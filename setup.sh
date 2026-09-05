#!/bin/bash

set -Eeuo pipefail

trap 'echo "[ERROR] Script failed at line $LINENO"; exit 1' ERR

# ============================================================
# SHOPCI COMPLETE DOCKER SETUP SCRIPT
# Amazon Linux 2023
# ============================================================

PROJECT_DIR="/root/VaibhavsShopciProject"
REPO_URL="https://github.com/vaibhavingle2002/VaibhavsShopciProject.git"
BRANCH="master"

FRONTEND_IMAGE="shopci-frontend"
BACKEND_IMAGE="shopci-backend"

echo
echo "============================================================"
echo "        SHOPCI COMPLETE DOCKER SETUP"
echo "============================================================"
echo

# ============================================================
# 1. ROOT CHECK
# ============================================================

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Please run this script as root."
    exit 1
fi

echo "[INFO] Running as root."

# ============================================================
# 2. OS CHECK
# ============================================================

if [ -f /etc/os-release ]; then
    . /etc/os-release
else
    echo "[ERROR] Cannot detect operating system."
    exit 1
fi

echo "[INFO] Operating System: $PRETTY_NAME"

if [[ "$ID" != "amzn" ]]; then
    echo "[WARNING] This script is designed for Amazon Linux."
fi

# ============================================================
# 3. USER INPUT
# ============================================================

echo
echo "============================================================"
echo "                APPLICATION CREDENTIALS"
echo "============================================================"
echo

read -r -p "Enter Docker Hub username: " DOCKERHUB_USERNAME

if [ -z "$DOCKERHUB_USERNAME" ]; then
    echo "[ERROR] Docker Hub username cannot be empty."
    exit 1
fi

# Validate Docker Hub username
if [[ ! "$DOCKERHUB_USERNAME" =~ ^[a-z0-9]+([._-][a-z0-9]+)*$ ]]; then
    echo "[ERROR] Invalid Docker Hub username."
    echo "Use lowercase letters, numbers, ., _, or -."
    exit 1
fi

echo
echo "Docker Hub password/token will be hidden."

read -r -s -p "Enter Docker Hub password/token: " DOCKERHUB_PASSWORD
echo

if [ -z "$DOCKERHUB_PASSWORD" ]; then
    echo "[ERROR] Docker Hub password/token cannot be empty."
    exit 1
fi

echo
read -r -s -p "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
echo

if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
    echo "[ERROR] MySQL root password cannot be empty."
    exit 1
fi

echo
read -r -s -p "Enter JWT secret: " JWT_SECRET
echo

if [ -z "$JWT_SECRET" ]; then
    echo "[ERROR] JWT secret cannot be empty."
    exit 1
fi

echo
echo "[INFO] Credentials received."

# ============================================================
# 4. UPDATE SYSTEM
# ============================================================

echo
echo "============================================================"
echo "1. Updating Amazon Linux"
echo "============================================================"

dnf update -y

# IMPORTANT:
# Do NOT install full curl because Amazon Linux 2023
# provides curl-minimal.

dnf install -y \
    git \
    jq \
    wget \
    unzip \
    tar \
    gzip \
    ca-certificates \
    openssl

if ! command -v curl >/dev/null 2>&1; then
    echo "[ERROR] curl is not available."
    exit 1
fi

echo "[INFO] curl detected: $(curl --version | head -1)"

# ============================================================
# 5. INSTALL DOCKER
# ============================================================

echo
echo "============================================================"
echo "2. Installing Docker"
echo "============================================================"

if ! command -v docker >/dev/null 2>&1; then

    echo "[INFO] Docker not found."
    echo "[INFO] Installing Docker..."

    dnf install -y docker

else

    echo "[INFO] Docker already installed."
fi

systemctl enable docker
systemctl start docker

echo "[INFO] Docker service started."

# Add ec2-user to docker group if available
if id ec2-user >/dev/null 2>&1; then
    usermod -aG docker ec2-user
    echo "[INFO] ec2-user added to docker group."
fi

# ============================================================
# 6. DOCKER VERSION
# ============================================================

echo
echo "============================================================"
echo "3. Docker Version"
echo "============================================================"

docker --version

# ============================================================
# 7. INSTALL BUILDX
# ============================================================

