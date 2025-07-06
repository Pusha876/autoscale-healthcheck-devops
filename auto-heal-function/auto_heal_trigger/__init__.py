import os
import json
import logging
import requests
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
import azure.functions as func


def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Auto-heal function triggered by Azure Monitor alert')

    try:
        # Parse the alert payload
        alert_data = req.get_json()
        logging.info(
            f'Alert data received: {json.dumps(alert_data, indent=2)}'
        )

        # Get environment variables
        subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
        resource_group_name = os.environ.get('RESOURCE_GROUP_NAME')
        container_group_name = os.environ.get('CONTAINER_GROUP_NAME')
        health_check_url = os.environ.get('HEALTH_CHECK_URL')

        if not all([
            subscription_id,
            resource_group_name,
            container_group_name
        ]):
            raise ValueError("Missing required environment variables")

        # Initialize Azure clients with managed identity
        credential = DefaultAzureCredential()
        container_client = ContainerInstanceManagementClient(
            credential,
            subscription_id
        )

        # Check if container group exists and is running
        try:
            container_group = container_client.container_groups.get(
                resource_group_name,
                container_group_name
            )
            current_state = (
                container_group.instance_view.state
                if container_group.instance_view else "Unknown"
            )
            logging.info(f'Container group current state: {current_state}')

        except Exception as e:
            logging.error(f'Failed to get container group status: {str(e)}')
            return func.HttpResponse(
                f"Failed to get container group status: {str(e)}",
                status_code=500
            )

        # Perform health check before restart
        health_status = check_health(health_check_url)
        logging.info(f'Health check result: {health_status}')

        # If health check fails or we have critical errors,
        # restart the container
        if not health_status or is_critical_alert(alert_data):
            logging.info('Initiating container group restart...')
            # Log the pre-restart health status
            # Restart the container group
            restart_result = container_client.container_groups.begin_restart(
                resource_group_name,
                container_group_name
            )

            # Wait for operation to complete (with timeout)
            restart_result.wait(timeout=300)  # 5 minutes timeout

            # Verify restart was successful
            post_restart_health = verify_restart_success(
                container_client,
                resource_group_name,
                container_group_name,
                health_check_url
            )

            response_data = {
                "status": "success",
                "action": "container_restarted",
                "timestamp": datetime.utcnow().isoformat(),
                "container_group": container_group_name,
                "resource_group": resource_group_name,
                "pre_restart_health": health_status,
                "post_restart_health": post_restart_health,
                "alert_data": alert_data
            }

            logging.info(
                f'Auto-heal completed successfully: '
                f'{json.dumps(response_data, indent=2)}'
            )

            return func.HttpResponse(
                json.dumps(response_data),
                status_code=200,
                headers={"Content-Type": "application/json"}
            )

        else:
            # Health check passed, no restart needed
            response_data = {
                "status": "no_action_needed",
                "action": "health_check_passed",
                "timestamp": datetime.utcnow().isoformat(),
                "health_status": health_status,
                "alert_data": alert_data
            }

            logging.info('Health check passed, no restart needed')

            return func.HttpResponse(
                json.dumps(response_data),
                status_code=200,
                headers={"Content-Type": "application/json"}
            )

    except Exception as e:
        error_msg = f"Auto-heal function failed: {str(e)}"
        logging.error(error_msg)

        error_response = {
            "status": "error",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat()
        }

        return func.HttpResponse(
            json.dumps(error_response),
            status_code=500,
            headers={"Content-Type": "application/json"}
        )


def check_health(health_url):
    """Check if the health endpoint is responding correctly"""
    try:
        response = requests.get(health_url, timeout=10)
        if response.status_code == 200:
            health_data = response.json()
            return health_data.get('status') == 'healthy'
        return False
    except Exception as e:
        logging.warning(f'Health check failed: {str(e)}')
        return False


def is_critical_alert(alert_data):
    """Determine if this is a critical alert that requires restart"""
    try:
        # Check alert severity
        essentials = alert_data.get('data', {}).get('essentials', {})
        severity = essentials.get('severity', 'Unknown')
        alert_rule = essentials.get('alertRule', '')

        # Critical alerts or specific error patterns trigger restart
        critical_conditions = [
            severity in ['Sev0', 'Sev1', 'Critical'],
            'auto-heal' in alert_rule.lower(),
            'downtime' in alert_rule.lower()
        ]

        return any(critical_conditions)

    except Exception as e:
        logging.warning(f'Failed to parse alert criticality: {str(e)}')
        return True  # Default to critical if we can't parse


def verify_restart_success(
    container_client,
    resource_group,
    container_name,
    health_url,
    max_attempts=12
):
    """Verify that the container restart was successful"""
    import time

    for attempt in range(max_attempts):
        try:
            # Wait between attempts
            time.sleep(10)

            # Check container status
            container_group = container_client.container_groups.get(
                resource_group,
                container_name
            )
            state = (
                container_group.instance_view.state
                if container_group.instance_view else "Unknown"
            )

            logging.info(
                f'Restart verification attempt {attempt + 1}: '
                f'Container state = {state}'
            )

            if state == "Running":
                # Container is running, now check health
                if check_health(health_url):
                    logging.info(
                        'Restart verification successful: '
                        'Container is running and healthy'
                    )
                    return True
                else:
                    logging.info(
                        'Container is running but health check failed, '
                        'continuing to wait...'
                    )

        except Exception as e:
            logging.warning(
                f'Restart verification attempt {attempt + 1} failed: {str(e)}'
            )

    logging.warning('Restart verification failed: Maximum attempts reached')
    return False
