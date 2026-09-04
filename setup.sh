#!/bin/bash

# ============================================================
# ShopCI - AWS DevOps Environment Setup Script
# OS: Amazon Linux 2023
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
    echo "Example: sudo ./setup.sh"
    exit 1
fi

echo "[OK] Running as root."


# ------------------------------------------------------------
# 2. OS Check
# ------------------------------------------------------------

if [ -f /etc/os-release ]; then
    source /etc/os-release
else
    echo "ERROR: Cannot detect operating system."
    exit 1
fi

echo "[INFO] Operating System: $PRETTY_NAME"

if [[ "$ID" != "amzn" ]]; then
    echo "WARNING: This script is designed for Amazon Linux."
fi


# ------------------------------------------------------------
# 3. System Update
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Updating system packages..."
echo "============================================================"

dnf update -y


# ------------------------------------------------------------
# 4. Install Required Packages
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
# 5. Verify curl
# Amazon Linux 2023 normally has curl-minimal.
# We intentionally DO NOT install full curl.
# ------------------------------------------------------------

echo ""
echo "Checking curl..."

if command -v curl >/dev/null 2>&1; then
    echo "[OK] curl is available."
else
    echo "ERROR: curl is not available."
    exit 1
fi


# ------------------------------------------------------------
# 6. Install Docker
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing Docker..."
echo "============================================================"

if command -v docker >/dev/null 2>&1; then
    echo "[INFO] Docker is already installed."
else

    dnf install -y docker

    systemctl start docker
    systemctl enable docker

    echo "[OK] Docker installed."

fi

systemctl start docker
systemctl enable docker

echo "[OK] Docker service is running."


# ------------------------------------------------------------
# 7. Add Users to Docker Group
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Configuring Docker permissions..."
echo "============================================================"

if id ec2-user >/dev/null 2>&1; then
    usermod -aG docker ec2-user
    echo "[OK] ec2-user added to docker group."
fi

if id "$SUDO_USER" >/dev/null 2>&1 && [ "$SUDO_USER" != "root" ]; then
    usermod -aG docker "$SUDO_USER"
    echo "[OK] $SUDO_USER added to docker group."
fi


# ------------------------------------------------------------
# 8. Detect Architecture
# ------------------------------------------------------------

ARCH=$(uname -m)

echo ""
echo "[INFO] System Architecture: $ARCH"

case "$ARCH" in

    x86_64)
        DOCKER_ARCH="amd64"
        AWS_ARCH="x86_64"
        KUBECTL_ARCH="amd64"
        EKSCTL_ARCH="amd64"
        ;;

    aarch64)
        DOCKER_ARCH="arm64"
        AWS_ARCH="aarch64"
        KUBECTL_ARCH="arm64"
        EKSCTL_ARCH="arm64"
        ;;

    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;

esac


# ------------------------------------------------------------
# 9. Docker Buildx
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing Docker Buildx..."
echo "============================================================"

DOCKER_CLI_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

mkdir -p "$DOCKER_CLI_PLUGIN_DIR"

if docker buildx version >/dev/null 2>&1; then

    echo "[INFO] Docker Buildx already installed."

