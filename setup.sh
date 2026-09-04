#!/bin/bash

# ============================================================
# ShopCI - AWS DevOps Environment Setup
# Amazon Linux 2023
# ============================================================

set -e

echo "============================================================"
echo "        ShopCI - DevOps Environment Setup"
echo "============================================================"

# ------------------------------------------------------------
# 1. Root Check
# ------------------------------------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root."
    echo "Use: sudo ./setup.sh"
    exit 1
fi

echo "[OK] Running as root."


# ------------------------------------------------------------
# 2. Operating System
# ------------------------------------------------------------

if [ -f /etc/os-release ]; then
    source /etc/os-release
else
    echo "ERROR: Cannot detect operating system."
    exit 1
fi

echo "[INFO] Operating System: $PRETTY_NAME"


# ------------------------------------------------------------
# 3. Architecture
# ------------------------------------------------------------

ARCH=$(uname -m)

echo "[INFO] Architecture: $ARCH"

if [ "$ARCH" != "x86_64" ]; then
    echo "ERROR: This setup script is currently designed for x86_64."
    exit 1
fi


# ------------------------------------------------------------
# 4. Update System
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Updating system packages..."
echo "============================================================"

dnf update -y


# ------------------------------------------------------------
# 5. Install Required Packages
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing required packages..."
echo "============================================================"

dnf install -y \
    git \
    jq \
    wget \
    unzip \
    tar \
    gzip \
    ca-certificates \
    openssl

echo "[OK] Required packages installed."


# ------------------------------------------------------------
# 6. Check curl
# ------------------------------------------------------------

echo ""
echo "Checking curl..."

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl is not available."
    exit 1
fi

echo "[OK] curl is available."


# ------------------------------------------------------------
# 7. Install Docker
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing Docker..."
echo "============================================================"

if command -v docker >/dev/null 2>&1; then
    echo "[INFO] Docker is already installed."
else
    dnf install -y docker
    echo "[OK] Docker installed."
fi

systemctl enable --now docker

echo "[OK] Docker service is running."


# ------------------------------------------------------------
# 8. Docker Group
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Configuring Docker permissions..."
echo "============================================================"

if id ec2-user >/dev/null 2>&1; then
    usermod -aG docker ec2-user
    echo "[OK] ec2-user added to docker group."
fi


# ------------------------------------------------------------
# 9. Docker Buildx
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Checking Docker Buildx..."
echo "============================================================"

DOCKER_CLI_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

mkdir -p "$DOCKER_CLI_PLUGIN_DIR"

if docker buildx version >/dev/null 2>&1; then

    echo "[OK] Docker Buildx is already installed."

