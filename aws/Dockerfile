FROM stackfeed/alpine-python3

LABEL vendor=StackFeed \
      version_tags="[\"aws\", \"aws-tf-0.11.7\", \"aws-kops-1.9.2\"]"

# Host user *IDs
ONBUILD ARG _USER=user
ONBUILD ARG _UID=1000
ONBUILD ARG _GID=1000

ARG TF_VERSION=0.11.7
ARG TG_RELEASE=v0.16.3
ARG KOPS_VERSION=1.9.2
ARG HELM_RELEASE=v2.9.1

# KUBECTL_SOURCE: Change to kubernetes-dev/ci for CI
ARG KUBECTL_SOURCE=kubernetes-release/release
# KUBECTL_TRACK: Currently latest from KUBECTL_SOURCE. Change to latest-1.3.txt, etc. if desired.
ARG KUBECTL_TRACK=stable.txt

# Additional packages for the toolbox
RUN apk add --no-cache zsh vim sudo jq fping make git openssl openssh-client iptables

# Install awscli & terraform
RUN pip install awscli sshuttle && apk add --no-cache groff less mailcap && \
    curl -sSL https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
        -o /tmp/terraform.zip && unzip /tmp/terraform.zip -d /usr/bin && \
    curl -sSL https://github.com/gruntwork-io/terragrunt/releases/download/${TG_RELEASE}/terragrunt_linux_amd64 \
        -o /usr/bin/terragrunt && chmod 755 /usr/bin/terragrunt && \
    rm -rf /tmp/* /tmp/.* /root/* /root/.* &>/dev/null || /bin/true

RUN \
# fetch kops
    curl -sSL https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
        -o /usr/bin/kops && \
# fetch kubectl
    KUBECTL_VERSION=$(curl -sSL "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_TRACK}") && \
#
    curl -sSL "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
         -o /usr/bin/kubectl && chmod 755 /usr/bin/kubectl /usr/bin/kops && \
# fetch helm
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | \
    DESIRED_VERSION="${HELM_RELEASE}" HELM_INSTALL_DIR="/usr/bin" sh -s

# Copy data
COPY ./oh-my-zsh /opt/oh-my-zsh
ADD  ./entrypoint.sh /

# Configure unprivileged user (remember NOT TO USE adduser from busybox!)
ONBUILD RUN \
# create user & group if those don't exist
    ( getent group ${_GID} &>/dev/null || groupadd -g ${_GID} ${_USER} ) && \
    ( id ${_UID} &>/dev/null || useradd -s /bin/zsh -md /home/${_USER} -u ${_UID} -g ${_GID} ${_USER} ) && \
    echo "#${_UID} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${_USER} && \
    chmod 440 /etc/sudoers.d/${_USER} && \
# link to home oh-my-zsh
    export USER_HOME=$(getent passwd ${_UID} | cut -f6 -d:) && \
    chown -R $_UID:$_GID /opt/oh-my-zsh && \
    echo -e "export ZSH=/opt/oh-my-zsh\n. \$ZSH/oh-my-zsh.sh" > ${USER_HOME}/.zshrc && \
# add plugins for k8s
    echo "plugins=(aws helm kops kubectl terraform)" >> ${USER_HOME}/.zshrc

# Set unprivileged user
ONBUILD USER $_UID:$_GID

VOLUME ["/code"]
WORKDIR "/code"
ENTRYPOINT ["/entrypoint.sh"]
