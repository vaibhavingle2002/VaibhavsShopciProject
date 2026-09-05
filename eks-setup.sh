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
    echo

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
# 16. INSTALL KUBECTL
# ============================================================

section "16. Installing kubectl"

if command -v kubectl >/dev/null 2>&1; then

    log "kubectl is already installed."

else

    log "Installing latest stable kubectl..."

    KUBECTL_VERSION="$(
        curl -fsSL \
        --retry 3 \
        --retry-delay 2 \
        https://dl.k8s.io/release/stable.txt
    )"

    if [[ -z "$KUBECTL_VERSION" ]]; then
        fail "Could not determine kubectl version."
    fi

    echo
    echo "kubectl version : $KUBECTL_VERSION"
    echo "Architecture    : $KUBECTL_ARCH"
    echo

    KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl"

    echo "Downloading:"
    echo "$KUBECTL_URL"
    echo

    curl -fL \
        --retry 3 \
        --retry-delay 2 \
        "$KUBECTL_URL" \
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
        --retry 3 \
        --retry-delay 2 \
        https://api.github.com/repos/eksctl-io/eksctl/releases/latest \
        | jq -r '.tag_name'
    )"

    if [[ -z "$EKSCTL_VERSION" || "$EKSCTL_VERSION" == "null" ]]; then
        fail "Could not determine latest eksctl version."
    fi

    echo
    echo "eksctl version : $EKSCTL_VERSION"
    echo "Architecture   : $EKSCTL_ARCH"
    echo

    EKSCTL_URL="https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_${EKSCTL_ARCH}.tar.gz"

    echo "Downloading:"
    echo "$EKSCTL_URL"
    echo

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
        --retry 3 \
        --retry-delay 2 \
        https://api.github.com/repos/helm/helm/releases/latest \
        | jq -r '.tag_name'
    )"

    if [[ -z "$HELM_VERSION" || "$HELM_VERSION" == "null" ]]; then
        fail "Could not determine latest Helm version."
    fi

    echo
    echo "Helm version : $HELM_VERSION"
    echo "Architecture : $HELM_ARCH"
    echo

    HELM_URL="https://get.helm.sh/helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz"

    echo "Downloading:"
    echo "$HELM_URL"
    echo

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

    rm -rf /tmp/helm
    rm -f /tmp/helm.tar.gz

    log "Helm installed."

fi

echo
helm version


# ============================================================
# 19. VERIFY KUBERNETES TOOLS
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
