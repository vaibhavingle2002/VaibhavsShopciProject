#!/bin/bash

set -Eeuo pipefail

# ============================================================
# SHOPCI - AMAZON LINUX 2023 DOCKER ENVIRONMENT SETUP
# ============================================================

REPO_URL="https://github.com/vaibhavingle2002/VaibhavsShopciProject.git"
BRANCH="master"
PROJECT_DIR="/root/VaibhavsShopciProject"

PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

fail() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

section() {
    echo
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

trap 'echo -e "\033[0;31m[ERROR]\033[0m Script failed at line $LINENO"; exit 1' ERR


# ============================================================
# 1. ROOT CHECK
# ============================================================

section "1. Checking User"

if [ "$(id -u)" -ne 0 ]; then
    fail "Run this script as root."
fi

echo "Running as: $(whoami)"


# ============================================================
# 2. OS CHECK
# ============================================================

section "2. Checking Operating System"

if [ ! -f /etc/os-release ]; then
    fail "/etc/os-release not found."
fi

source /etc/os-release

echo "OS           : ${PRETTY_NAME}"
echo "Architecture : $(uname -m)"

if [[ "${ID:-}" != "amzn" ]]; then
    warn "This script is designed for Amazon Linux 2023."
fi


# ============================================================
# 3. UPDATE SYSTEM
# ============================================================

section "3. Updating Amazon Linux"

dnf update -y

log "System update completed."


# ============================================================
# 4. INSTALL REQUIRED UTILITIES
# ============================================================

section "4. Installing Required Utilities"

dnf install -y \
    git \
    jq \
    wget \
    unzip \
    tar \
    gzip \
    ca-certificates \
    openssl \
    curl

echo
curl --version | head -1
git --version
jq --version

log "Required utilities installed."


# ============================================================
# 5. DETECT CPU ARCHITECTURE
# ============================================================

section "5. Detecting CPU Architecture"

ARCH="$(uname -m)"

case "$ARCH" in

    x86_64)
        BUILDX_ARCH="amd64"
        COMPOSE_ARCH="x86_64"
        AWSCLI_ARCH="x86_64"
        ;;

    aarch64)
        BUILDX_ARCH="arm64"
        COMPOSE_ARCH="aarch64"
        AWSCLI_ARCH="aarch64"
        ;;

    arm64)
        BUILDX_ARCH="arm64"
        COMPOSE_ARCH="aarch64"
        AWSCLI_ARCH="aarch64"
        ;;

    *)
        fail "Unsupported architecture: $ARCH"
        ;;

esac

echo "System architecture : $ARCH"
echo "Buildx architecture  : $BUILDX_ARCH"
echo "Compose architecture : $COMPOSE_ARCH"
echo "AWS CLI architecture : $AWSCLI_ARCH"


# ============================================================
# 6. INSTALL DOCKER
# ============================================================

section "6. Installing Docker"

if command -v docker >/dev/null 2>&1; then

    log "Docker is already installed."

else

    log "Installing Docker..."

    dnf install -y docker

    log "Docker installed."

fi

echo
docker --version


# ============================================================
# 7. START DOCKER SERVICE
# ============================================================

section "7. Starting Docker Service"

systemctl enable docker
systemctl start docker

sleep 3

if systemctl is-active --quiet docker; then

    log "Docker service is running."

else

    systemctl status docker --no-pager
    fail "Docker service failed to start."

fi


# ============================================================
# 8. CONFIGURE DOCKER GROUP
# ============================================================

section "8. Configuring Docker Group"

if id ec2-user >/dev/null 2>&1; then

    usermod -aG docker ec2-user

    log "Added ec2-user to docker group."

else

    warn "ec2-user does not exist."

fi


# ============================================================
# 9. PREPARE DOCKER CLI PLUGIN DIRECTORY
# ============================================================

section "9. Preparing Docker CLI Plugins"

mkdir -p "$PLUGIN_DIR"

log "Docker CLI plugin directory ready."


# ============================================================
# 10. INSTALL DOCKER BUILDX
# ============================================================

section "10. Installing Docker Buildx"

if docker buildx version >/dev/null 2>&1; then

    log "Docker Buildx is already installed."

else

    log "Installing Docker Buildx..."

    BUILDX_VERSION="$(
        curl -fsSL \
        --retry 3 \
        --retry-delay 2 \
        https://api.github.com/repos/docker/buildx/releases/latest \
        | jq -r '.tag_name'
    )"

    if [[ -z "$BUILDX_VERSION" || "$BUILDX_VERSION" == "null" ]]; then
        fail "Could not determine latest Docker Buildx version."
    fi

    echo
    echo "Buildx version : $BUILDX_VERSION"
    echo "Architecture   : $BUILDX_ARCH"
    echo

    BUILDX_URL="https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${BUILDX_ARCH}"

    echo "Downloading:"
    echo "$BUILDX_URL"

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "$BUILDX_URL" \
        -o "$PLUGIN_DIR/docker-buildx"

    chmod +x "$PLUGIN_DIR/docker-buildx"

    log "Docker Buildx installed successfully."

