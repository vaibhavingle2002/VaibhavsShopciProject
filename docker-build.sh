#!/bin/bash

set -e

echo "============================================================"
echo "        ShopCI - Docker Build & Deployment"
echo "============================================================"

# ------------------------------------------------------------
# Project Directory
# ------------------------------------------------------------

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "[INFO] Project directory: $PROJECT_DIR"

# ------------------------------------------------------------
# Check Docker
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Checking Docker..."
echo "============================================================"

if ! command -v docker >/dev/null 2>&1; then
    echo "[ERROR] Docker is not installed."
    exit 1
fi

if ! systemctl is-active --quiet docker; then
    echo "[INFO] Docker service is not running. Starting Docker..."
    systemctl start docker
fi

echo "[OK] Docker is installed."
echo "[OK] Docker service is running."

# ------------------------------------------------------------
# Check Docker Compose
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Checking Docker Compose..."
echo "============================================================"

if ! docker compose version >/dev/null 2>&1; then
    echo "[ERROR] Docker Compose is not available."
    echo "[ERROR] Please run setup.sh first."
    exit 1
fi

echo "[OK] Docker Compose is available."

# ------------------------------------------------------------
# Check Project Files
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Checking ShopCI project files..."
echo "============================================================"

if [ ! -d "frontend" ]; then
    echo "[ERROR] frontend directory not found."
    exit 1
fi

if [ ! -d "backend" ]; then
    echo "[ERROR] backend directory not found."
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo "[ERROR] docker-compose.yml not found."
    exit 1
fi

if [ ! -f "backend/.env" ]; then
    echo "[ERROR] backend/.env not found."
    echo "[INFO] Create backend/.env before running this script."
    exit 1
fi

echo "[OK] Frontend directory found."
echo "[OK] Backend directory found."
echo "[OK] docker-compose.yml found."
echo "[OK] backend/.env found."

# ------------------------------------------------------------
# Docker Hub Login
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Docker Hub Authentication"
echo "============================================================"

read -p "Enter Docker Hub Username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo "[ERROR] Docker Hub username cannot be empty."
    exit 1
fi

echo
read -s -p "Enter Docker Hub Password / Access Token: " DOCKER_PASSWORD
echo

if [ -z "$DOCKER_PASSWORD" ]; then
    echo "[ERROR] Docker Hub password/token cannot be empty."
    exit 1
fi

echo
echo "[INFO] Logging in to Docker Hub..."

echo "$DOCKER_PASSWORD" | docker login \
    --username "$DOCKER_USERNAME" \
    --password-stdin

echo "[OK] Docker Hub login successful."

# ------------------------------------------------------------
# Image Names
# ------------------------------------------------------------

FRONTEND_IMAGE="$DOCKER_USERNAME/shopci-frontend:v1"
BACKEND_IMAGE="$DOCKER_USERNAME/shopci-backend:v1"

echo
echo "[INFO] Frontend Image: $FRONTEND_IMAGE"
echo "[INFO] Backend Image : $BACKEND_IMAGE"

# ------------------------------------------------------------
# Build Frontend
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Building ShopCI Frontend Image"
echo "============================================================"

docker build \
    -t "$FRONTEND_IMAGE" \
    ./frontend

echo "[OK] Frontend Docker image built successfully."

# ------------------------------------------------------------
# Build Backend
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Building ShopCI Backend Image"
echo "============================================================"

docker build \
    -t "$BACKEND_IMAGE" \
    ./backend

echo "[OK] Backend Docker image built successfully."

# ------------------------------------------------------------
# Push Frontend
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Pushing Frontend Image to Docker Hub"
echo "============================================================"

docker push "$FRONTEND_IMAGE"

echo "[OK] Frontend image pushed successfully."

# ------------------------------------------------------------
# Push Backend
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Pushing Backend Image to Docker Hub"
echo "============================================================"

docker push "$BACKEND_IMAGE"

echo "[OK] Backend image pushed successfully."

# ------------------------------------------------------------
# Validate Docker Compose
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Validating Docker Compose"
echo "============================================================"

docker compose config >/dev/null

echo "[OK] docker-compose.yml configuration is valid."

# ------------------------------------------------------------
# Stop Existing ShopCI Containers
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Stopping Existing ShopCI Containers"
echo "============================================================"

docker compose down

echo "[OK] Existing ShopCI containers stopped."

# ------------------------------------------------------------
# Deploy ShopCI
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Deploying ShopCI Application"
echo "============================================================"

docker compose up -d

echo "[OK] ShopCI containers started."

# ------------------------------------------------------------
# Wait for Containers
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        Waiting for Containers"
echo "============================================================"

sleep 10

# ------------------------------------------------------------
# Container Status
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        ShopCI Container Status"
echo "============================================================"

docker compose ps

# ------------------------------------------------------------
# Docker Images
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        ShopCI Docker Images"
echo "============================================================"

docker images | grep -E "shopci-frontend|shopci-backend" || true

# ------------------------------------------------------------
# Final Result
# ------------------------------------------------------------

echo
echo "============================================================"
echo "        ShopCI Deployment Completed"
echo "============================================================"

echo
echo "[OK] Frontend image built."
echo "[OK] Backend image built."
echo "[OK] Frontend image pushed to Docker Hub."
echo "[OK] Backend image pushed to Docker Hub."
echo "[OK] ShopCI application deployed using Docker Compose."

echo
echo "Useful commands:"
echo
echo "  docker compose ps"
echo "  docker compose logs -f"
echo "  docker compose logs frontend"
echo "  docker compose logs backend"
echo "  docker compose restart"
echo "  docker compose down"

echo
echo "============================================================"
echo "                 ShopCI is LIVE 🚀"
echo "============================================================"