echo
echo "============================================================"
echo "4. Installing Latest Docker Buildx"
echo "============================================================"

ARCH="$(uname -m)"

case "$ARCH" in

    x86_64)
        BUILDX_ARCH="amd64"
        COMPOSE_ARCH="x86_64"
        ;;

    aarch64)
        BUILDX_ARCH="arm64"
        COMPOSE_ARCH="aarch64"
        ;;

    *)
        echo "[ERROR] Unsupported architecture: $ARCH"
        exit 1
        ;;

esac

echo "[INFO] Architecture: $ARCH"

CLI_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

mkdir -p "$CLI_PLUGIN_DIR"

# Remove old plugins
rm -f /usr/libexec/docker/cli-plugins/docker-buildx 2>/dev/null || true
rm -f /usr/libexec/docker/cli-plugins/docker-compose 2>/dev/null || true

rm -f /root/.docker/cli-plugins/docker-buildx 2>/dev/null || true
rm -f /root/.docker/cli-plugins/docker-compose 2>/dev/null || true

rm -f "$CLI_PLUGIN_DIR/docker-buildx" 2>/dev/null || true
rm -f "$CLI_PLUGIN_DIR/docker-compose" 2>/dev/null || true

# Get latest Buildx
BUILDX_VERSION="$(curl -fsSL \
    https://api.github.com/repos/docker/buildx/releases/latest \
    | jq -r '.tag_name')"

if [ -z "$BUILDX_VERSION" ] || [ "$BUILDX_VERSION" = "null" ]; then
    echo "[ERROR] Could not determine latest Buildx version."
    exit 1
fi

echo "[INFO] Latest Buildx: $BUILDX_VERSION"

curl -fL \
    "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${BUILDX_ARCH}" \
    -o "$CLI_PLUGIN_DIR/docker-buildx"

chmod +x "$CLI_PLUGIN_DIR/docker-buildx"

echo "[INFO] Buildx installed."

# ============================================================
# 8. INSTALL DOCKER COMPOSE
# ============================================================

echo
echo "============================================================"
echo "5. Installing Latest Docker Compose"
echo "============================================================"

COMPOSE_VERSION="$(curl -fsSL \
    https://api.github.com/repos/docker/compose/releases/latest \
    | jq -r '.tag_name')"

if [ -z "$COMPOSE_VERSION" ] || [ "$COMPOSE_VERSION" = "null" ]; then
    echo "[ERROR] Could not determine latest Docker Compose version."
    exit 1
fi

echo "[INFO] Latest Docker Compose: $COMPOSE_VERSION"

curl -fL \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}" \
    -o "$CLI_PLUGIN_DIR/docker-compose"

chmod +x "$CLI_PLUGIN_DIR/docker-compose"

echo "[INFO] Docker Compose installed."

# ============================================================
# 9. VERIFY DOCKER TOOLS
# ============================================================

echo
echo "============================================================"
echo "6. Verifying Docker Tools"
echo "============================================================"

docker --version
docker buildx version
docker compose version

echo
echo "[INFO] Docker information:"
docker info >/dev/null

echo "[INFO] Docker is working correctly."

# ============================================================
# 10. CREATE BUILDX BUILDER
# ============================================================

echo
echo "============================================================"
echo "7. Configuring Docker Buildx"
echo "============================================================"

if docker buildx inspect shopci-builder >/dev/null 2>&1; then

    echo "[INFO] shopci-builder already exists."

else

    docker buildx create \
        --name shopci-builder \
        --driver docker-container \
        --use

fi

docker buildx use shopci-builder

docker buildx inspect --bootstrap

echo "[INFO] Buildx ready."

# ============================================================
# 11. CLONE / UPDATE SHOPCI
# ============================================================

echo
echo "============================================================"
echo "8. Getting ShopCI Source Code"
echo "============================================================"

if [ -d "$PROJECT_DIR/.git" ]; then

    echo "[INFO] Existing ShopCI repository found."

    cd "$PROJECT_DIR"

    git fetch origin

    git checkout "$BRANCH"

    git pull origin "$BRANCH"

else

    echo "[INFO] Cloning ShopCI repository..."

    rm -rf "$PROJECT_DIR"

    git clone \
        -b "$BRANCH" \
        "$REPO_URL" \
        "$PROJECT_DIR"

    cd "$PROJECT_DIR"