fi

echo
docker buildx version


# ============================================================
# 11. INSTALL DOCKER COMPOSE
# ============================================================

section "11. Installing Docker Compose"

if docker compose version >/dev/null 2>&1; then

    log "Docker Compose is already installed."

else

    log "Installing Docker Compose..."

    COMPOSE_VERSION="$(
        curl -fsSL \
        --retry 3 \
        --retry-delay 2 \
        https://api.github.com/repos/docker/compose/releases/latest \
        | jq -r '.tag_name'
    )"

    if [[ -z "$COMPOSE_VERSION" || "$COMPOSE_VERSION" == "null" ]]; then
        fail "Could not determine latest Docker Compose version."
    fi

    echo
    echo "Compose version : $COMPOSE_VERSION"
    echo "Architecture    : $COMPOSE_ARCH"
    echo

    COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}"

    echo "Downloading:"
    echo "$COMPOSE_URL"

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "$COMPOSE_URL" \
        -o "$PLUGIN_DIR/docker-compose"

    chmod +x "$PLUGIN_DIR/docker-compose"

    log "Docker Compose installed successfully."

fi

echo
docker compose version


# ============================================================
# 12. VERIFY DOCKER TOOLS
# ============================================================

section "12. Verifying Docker Tools"

echo
echo "Docker:"
docker --version

echo
echo "Buildx:"
docker buildx version

echo
echo "Docker Compose:"
docker compose version

echo
echo "Docker Info:"

if docker info >/dev/null 2>&1; then

    log "Docker daemon is responding."

else

    fail "Docker daemon is not responding."

fi


# ============================================================
# 13. CREATE BUILDX BUILDER
# ============================================================

section "13. Configuring Buildx Builder"

if docker buildx inspect shopci-builder >/dev/null 2>&1; then

    log "shopci-builder already exists."

else

    docker buildx create \
        --name shopci-builder \
        --driver docker-container \
        --use

    log "shopci-builder created."

fi

docker buildx use shopci-builder

docker buildx inspect --bootstrap

log "Buildx builder is ready."


# ============================================================
# 14. CHECK AWS CLI
# ============================================================

section "14. Checking AWS CLI"

if command -v aws >/dev/null 2>&1; then

    log "AWS CLI is already installed."

else

    log "AWS CLI is not installed. Installing AWS CLI..."

    AWS_ZIP="/tmp/awscliv2.zip"
    AWS_INSTALL_DIR="/tmp/aws"

    rm -rf "$AWS_INSTALL_DIR"
    rm -f "$AWS_ZIP"

    AWS_URL="https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARCH}.zip"

    echo
    echo "Downloading:"
    echo "$AWS_URL"

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "$AWS_URL" \
        -o "$AWS_ZIP"

    unzip -q "$AWS_ZIP" -d /tmp

    /tmp/aws/install --update

    rm -rf "$AWS_INSTALL_DIR"
    rm -f "$AWS_ZIP"

    log "AWS CLI installed."

fi

echo
aws --version


# ============================================================
# 15. VERIFY EC2 IAM ROLE
# ============================================================

section "15. Checking EC2 IAM Role"

IDENTITY_FILE="/tmp/shopci-identity.json"
IDENTITY_ERROR="/tmp/shopci-identity-error.log"

if aws sts get-caller-identity \
    >"$IDENTITY_FILE" \
    2>"$IDENTITY_ERROR"; then

    log "EC2 IAM Role is working."

    echo
    cat "$IDENTITY_FILE"

else

    warn "AWS CLI is installed, but EC2 IAM Role verification failed."

    echo
    cat "$IDENTITY_ERROR"

    echo
    warn "Make sure an IAM Role is attached to this EC2 instance."

fi


# ============================================================
# 16. GET SHOPCI PROJECT
# ============================================================

section "16. Getting ShopCI Source Code"

if [ -d "$PROJECT_DIR/.git" ]; then

    log "ShopCI repository already exists."

    cd "$PROJECT_DIR"

    git fetch origin

    git checkout "$BRANCH"

    git pull --ff-only origin "$BRANCH"

else

    log "Cloning ShopCI repository..."

    git clone \
        --branch "$BRANCH" \
        "$REPO_URL" \
        "$PROJECT_DIR"

    cd "$PROJECT_DIR"

fi

echo
echo "Project directory:"
pwd

echo
echo "Current branch:"
git branch --show-current

