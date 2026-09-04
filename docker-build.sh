```bash
#!/bin/bash

set -e

# ============================================================
# ShopCI Docker Build & Push Script
# ============================================================

IMAGE_TAG="v1"

echo "=============================================="
echo "      ShopCI Docker Build & Push"
echo "=============================================="

# ------------------------------------------------------------
# 1. Check Docker
# ------------------------------------------------------------

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker is not installed."
    exit 1
fi

echo "Docker found:"
docker --version

# ------------------------------------------------------------
# 2. Check Project Directories
# ------------------------------------------------------------

if [ ! -d "frontend" ]; then
    echo "ERROR: frontend directory not found."
    echo "Run this script from the ShopCI project root."
    exit 1
fi

if [ ! -d "backend" ]; then
    echo "ERROR: backend directory not found."
    echo "Run this script from the ShopCI project root."
    exit 1
fi

if [ ! -f "frontend/Dockerfile" ]; then
    echo "ERROR: frontend/Dockerfile not found."
    exit 1
fi

if [ ! -f "backend/Dockerfile" ]; then
    echo "ERROR: backend/Dockerfile not found."
    exit 1
fi

# ------------------------------------------------------------
# 3. Ask Docker Hub Credentials Every Time
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "Docker Hub Login"
echo "=============================================="

read -p "Docker Hub Username: " DOCKERHUB_USERNAME

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "ERROR: Docker Hub username cannot be empty."
    exit 1
fi

echo "Enter Docker Hub password/access token:"
read -s DOCKERHUB_PASSWORD
echo ""

if [ -z "$DOCKERHUB_PASSWORD" ]; then
    echo "ERROR: Docker Hub password/access token cannot be empty."
    exit 1
fi

echo "$DOCKERHUB_PASSWORD" | docker login \
    --username "$DOCKERHUB_USERNAME" \
    --password-stdin

echo "Docker Hub login successful."

# ------------------------------------------------------------
# 4. Define Images
# ------------------------------------------------------------

FRONTEND_IMAGE="${DOCKERHUB_USERNAME}/shopci-frontend"
BACKEND_IMAGE="${DOCKERHUB_USERNAME}/shopci-backend"

# ------------------------------------------------------------
# 5. Build Frontend
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "Building Frontend Image"
echo "=============================================="

docker build \
    -t "${FRONTEND_IMAGE}:${IMAGE_TAG}" \
    ./frontend

echo "Frontend image built successfully."

# ------------------------------------------------------------
# 6. Build Backend
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "Building Backend Image"
echo "=============================================="

docker build \
    -t "${BACKEND_IMAGE}:${IMAGE_TAG}" \
    ./backend

echo "Backend image built successfully."

# ------------------------------------------------------------
# 7. Display Images
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "Docker Images"
echo "=============================================="

docker images | grep -E "shopci-frontend|shopci-backend"

# ------------------------------------------------------------
# 8. Push Frontend
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "Pushing Frontend Image"
echo "=============================================="

docker push "${FRONTEND_IMAGE}:${IMAGE_TAG}"

echo "Frontend image pushed successfully."

# ------------------------------------------------------------
# 9. Push Backend
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "Pushing Backend Image"
echo "=============================================="

docker push "${BACKEND_IMAGE}:${IMAGE_TAG}"

echo "Backend image pushed successfully."

# ------------------------------------------------------------
# 10. Final Output
# ------------------------------------------------------------

echo ""
echo "=============================================="
echo "       BUILD & PUSH COMPLETED"
echo "=============================================="

echo ""
echo "Frontend:"
echo "  ${FRONTEND_IMAGE}:${IMAGE_TAG}"

echo ""
echo "Backend:"
echo "  ${BACKEND_IMAGE}:${IMAGE_TAG}"

echo ""
echo "Docker Hub Username:"
echo "  ${DOCKERHUB_USERNAME}"

echo ""
echo "=============================================="
```
