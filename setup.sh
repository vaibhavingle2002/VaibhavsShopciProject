cat > ~/shopci-setup.sh <<'EOF'
#!/bin/bash

set -Eeuo pipefail

# ============================================================
# SHOPCI - AMAZON LINUX 2023 DEVOPS ENVIRONMENT SETUP
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
    warn "This script is designed for Amazon Linux."
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
    openssl

if command -v curl >/dev/null 2>&1; then
    log "curl is available."
else
    fail "curl is not available on this system."
fi

echo
curl --version | head -1
git --version
jq --version

log "Required utilities installed."


# ============================================================
# 5. INSTALL DOCKER
# ============================================================

section "5. Installing Docker"

if command -v docker >/dev/null 2>&1; then
    log "Docker is already installed."
else
    log "Installing Docker..."
    dnf install -y docker
fi

echo
docker --version


# ============================================================
# 6. START DOCKER
# ============================================================

section "6. Starting Docker Service"

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
# 7. DOCKER GROUP
# ============================================================

section "7. Configuring Docker Group"

if id ec2-user >/dev/null 2>&1; then
    usermod -aG docker ec2-user
    log "Added ec2-user to docker group."
else
    log "ec2-user does not exist. Current user is root."
fi


# ============================================================
# 8. DETECT CPU ARCHITECTURE
# ============================================================

section "8. Detecting CPU Architecture"

ARCH="$(uname -m)"

case "$ARCH" in

    x86_64)
        BUILDX_ARCH="amd64"
        COMPOSE_ARCH="x86_64"
        KUBECTL_ARCH="amd64"
        EKSCTL_ARCH="amd64"
        HELM_ARCH="amd64"
        ;;

    aarch64)
        BUILDX_ARCH="arm64"
        COMPOSE_ARCH="aarch64"
        KUBECTL_ARCH="arm64"
        EKSCTL_ARCH="arm64"
        HELM_ARCH="arm64"
        ;;

    arm64)
        BUILDX_ARCH="arm64"
        COMPOSE_ARCH="aarch64"
        KUBECTL_ARCH="arm64"
        EKSCTL_ARCH="arm64"
        HELM_ARCH="arm64"
        ;;

    *)
        fail "Unsupported architecture: $ARCH"
        ;;

esac

echo "System architecture : $ARCH"
echo "Buildx architecture  : $BUILDX_ARCH"
echo "Compose architecture : $COMPOSE_ARCH"
echo "kubectl architecture : $KUBECTL_ARCH"
echo "eksctl architecture  : $EKSCTL_ARCH"
echo "Helm architecture    : $HELM_ARCH"


# ============================================================
# 9. DOCKER CLI PLUGIN DIRECTORY
# ============================================================

section "9. Preparing Docker CLI Plugins"

mkdir -p "$PLUGIN_DIR"

rm -f /usr/libexec/docker/cli-plugins/docker-buildx
rm -f /usr/libexec/docker/cli-plugins/docker-compose

rm -f /root/.docker/cli-plugins/docker-buildx
rm -f /root/.docker/cli-plugins/docker-compose

rm -f "$PLUGIN_DIR/docker-buildx"
rm -f "$PLUGIN_DIR/docker-compose"

log "Old manually installed Docker plugins removed."


# ============================================================
# 10. INSTALL LATEST DOCKER BUILDX
# ============================================================

section "10. Installing Docker Buildx"

BUILDX_VERSION="$(
    curl -fsSL \
    https://api.github.com/repos/docker/buildx/releases/latest \
    | jq -r '.tag_name'
)"

if [[ -z "$BUILDX_VERSION" || "$BUILDX_VERSION" == "null" ]]; then
    fail "Could not determine latest Buildx release."
fi

echo "Buildx version: $BUILDX_VERSION"

BUILDX_URL="https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${BUILDX_ARCH}"

echo "Downloading:"
echo "$BUILDX_URL"

curl -fL \
    --retry 3 \
    --retry-delay 2 \
    "$BUILDX_URL" \
    -o "$PLUGIN_DIR/docker-buildx"

chmod +x "$PLUGIN_DIR/docker-buildx"

