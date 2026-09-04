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
# 1. Root check
# ------------------------------------------------------------

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script as root."
    echo "Run:"
    echo "sudo ./setup.sh"
    exit 1
fi

echo "[OK] Running as root."


# ------------------------------------------------------------
# 2. Detect OS
# ------------------------------------------------------------

if [ -f /etc/os-release ]; then
    source /etc/os-release
else
    echo "ERROR: /etc/os-release not found."
    exit 1
fi

echo "[INFO] Operating System: $PRETTY_NAME"


# ------------------------------------------------------------
# 3. Detect architecture
# ------------------------------------------------------------

ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        PLATFORM_ARCH="amd64"
        AWS_ARCH="x86_64"
        ;;
    aarch64)
        PLATFORM_ARCH="arm64"
        AWS_ARCH="aarch64"
        ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "[INFO] Architecture: $ARCH"


# ------------------------------------------------------------
# 4. Update system
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Updating system packages..."
echo "============================================================"

dnf update -y


# ------------------------------------------------------------
# 5. Install required packages
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
# 6. Verify curl
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

    echo "[OK] Docker package installed."

fi

systemctl enable --now docker

echo "[OK] Docker service is running."


# ------------------------------------------------------------
# 8. Configure Docker group
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
echo "Installing Docker Buildx..."
echo "============================================================"

DOCKER_CLI_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

mkdir -p "$DOCKER_CLI_PLUGIN_DIR"

if docker buildx version >/dev/null 2>&1; then

    echo "[OK] Docker Buildx is already available."

else

    echo "[INFO] Downloading Docker Buildx..."

    BUILDX_URL=$(curl -fsSL \
        https://api.github.com/repos/docker/buildx/releases/latest \
        | jq -r --arg arch "$PLATFORM_ARCH" \
        '.assets[] | select(.name | test("linux-" + $arch + "$")) | .browser_download_url' \
        | head -n 1)

    if [ -z "$BUILDX_URL" ] || [ "$BUILDX_URL" = "null" ]; then
        echo "ERROR: Could not find Docker Buildx download URL."
        exit 1
    fi

    echo "[INFO] Buildx URL found."

    curl -fL \
        "$BUILDX_URL" \
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

    echo "[OK] Docker Compose is already available."

else

    echo "[INFO] Downloading Docker Compose..."

    COMPOSE_URL=$(curl -fsSL \
        https://api.github.com/repos/docker/compose/releases/latest \
        | jq -r --arg arch "$PLATFORM_ARCH" \
        '.assets[] | select(.name == ("docker-compose-linux-" + $arch)) | .browser_download_url' \
        | head -n 1)

    if [ -z "$COMPOSE_URL" ] || [ "$COMPOSE_URL" = "null" ]; then
        echo "ERROR: Could not find Docker Compose download URL."
        echo ""
        echo "Available Docker Compose assets:"
        curl -fsSL \
            https://api.github.com/repos/docker/compose/releases/latest \
            | jq -r '.assets[].name'
        exit 1
    fi

    echo "[INFO] Compose URL found."

    curl -fL \
        "$COMPOSE_URL" \
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
# 12. Create Buildx builder
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
# 13. Install AWS CLI
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Installing AWS CLI..."
echo "============================================================"

if command -v aws >/dev/null 2>&1; then

    echo "[OK] AWS CLI is already installed."

else

    cd /tmp

    rm -rf aws awscliv2.zip

    echo "[INFO] Downloading AWS CLI..."

    curl -fL \
        "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" \
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

    KUBECTL_VERSION=$(curl -fsSL \
        https://dl.k8s.io/release/stable.txt)

    echo "[INFO] kubectl version: $KUBECTL_VERSION"

    curl -fL \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${PLATFORM_ARCH}/kubectl" \
        -o /usr/local/bin/kubectl

    chmod +x /usr/local/bin/kubectl

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

    EKSCTL_VERSION=$(curl -fsSL \
        https://api.github.com/repos/eksctl-io/eksctl/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$EKSCTL_VERSION" ] || [ "$EKSCTL_VERSION" = "null" ]; then
        echo "ERROR: Could not determine eksctl version."
        exit 1
    fi

    echo "[INFO] eksctl version: $EKSCTL_VERSION"

    cd /tmp

    rm -f eksctl.tar.gz eksctl

    curl -fL \
        "https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_${EKSCTL_VERSION#v}_Linux_${PLATFORM_ARCH}.tar.gz" \
        -o eksctl.tar.gz

    tar -xzf eksctl.tar.gz

    mv eksctl /usr/local/bin/eksctl

    chmod +x /usr/local/bin/eksctl

    rm -f eksctl.tar.gz

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

    HELM_VERSION=$(curl -fsSL \
        https://api.github.com/repos/helm/helm/releases/latest \
        | jq -r '.tag_name')

    if [ -z "$HELM_VERSION" ] || [ "$HELM_VERSION" = "null" ]; then
        echo "ERROR: Could not determine Helm version."
        exit 1
    fi

    echo "[INFO] Helm version: $HELM_VERSION"

    cd /tmp

    rm -f helm.tar.gz
    rm -rf "linux-${PLATFORM_ARCH}"

    curl -fL \
        "https://get.helm.sh/helm-${HELM_VERSION}-linux-${PLATFORM_ARCH}.tar.gz" \
        -o helm.tar.gz

    tar -xzf helm.tar.gz

    mv "linux-${PLATFORM_ARCH}/helm" /usr/local/bin/helm

    chmod +x /usr/local/bin/helm

    rm -f helm.tar.gz
    rm -rf "linux-${PLATFORM_ARCH}"

    echo "[OK] Helm installed."

fi


# ------------------------------------------------------------
# 17. Final verification
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
# 18. AWS IAM Role verification
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Checking EC2 IAM Role..."
echo "============================================================"

if aws sts get-caller-identity >/dev/null 2>&1; then

    echo "[OK] EC2 IAM Role is working."

    aws sts get-caller-identity

else

    echo ""
    echo "WARNING: AWS IAM Role could not be verified."
    echo ""
    echo "Make sure an IAM Role is attached to this EC2 instance."
    echo ""

fi


# ------------------------------------------------------------
# 19. Docker service
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Docker Service Status"
echo "============================================================"

systemctl is-active docker


# ------------------------------------------------------------
# 20. Complete
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "        ShopCI Environment Setup Completed"
echo "============================================================"

echo ""
echo "Installed successfully:"
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
echo "as ec2-user because the user was added to the docker group."

echo ""
echo "After reconnecting run:"
echo ""
echo "  docker ps"
echo "  docker compose version"
echo "  aws sts get-caller-identity"
echo "  kubectl version --client"
echo "  eksctl version"
echo "  helm version"

echo ""
echo "============================================================"
echo "                  SETUP COMPLETE"
echo "============================================================"