else

    echo "[INFO] Installing Docker Buildx..."

    BUILDX_VERSION=$(curl -fsSL \
        https://api.github.com/repos/docker/buildx/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$BUILDX_VERSION" ] || [ "$BUILDX_VERSION" = "null" ]; then
        echo "ERROR: Could not determine Buildx version."
        exit 1
    fi

    curl -fL \
        "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64" \
        -o "$DOCKER_CLI_PLUGIN_DIR/docker-buildx"

    chmod +x "$DOCKER_CLI_PLUGIN_DIR/docker-buildx"

    echo "[OK] Docker Buildx installed."

fi


# ------------------------------------------------------------
# 10. Docker Compose
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing Docker Compose..."
echo "============================================================"

if docker compose version >/dev/null 2>&1; then

    echo "[OK] Docker Compose is already installed."

else

    echo "[INFO] Installing Docker Compose..."

    COMPOSE_VERSION=$(curl -fsSL \
        https://api.github.com/repos/docker/compose/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$COMPOSE_VERSION" ] || [ "$COMPOSE_VERSION" = "null" ]; then
        echo "ERROR: Could not determine Docker Compose version."
        exit 1
    fi

    echo "[INFO] Compose version: $COMPOSE_VERSION"

    curl -fL \
        "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
        -o "$DOCKER_CLI_PLUGIN_DIR/docker-compose"

    chmod +x "$DOCKER_CLI_PLUGIN_DIR/docker-compose"

    echo "[OK] Docker Compose installed."

fi


# ------------------------------------------------------------
# 11. Verify Docker Compose
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Verifying Docker Compose..."
echo "============================================================"

docker compose version


# ------------------------------------------------------------
# 12. Create Buildx Builder
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Configuring Docker Buildx builder..."
echo "============================================================"

if docker buildx inspect shopci-builder >/dev/null 2>&1; then

    echo "[INFO] shopci-builder already exists."

else

    docker buildx create \
        --name shopci-builder \
        --use

    echo "[OK] shopci-builder created."

fi

docker buildx use shopci-builder


# ------------------------------------------------------------
# 13. AWS CLI
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Checking AWS CLI..."
echo "============================================================"

if command -v aws >/dev/null 2>&1; then

    echo "[OK] AWS CLI is already installed."

else

    echo "[INFO] Installing AWS CLI..."

    cd /tmp

    rm -rf aws awscliv2.zip

    curl -fL \
        https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
        -o awscliv2.zip

    unzip -q awscliv2.zip

    ./aws/install

    rm -rf aws awscliv2.zip

    echo "[OK] AWS CLI installed."

fi


# ------------------------------------------------------------
# 14. Install kubectl
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing kubectl..."
echo "============================================================"

if command -v kubectl >/dev/null 2>&1; then

    echo "[OK] kubectl is already installed."

else

    echo "[INFO] Downloading kubectl v1.30.0..."

    cd /tmp

    rm -f kubectl

    curl -fLO \
        https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl

    chmod +x kubectl

    mv kubectl /usr/local/bin/kubectl

    echo "[OK] kubectl installed."

fi


# ------------------------------------------------------------
# 15. Install eksctl
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing eksctl..."
echo "============================================================"

if command -v eksctl >/dev/null 2>&1; then

    echo "[OK] eksctl is already installed."

else

    echo "[INFO] Installing eksctl..."

    cd /tmp

    rm -f eksctl.tar.gz

    curl --silent --location \
        "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
        | tar xz

    mv eksctl /usr/local/bin/eksctl

    chmod +x /usr/local/bin/eksctl

    echo "[OK] eksctl installed."

fi


# ------------------------------------------------------------
# 16. Install Helm
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing Helm..."
echo "============================================================"

if command -v helm >/dev/null 2>&1; then

    echo "[OK] Helm is already installed."

else

    echo "[INFO] Installing Helm..."

    curl -fsSL \
        https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
        | bash

    echo "[OK] Helm installed."

fi


# ------------------------------------------------------------
# 17. Final Verification
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "              FINAL VERIFICATION"
echo "============================================================"

echo ""
echo "Docker:"
docker --version

echo ""
echo "Docker Buildx:"
docker buildx version

echo ""
echo "Docker Compose:"
docker compose version

echo ""
echo "AWS CLI:"
aws --version

echo ""
echo "kubectl:"
kubectl version --client

echo ""
echo "eksctl:"
eksctl version

echo ""
echo "Helm:"
helm version


# ------------------------------------------------------------
# 18. Docker Status
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Docker Service Status"
echo "============================================================"

systemctl is-active docker


# ------------------------------------------------------------
# 19. AWS IAM Role Verification
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Checking EC2 IAM Role..."
echo "============================================================"

if aws sts get-caller-identity >/dev/null 2>&1; then

    echo "[OK] EC2 IAM Role is working."

    aws sts get-caller-identity

else

    echo "WARNING: AWS IAM Role could not be verified."
    echo "Make sure an IAM Role is attached to the EC2 instance."

fi


# ------------------------------------------------------------
# 20. Complete
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "        ShopCI Environment Setup Completed"
echo "============================================================"

echo ""
echo "Successfully installed/verified:"
echo "  [OK] Docker"
echo "  [OK] Docker Buildx"
echo "  [OK] Docker Compose"
echo "  [OK] AWS CLI"
echo "  [OK] kubectl"
echo "  [OK] eksctl"
echo "  [OK] Helm"

echo ""
echo "IMPORTANT:"
echo "Reconnect to EC2 Instance Connect before using Docker"
echo "as ec2-user, because ec2-user was added to the docker group."

echo ""
echo "After reconnecting, verify:"
echo ""
echo "docker ps"
echo "docker compose version"
echo "aws sts get-caller-identity"
echo "kubectl version --client"
echo "eksctl version"
echo "helm version"

echo ""
echo "============================================================"
echo "                  SETUP COMPLETE"
echo "============================================================"