fi

echo "[INFO] Current commit:"
git log -1 --oneline

# ============================================================
# 12. VERIFY PROJECT FILES
# ============================================================

echo
echo "============================================================"
echo "9. Checking ShopCI Files"
echo "============================================================"

REQUIRED_FILES=(
    "docker-compose.yml"
    "frontend/Dockerfile"
    "frontend/nginx.conf"
    "backend/Dockerfile"
)

for FILE in "${REQUIRED_FILES[@]}"; do

    if [ ! -f "$FILE" ]; then
        echo "[ERROR] Missing file: $FILE"
        exit 1
    fi

    echo "[OK] $FILE"

done

# ============================================================
# 13. CREATE BACKEND ENVIRONMENT FILE
# ============================================================

echo
echo "============================================================"
echo "10. Creating Backend Environment"
echo "============================================================"

cat > backend/.env <<EOF
PORT=5000
DB_HOST=mysql
DB_USER=root
DB_PASSWORD=${MYSQL_ROOT_PASSWORD}
DB_NAME=ecommerce_db
JWT_SECRET=${JWT_SECRET}
EOF

chmod 600 backend/.env

echo "[INFO] backend/.env created."

# ============================================================
# 14. CREATE DOCKER COMPOSE FILE
# ============================================================

echo
echo "============================================================"
echo "11. Creating Docker Compose Configuration"
echo "============================================================"

cat > docker-compose.yml <<EOF
services:

  mysql:
    image: mysql:8.0
    container_name: shopci-mysql
    restart: unless-stopped

    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      MYSQL_DATABASE: ecommerce_db

    volumes:
      - mysql_data:/var/lib/mysql

    ports:
      - "3306:3306"

    healthcheck:
      test:
        [
          "CMD",
          "mysqladmin",
          "ping",
          "-h",
          "localhost",
          "-u",
          "root",
          "-p${MYSQL_ROOT_PASSWORD}"
        ]
      interval: 10s
      timeout: 5s
      retries: 10

  backend:
    image: ${DOCKERHUB_USERNAME}/shopci-backend:v1
    container_name: shopci-backend
    restart: unless-stopped

    env_file:
      - ./backend/.env

    depends_on:
      mysql:
        condition: service_healthy

    ports:
      - "5000:5000"

  frontend:
    image: ${DOCKERHUB_USERNAME}/shopci-frontend:v1
    container_name: shopci-frontend
    restart: unless-stopped

    depends_on:
      - backend

    ports:
      - "3000:80"

volumes:
  mysql_data:
EOF

echo "[INFO] docker-compose.yml created."

# ============================================================
# 15. VALIDATE COMPOSE
# ============================================================

echo
echo "============================================================"
echo "12. Validating Docker Compose"
echo "============================================================"

docker compose config >/dev/null

echo "[OK] Docker Compose configuration is valid."

# ============================================================
# 16. STOP OLD SHOPCI CONTAINERS
# ============================================================

echo
echo "============================================================"
echo "13. Cleaning Old ShopCI Containers"
echo "============================================================"

docker compose down 2>/dev/null || true

# ============================================================
# 17. BUILD LOCAL IMAGES
# ============================================================

echo
echo "============================================================"
echo "14. Building ShopCI Frontend and Backend"
echo "============================================================"

# Build directly from Dockerfiles rather than pulling
# placeholder images.

docker build \
    --pull \
    -t "${DOCKERHUB_USERNAME}/${FRONTEND_IMAGE}:v1" \
    ./frontend

docker build \
    --pull \
    -t "${DOCKERHUB_USERNAME}/${BACKEND_IMAGE}:v1" \
    ./backend

echo
echo "[INFO] ShopCI images built successfully."

# ============================================================
# 18. LOGIN TO DOCKER HUB
# ============================================================

echo
echo "============================================================"
echo "15. Docker Hub Login"
echo "============================================================"

echo "$DOCKERHUB_PASSWORD" | docker login \
    --username "$DOCKERHUB_USERNAME" \
    --password-stdin

echo "[INFO] Docker Hub login successful."

# Clear password variable after login
unset DOCKERHUB_PASSWORD

# ============================================================
# 19. PUSH IMAGES
# ============================================================

echo
echo "============================================================"
echo "16. Pushing ShopCI Images to Docker Hub"
echo "============================================================"

