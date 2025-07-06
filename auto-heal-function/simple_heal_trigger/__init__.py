import os
import logging
import subprocess
from datetime import datetime
import azure.functions as func


def main(mytimer: func.TimerRequest) -> None:
    """
    Simple timer-triggered auto-heal function using Azure CLI.
    This is a simplified version that uses az CLI commands directly.
    """
    utc_timestamp = datetime.utcnow().replace(tzinfo=None).isoformat()

    if mytimer.past_due:
        logging.info('The timer is past due!')

    logging.info(f'Simple auto-heal function executed at {utc_timestamp}')

    try:
        # Get environment variables
        resource_group = os.environ.get('RESOURCE_GROUP_NAME', 'autoscale-rg')
        container_name = os.environ.get(
            'CONTAINER_GROUP_NAME', 'healthcheck-aci'
        )

        logging.info(
            f'Restarting container group: {container_name} '
            f'in resource group: {resource_group}'
        )

        # Restart container group using Azure CLI
        # This approach is simpler but requires Azure CLI to be installed
        # in the function app
        result = subprocess.run([
            'az', 'container', 'restart',
            '-g', resource_group,
            '-n', container_name,
            '--output', 'json'
        ], capture_output=True, text=True, timeout=60)

        if result.returncode == 0:
            logging.info('Container restart completed successfully')
            logging.info(f'Azure CLI output: {result.stdout}')
        else:
            logging.error(
                (
                    f'Container restart failed with return code: '
                    f'{result.returncode}'
                )
            )
            logging.error(f'Error output: {result.stderr}')
            raise Exception(f'Azure CLI command failed: {result.stderr}')

    except subprocess.TimeoutExpired:
        error_msg = "Azure CLI command timed out"
        logging.error(error_msg)
        raise Exception(error_msg)

    except Exception as e:
        error_msg = f"Simple auto-heal function failed: {str(e)}"
        logging.error(error_msg)
        raise


def alternative_restart_approach():
    """
    Alternative approach using direct Azure REST API calls
    This doesn't require Azure CLI but needs proper authentication
    """
    import requests
    from azure.identity import DefaultAzureCredential

    try:
        # Get environment variables
        subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
        resource_group = os.environ.get('RESOURCE_GROUP_NAME')
        container_name = os.environ.get('CONTAINER_GROUP_NAME')

        if not all([subscription_id, resource_group, container_name]):
            raise ValueError("Missing required environment variables")

        # Get access token using managed identity
        credential = DefaultAzureCredential()
        token = credential.get_token("https://management.azure.com/.default")

        # Construct REST API URL
        url = (
            f"https://management.azure.com/subscriptions/{subscription_id}"
            f"/resourceGroups/{resource_group}"
            f"/providers/Microsoft.ContainerInstance"
            f"/containerGroups/{container_name}/restart"
        )

        # Make REST API call
        headers = {
            'Authorization': f'Bearer {token.token}',
            'Content-Type': 'application/json'
        }

        response = requests.post(
            f"{url}?api-version=2023-05-01",
            headers=headers
        )

        if response.status_code in [200, 202]:
            logging.info(
                'Container restart initiated successfully via REST API'
            )
            return True
        else:
            logging.error(
                f'REST API call failed: {response.status_code} - '
                f'{response.text}'
            )
            return False

    except Exception as e:
        logging.error(f'Alternative restart approach failed: {str(e)}')
        return False
