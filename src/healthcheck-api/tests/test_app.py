import pytest
import sys
import os

# Add the parent directory to the path so we can import the app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import after path modification
from app import app  # noqa: E402


@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_health_endpoint(client):
    """Test the health check endpoint."""
    response = client.get('/health')
    assert response.status_code == 200

    json_data = response.get_json()
    assert json_data['status'] == 'healthy'


def test_health_endpoint_structure(client):
    """Test the structure of the health check response."""
    response = client.get('/health')
    json_data = response.get_json()

    # Check required fields
    required_fields = ['status']
    for field in required_fields:
        assert field in json_data, f"Missing field: {field}"
    # Check response status code
    # Check data types
    assert isinstance(json_data['status'], str)


def test_app_runs():
    """Test that the Flask app can be created and configured."""
    assert app is not None
    assert app.config['TESTING'] is True