docker push "${DOCKERHUB_USERNAME}/${FRONTEND_IMAGE}:v1"

docker push "${DOCKERHUB_USERNAME}/${BACKEND_IMAGE}:v1"

echo
echo "[INFO] Images pushed successfully."

# ============================================================
# 20. START SHOPCI
# ============================================================

echo
echo "============================================================"
echo "17. Starting ShopCI"
echo "============================================================"

docker compose up -d

echo "[INFO] Containers started."

# ============================================================
# 21. WAIT FOR MYSQL
# ============================================================

echo
echo "============================================================"
echo "18. Waiting for MySQL"
echo "============================================================"

for i in {1..30}; do

    if docker exec shopci-mysql \
        mysqladmin ping \
        -h localhost \
        -u root \
        -p"${MYSQL_ROOT_PASSWORD}" \
        --silent >/dev/null 2>&1; then

        echo "[OK] MySQL is ready."
        break

    fi

    echo "[INFO] Waiting for MySQL... ($i/30)"
    sleep 2

done

# ============================================================
# 22. DATABASE SETUP
# ============================================================

echo
echo "============================================================"
echo "19. Running ShopCI Database Setup"
echo "============================================================"

sleep 3

if docker exec shopci-backend npm run setup-db; then

    echo "[OK] Database setup completed."

else

    echo "[WARNING] Database setup command failed."
    echo "[INFO] Check backend logs:"
    echo "docker logs shopci-backend"

fi

# ============================================================
# 23. CONTAINER STATUS
# ============================================================

echo
echo "============================================================"
echo "20. ShopCI Container Status"
echo "============================================================"

docker compose ps

# ============================================================
# 24. SHOW IMAGES
# ============================================================

echo
echo "============================================================"
echo "21. ShopCI Docker Images"
echo "============================================================"

docker images | grep shopci || true

# ============================================================
# 25. TEST BACKEND
# ============================================================

echo
echo "============================================================"
echo "22. Testing Backend API"
echo "============================================================"

sleep 5

if curl -fsS \
    --max-time 10 \
    http://127.0.0.1:5000/api/products \
    >/tmp/shopci-backend-test.json 2>/dev/null; then

    echo "[OK] Backend API is working."

else

    echo "[WARNING] Backend API test failed."

    echo
    echo "Backend logs:"
    docker logs --tail 50 shopci-backend || true

fi

# ============================================================
# 26. TEST FRONTEND
# ============================================================

echo
echo "============================================================"
echo "23. Testing Frontend"
echo "============================================================"

if curl -fsS \
    --max-time 10 \
    http://127.0.0.1:3000 \
    >/tmp/shopci-frontend-test.html 2>/dev/null; then

    echo "[OK] Frontend is working."

else

    echo "[WARNING] Frontend test failed."

    echo
    echo "Frontend logs:"
    docker logs --tail 50 shopci-frontend || true

fi

# ============================================================
# 27. FINAL INFORMATION
# ============================================================

echo
echo
echo "============================================================"
echo "          SHOPCI DEPLOYMENT COMPLETED"
echo "============================================================"
echo

echo "Docker:"
docker --version

echo
echo "Buildx:"
docker buildx version

echo
echo "Compose:"
docker compose version

echo
echo "Docker Hub:"
echo "$DOCKERHUB_USERNAME"

echo
echo "Images:"
echo "  ${DOCKERHUB_USERNAME}/${FRONTEND_IMAGE}:v1"
echo "  ${DOCKERHUB_USERNAME}/${BACKEND_IMAGE}:v1"

echo
echo "Containers:"
docker compose ps

echo
echo "Application:"
echo "  Frontend: http://<EC2-PUBLIC-IP>:3000"
echo "  Backend:  http://<EC2-PUBLIC-IP>:5000/api/products"

echo
echo "Project:"
echo "  $PROJECT_DIR"

echo
echo "============================================================"
echo "IMPORTANT"
echo "============================================================"
echo
echo "Do NOT run:"
echo "  docker compose down -v"
echo
echo "unless you intentionally want to delete the MySQL volume."
echo
echo "MySQL data volume:"
echo "  mysql_data"
echo
echo "============================================================"
echo "[SUCCESS] ShopCI is ready."
echo "============================================================"