if [ ! -x "$PLUGIN_DIR/docker-buildx" ]; then
    fail "Buildx installation failed."
fi

log "Docker Buildx installed."


# ============================================================
# 11. INSTALL LATEST DOCKER COMPOSE
# ============================================================

section "11. Installing Docker Compose"

COMPOSE_VERSION="$(
    curl -fsSL \
    https://api.github.com/repos/docker/compose/releases/latest \
    | jq -r '.tag_name'
)"

if [[ -z "$COMPOSE_VERSION" || "$COMPOSE_VERSION" == "null" ]]; then
    fail "Could not determine latest Docker Compose release."
fi

echo "Compose version: $COMPOSE_VERSION"

COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${COMPOSE_ARCH}"

echo "Downloading:"
echo "$COMPOSE_URL"

curl -fL \
    --retry 3 \
    --retry-delay 2 \
    "$COMPOSE_URL" \
    -o "$PLUGIN_DIR/docker-compose"

chmod +x "$PLUGIN_DIR/docker-compose"

if [ ! -x "$PLUGIN_DIR/docker-compose" ]; then
    fail "Docker Compose installation failed."
fi

log "Docker Compose installed."


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
echo "Compose:"
docker compose version

echo
echo "Docker Info:"
docker info >/dev/null

log "Docker + Buildx + Compose are working."


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

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        -o "$AWS_ZIP"

    rm -rf /tmp/aws

    unzip -q "$AWS_ZIP" -d /tmp

    /tmp/aws/install --update

    rm -rf "$AWS_ZIP" /tmp/aws

    log "AWS CLI installed."

fi

echo
aws --version


# ============================================================
# 15. VERIFY EC2 IAM ROLE
# ============================================================

section "15. Checking EC2 IAM Role"

if aws sts get-caller-identity >/tmp/shopci-identity.json 2>/tmp/shopci-identity-error.log; then

    log "EC2 IAM Role is working."

    cat /tmp/shopci-identity.json

else

    warn "AWS CLI is installed, but EC2 IAM Role verification failed."

    cat /tmp/shopci-identity-error.log

    warn "Make sure an IAM Role is attached to this EC2 instance."

fi


# ============================================================
# 16. INSTALL KUBECTL
# ============================================================

section "16. Installing kubectl"

if command -v kubectl >/dev/null 2>&1; then

    log "kubectl is already installed."

else

    log "Installing latest stable kubectl..."

    KUBECTL_VERSION="$(
        curl -fsSL https://dl.k8s.io/release/stable.txt
    )"

    echo "kubectl version: $KUBECTL_VERSION"

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" \
        -o /usr/local/bin/kubectl

    chmod +x /usr/local/bin/kubectl

    log "kubectl installed."

fi

echo
kubectl version --client


# ============================================================
# 17. INSTALL EKSCTL
# ============================================================

section "17. Installing eksctl"

if command -v eksctl >/dev/null 2>&1; then

    log "eksctl is already installed."

else

    log "Installing latest eksctl..."

    EKSCTL_VERSION="$(
        curl -fsSL \
        https://api.github.com/repos/eksctl-io/eksctl/releases/latest \
        | jq -r '.tag_name'
    )"

    if [[ -z "$EKSCTL_VERSION" || "$EKSCTL_VERSION" == "null" ]]; then
        fail "Could not determine latest eksctl release."
    fi

    echo "eksctl version: $EKSCTL_VERSION"

    EKSCTL_URL="https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_${EKSCTL_ARCH}.tar.gz"

    echo "Downloading:"
    echo "$EKSCTL_URL"

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "$EKSCTL_URL" \
        -o /tmp/eksctl.tar.gz

    tar -xzf /tmp/eksctl.tar.gz \
        -C /usr/local/bin \
        eksctl

    chmod +x /usr/local/bin/eksctl

    rm -f /tmp/eksctl.tar.gz

    log "eksctl installed."

fi

echo
eksctl version


# ============================================================
# 18. INSTALL HELM
# ============================================================

section "18. Installing Helm"

if command -v helm >/dev/null 2>&1; then

    log "Helm is already installed."