echo
echo "Latest commit:"
git log -1 --oneline


# ============================================================
# 17. CHECK SHOPCI FILES
# ============================================================

section "17. Checking ShopCI Project Files"

REQUIRED_FILES=(
    "docker-compose.yml"
    "frontend/Dockerfile"
    "frontend/nginx.conf"
    "backend/Dockerfile"
)

for FILE in "${REQUIRED_FILES[@]}"; do

    if [ -f "$FILE" ]; then

        echo "[FOUND] $FILE"

    else

        fail "Required file missing: $FILE"

    fi

done

log "All required ShopCI files found."


# ============================================================
# 18. CREATE BACKEND ENVIRONMENT
# ============================================================

section "18. Configuring Backend Environment"

mkdir -p "$PROJECT_DIR/backend"

if [ -f "$PROJECT_DIR/backend/.env" ]; then

    warn "backend/.env already exists."
    warn "Existing .env will NOT be overwritten."

else

    echo
    echo "ShopCI Backend Configuration"
    echo "--------------------------------"
    echo

    read -r -s -p "Enter MySQL root password: " DB_PASSWORD
    echo

    read -r -s -p "Enter JWT secret: " JWT_SECRET
    echo

    if [[ -z "$DB_PASSWORD" ]]; then
        fail "MySQL password cannot be empty."
    fi

    if [[ -z "$JWT_SECRET" ]]; then
        fail "JWT secret cannot be empty."
    fi

    cat > "$PROJECT_DIR/backend/.env" <<ENVEOF
PORT=5000
DB_HOST=mysql
DB_USER=root
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=ecommerce_db
JWT_SECRET=${JWT_SECRET}
ENVEOF

    chmod 600 "$PROJECT_DIR/backend/.env"

    log "backend/.env created."

fi


# ============================================================
# 19. VALIDATE DOCKER COMPOSE
# ============================================================

section "19. Validating Docker Compose"

cd "$PROJECT_DIR"

docker compose config >/dev/null

log "docker-compose.yml is valid."


# ============================================================
# 20. FINAL VERIFICATION
# ============================================================

section "20. FINAL VERIFICATION"

echo
echo "Docker:"
docker --version

echo
echo "Docker Buildx:"
docker buildx version

echo
echo "Docker Compose:"
docker compose version

echo
echo "AWS CLI:"
aws --version

echo
echo "Docker Service:"
systemctl is-active docker

echo
echo "EC2 IAM Identity:"
aws sts get-caller-identity

echo
echo "Buildx Builders:"
docker buildx ls

echo
echo "Project Directory:"
echo "$PROJECT_DIR"

echo
echo "Git Branch:"
git branch --show-current

echo
echo "Latest Commit:"
git log -1 --oneline


# ============================================================
# 21. SETUP COMPLETE
# ============================================================

section "SHOPCI DOCKER ENVIRONMENT SETUP COMPLETED"

echo
echo "Successfully installed / verified:"
echo
echo "  [OK] Docker"
echo "  [OK] Docker Buildx"
echo "  [OK] Docker Compose"
echo "  [OK] AWS CLI"
echo "  [OK] EC2 IAM Role"
echo "  [OK] Git"
echo "  [OK] ShopCI Source Code"
echo "  [OK] Docker Compose Configuration"
echo "  [OK] Backend Environment"
echo

echo "============================================================"
echo " IMPORTANT"
echo "============================================================"

echo
echo "This setup.sh ONLY prepares the Docker environment."
echo
echo "It DOES NOT:"
echo
echo "  - Build Docker images"
echo "  - Start Docker Compose application"
echo "  - Deploy ShopCI"
echo "  - Run docker compose build"
echo "  - Run docker compose up"
echo "  - Run docker compose down"
echo

echo "============================================================"
echo " NEXT STEPS"
echo "============================================================"

echo
echo "Go to project:"
echo
echo "cd $PROJECT_DIR"
echo

echo "Build application:"
echo
echo "docker compose build"
echo

echo "Start application:"
echo
echo "docker compose up -d"
echo

echo "Check containers:"
echo
echo "docker compose ps"
echo

echo "View logs:"
echo
echo "docker compose logs -f"
echo

echo "Stop application:"
echo
echo "docker compose down"
echo

echo "IMPORTANT:"
echo
echo "Do NOT run:"
echo
echo "docker compose down -v"
echo
echo "unless you intentionally want to delete the MySQL volume."
echo

echo "============================================================"
echo " DOCKER ACCESS NOTE"
echo "============================================================"

echo
echo "ec2-user was added to the docker group."
echo
echo "If using ec2-user, reconnect to EC2 Instance Connect"
echo "before running Docker commands as ec2-user."
echo

echo "============================================================"
echo " SETUP COMPLETE"
echo "============================================================"
