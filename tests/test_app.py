import pytest
from fastapi.testclient import TestClient
import sys
import os

# Add parent directory to path to import app
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import app

client = TestClient(app)


def test_health_endpoint():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "version" in data


def test_hello_endpoint():
    """Test the hello API endpoint"""
    response = client.get("/api/hello")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "Eloquent AI" in data["message"]
    assert "environment" in data


def test_health_with_version():
    """Test health endpoint with custom version"""
    os.environ["APP_VERSION"] = "2.0.0"
    response = client.get("/health")
    data = response.json()
    assert data["version"] == "2.0.0"


def test_hello_with_environment():
    """Test hello endpoint with custom environment"""
    os.environ["ENVIRONMENT"] = "testing"
    response = client.get("/api/hello")
    data = response.json()
    assert data["environment"] == "testing"


def test_invalid_endpoint():
    """Test that invalid endpoints return 404"""
    response = client.get("/invalid")
    assert response.status_code == 404
