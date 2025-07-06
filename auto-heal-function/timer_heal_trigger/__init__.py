import os
import logging
import requests
from datetime import datetime
from azure.identity import DefaultAzureCredential
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
import azure.functions as func


def main(mytimer: func.TimerRequest) -> None:
    """
    Timer-triggered auto-heal function that checks health and restarts
    container if needed.
    This function runs on a schedule and provides a simpler alternative to
    alert-based healing.
    """
    utc_timestamp = datetime.utcnow().replace(tzinfo=None).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info(f'Timer-based auto-heal function executed at {utc_timestamp}')

    try:
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

        # Check health first
        logging.info(f'Checking health at {health_check_url}')
        if health_check_url and check_health(health_check_url):
            logging.info('Health check passed, no restart needed')
            return

        # Health check failed or no health URL provided, restart container
        logging.warning('Health check failed, restarting container...')

        # Initialize Azure client with managed identity
        credential = DefaultAzureCredential()
        container_client = ContainerInstanceManagementClient(
            credential,
            subscription_id
        )

        # Restart the container group
        logging.info(f'Restarting container group: {container_group_name}')
        restart_operation = container_client.container_groups.begin_restart(
            resource_group_name,
            container_group_name
        )

        # Wait for restart to complete
        restart_operation.wait()
        logging.info('Container group restart completed successfully')

        # Optional: Wait and verify restart success
        if health_check_url:
            verify_restart_success(
                container_client,
                resource_group_name,
                container_group_name,
                health_check_url
            )

    except Exception as e:
        error_msg = f"Timer-based auto-heal function failed: {str(e)}"
        logging.error(error_msg)
        raise


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


def verify_restart_success(
    container_client,
    resource_group,
    container_name,
    health_url,
    max_attempts=6
):
    """Verify that the container restart was successful"""
    import time

    for attempt in range(max_attempts):
        try:
            # Wait between attempts (30 seconds)
            time.sleep(30)

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