else

    echo "[INFO] Downloading latest Docker Buildx..."

    BUILDX_VERSION=$(curl -s \
        https://api.github.com/repos/docker/buildx/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$BUILDX_VERSION" ] || [ "$BUILDX_VERSION" = "null" ]; then
        echo "ERROR: Could not determine Docker Buildx version."
        exit 1
    fi

    wget -q \
        -O "$DOCKER_CLI_PLUGIN_DIR/docker-buildx" \
        "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-${DOCKER_ARCH}"

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

    echo "[INFO] Docker Compose already installed."

else

    echo "[INFO] Downloading latest Docker Compose..."

    COMPOSE_VERSION=$(curl -s \
        https://api.github.com/repos/docker/compose/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$COMPOSE_VERSION" ] || [ "$COMPOSE_VERSION" = "null" ]; then
        echo "ERROR: Could not determine Docker Compose version."
        exit 1
    fi

    wget -q \
        -O "$DOCKER_CLI_PLUGIN_DIR/docker-compose" \
        "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${DOCKER_ARCH}"

    chmod +x "$DOCKER_CLI_PLUGIN_DIR/docker-compose"

    echo "[OK] Docker Compose installed."

fi


# ------------------------------------------------------------
# 11. Docker Buildx Builder
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
# 12. AWS CLI
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing AWS CLI..."
echo "============================================================"

if command -v aws >/dev/null 2>&1; then

    echo "[INFO] AWS CLI already installed."

else

    cd /tmp

    rm -f awscliv2.zip

    curl -sSL \
        "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
        -o awscliv2.zip

    rm -rf aws

    unzip -q awscliv2.zip

    ./aws/install

    rm -rf aws awscliv2.zip

    echo "[OK] AWS CLI installed."

fi


# ------------------------------------------------------------
# 13. kubectl
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing kubectl..."
echo "============================================================"

if command -v kubectl >/dev/null 2>&1; then

    echo "[INFO] kubectl already installed."

else

    KUBECTL_VERSION=$(curl -L -s \
        https://dl.k8s.io/release/stable.txt)

    curl -L -s \
        -o /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

    chmod +x /usr/local/bin/kubectl

    echo "[OK] kubectl installed."

fi


# ------------------------------------------------------------
# 14. eksctl
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing eksctl..."
echo "============================================================"

if command -v eksctl >/dev/null 2>&1; then

    echo "[INFO] eksctl already installed."

else

    EKSCTL_VERSION=$(curl -s \
        https://api.github.com/repos/eksctl-io/eksctl/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$EKSCTL_VERSION" ] || [ "$EKSCTL_VERSION" = "null" ]; then
        echo "ERROR: Could not determine eksctl version."
        exit 1
    fi

    wget -q \
        -O /tmp/eksctl.tar.gz \
        "https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_${EKSCTL_VERSION#v}_Linux_${ARCH}.tar.gz"

    tar -xzf /tmp/eksctl.tar.gz -C /tmp

    mv /tmp/eksctl /usr/local/bin/eksctl

    chmod +x /usr/local/bin/eksctl

    rm -f /tmp/eksctl.tar.gz

    echo "[OK] eksctl installed."

fi


# ------------------------------------------------------------
# 15. Helm
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing Helm..."
echo "============================================================"

if command -v helm >/dev/null 2>&1; then

    echo "[INFO] Helm already installed."

else

    HELM_VERSION=$(curl -s \
        https://api.github.com/repos/helm/helm/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$HELM_VERSION" ] || [ "$HELM_VERSION" = "null" ]; then
        echo "ERROR: Could not determine Helm version."
        exit 1
    fi

    wget -q \
        -O /tmp/helm.tar.gz \
        "https://get.helm.sh/helm-${HELM_VERSION}-linux-${DOCKER_ARCH}.tar.gz"

    tar -xzf /tmp/helm.tar.gz -C /tmp

    mv "/tmp/linux-${DOCKER_ARCH}/helm" /usr/local/bin/helm

    chmod +x /usr/local/bin/helm

    rm -rf \
        /tmp/helm.tar.gz \
        "/tmp/linux-${DOCKER_ARCH}"

    echo "[OK] Helm installed."

fi


# ------------------------------------------------------------
# 16. Verify Docker
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Docker Verification"
echo "============================================================"

docker --version

echo ""
docker buildx version

echo ""
docker compose version


# ------------------------------------------------------------
# 17. Verify Docker Service
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Docker Service Status"
echo "============================================================"

systemctl is-active docker

echo ""
docker info >/dev/null 2>&1 && \
    echo "[OK] Docker daemon is accessible."


# ------------------------------------------------------------
# 18. Verify AWS CLI
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "AWS CLI Verification"
echo "============================================================"

aws --version


# ------------------------------------------------------------
# 19. Verify kubectl
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "kubectl Verification"
echo "============================================================"

kubectl version --client


# ------------------------------------------------------------
# 20. Verify eksctl
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "eksctl Verification"
echo "============================================================"

eksctl version


# ------------------------------------------------------------
# 21. Verify Helm
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Helm Verification"
echo "============================================================"

helm version


# ------------------------------------------------------------
# 22. AWS IAM Role Verification
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Checking AWS IAM Role..."
echo "============================================================"

if aws sts get-caller-identity >/dev/null 2>&1; then

    echo "[OK] AWS credentials/IAM role detected."

    aws sts get-caller-identity

else

    echo ""
    echo "WARNING: AWS credentials/IAM role could not be detected."
    echo ""
    echo "If you are using an EC2 IAM Role, verify that:"
    echo "1. IAM Role is attached to this EC2 instance."
    echo "2. The role has the required permissions."
    echo "3. Instance Metadata Service is accessible."
    echo ""

fi


# ------------------------------------------------------------
# 23. Final Output
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "        ShopCI Environment Setup Completed"
echo "============================================================"

echo ""
echo "Installed/Verified:"
echo "  ✓ Git"
echo "  ✓ Docker"
echo "  ✓ Docker Buildx"
echo "  ✓ Docker Compose"
echo "  ✓ AWS CLI"
echo "  ✓ kubectl"
echo "  ✓ eksctl"
echo "  ✓ Helm"

echo ""
echo "IMPORTANT:"
echo "Docker group permissions require a new login session."

echo ""
echo "Reconnect to EC2 Instance Connect before running:"
echo ""
echo "  docker ps"
echo "  docker compose version"
echo "  aws sts get-caller-identity"
echo ""

echo "============================================================"
echo "              Setup Finished Successfully"
echo "============================================================"