else

    log "Installing latest Helm..."

    HELM_VERSION="$(
        curl -fsSL \
        https://api.github.com/repos/helm/helm/releases/latest \
        | jq -r '.tag_name'
    )"

    if [[ -z "$HELM_VERSION" || "$HELM_VERSION" == "null" ]]; then
        fail "Could not determine latest Helm release."
    fi

    echo "Helm version: $HELM_VERSION"

    HELM_URL="https://get.helm.sh/helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz"

    echo "Downloading:"
    echo "$HELM_URL"

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "$HELM_URL" \
        -o /tmp/helm.tar.gz

    rm -rf /tmp/helm

    mkdir -p /tmp/helm

    tar -xzf /tmp/helm.tar.gz \
        -C /tmp/helm

    install -m 0755 \
        "/tmp/helm/linux-${HELM_ARCH}/helm" \
        /usr/local/bin/helm

    rm -rf /tmp/helm /tmp/helm.tar.gz

    log "Helm installed."

fi

echo
helm version


# ============================================================
# 19. VERIFY KUBERNETES DEVOPS TOOLS
# ============================================================

section "19. Verifying Kubernetes Tools"

echo
echo "kubectl:"
kubectl version --client

echo
echo "eksctl:"
eksctl version

echo
echo "Helm:"
helm version

log "Kubernetes tools are working."


# ============================================================
# 20. GET SHOPCI PROJECT
# ============================================================

section "20. Getting ShopCI Source Code"

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
# 21. CHECK SHOPCI FILES
# ============================================================

section "21. Checking ShopCI Project Files"

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
# 22. CREATE BACKEND ENVIRONMENT
# ============================================================

section "22. Configuring Backend Environment"

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
# 23. VALIDATE DOCKER COMPOSE
# ============================================================

section "23. Validating Docker Compose"

cd "$PROJECT_DIR"

docker compose config >/dev/null

log "docker-compose.yml is valid."


# ============================================================
# 24. FINAL VERIFICATION
# ============================================================

section "24. FINAL VERIFICATION"

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
echo "kubectl:"
kubectl version --client

echo
echo "eksctl:"
eksctl version

echo
echo "Helm:"
helm version

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


# ============================================================
# IMPORTANT - NO APPLICATION BUILD/DEPLOY
# ============================================================

section "SETUP COMPLETE"

echo
echo "ShopCI DevOps Environment Setup Completed Successfully."
echo

echo "Installed / Verified:"
echo "  [OK] Docker"
echo "  [OK] Docker Buildx"
echo "  [OK] Docker Compose"
echo "  [OK] AWS CLI"
echo "  [OK] kubectl"
echo "  [OK] eksctl"
echo "  [OK] Helm"
echo "  [OK] EC2 IAM Role"
echo "  [OK] ShopCI Source Code"
echo "  [OK] Docker Compose Configuration"
echo "  [OK] Backend Environment"
echo

echo "IMPORTANT:"
echo "This setup script DOES NOT:"
echo "  - Build Docker images"
echo "  - Start ShopCI containers"
echo "  - Deploy ShopCI"
echo "  - Run docker compose up"
echo "  - Run docker compose build"
echo

echo "Next steps must be run manually:"
echo
echo "cd $PROJECT_DIR"
echo
echo "docker compose build"
echo
echo "docker compose up -d"
echo

echo "Useful commands:"
echo
echo "docker compose ps"
echo "docker compose logs -f"
echo "docker compose restart"
echo "docker compose down"
echo

echo "IMPORTANT:"
echo "Do NOT run:"
echo "docker compose down -v"
echo "unless you intentionally want to delete the MySQL volume."
echo

echo "Kubernetes tools:"
echo
echo "kubectl version --client"
echo "eksctl version"
echo "helm version"
echo

echo "AWS IAM:"
echo
echo "aws sts get-caller-identity"
echo

echo "IMPORTANT:"
echo "If using ec2-user instead of root, reconnect to"
echo "EC2 Instance Connect after this script completes so"
echo "the docker group membership takes effect."
echo

echo "============================================================"
echo " SHOPCI SETUP COMPLETED"
echo "============================================================"
echo

EOF
