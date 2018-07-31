FROM stackfeed/alpine-python3

LABEL vendor=StackFeed \
      version_tags="[\"aws\", \"aws-tf-0.11.7\", \"aws-kops-1.9.2\"]"

# Host user *IDs
ONBUILD ARG _USER=user
ONBUILD ARG _UID=1000
ONBUILD ARG _GID=1000

ARG TF_VERSION=0.11.7
ARG TG_VERSION=0.16.3
ARG KOPS_RELEASE=1.9.2
ARG HELM_RELEASE=v2.9.1

# KUBECTL_SOURCE: Change to kubernetes-dev/ci for CI
ARG KUBECTL_SOURCE=kubernetes-release/release
# KUBECTL_TRACK: Currently latest from KUBECTL_SOURCE. Change to latest-1.3.txt, etc. if desired.
ARG KUBECTL_TRACK=stable.txt

# Additional packages for the toolbox
RUN apk add --no-cache zsh vim sudo jq fping make git openssl openssh-client iptables

# Install awscli & terraform
RUN pip install awscli sshuttle && apk add --no-cache groff less mailcap && \
    curl -sSL https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip -o /tmp/terraform.zip && \
              unzip /tmp/terraform.zip -d /usr/bin && \
    curl -sSL https://github.com/gruntwork-io/terragrunt/releases/download/v${TG_VERSION}/terragrunt_linux_amd64 -o /usr/bin/terragrunt && \
              chmod 755 /usr/bin/terragrunt && \
    rm -rf /tmp/* /tmp/.* /root/* /root/.* &>/dev/null

# Get kops, kubectl and helm
RUN curl -SsL --retry 5 -o /usr/bin/kops https://github.com/kubernetes/kops/releases/download/${KOPS_RELEASE}/kops-linux-amd64 && \
    KUBECTL_VERSION=$(curl -SsL --retry 5 "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_TRACK}") && \
    curl -SsL --retry 5 "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" > /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl /usr/bin/kops && \
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | \
    DESIRED_VERSION="${HELM_RELEASE}" HELM_INSTALL_DIR="/usr/bin" sh -s

# entrypoint (bash is the default default)
ADD ./entrypoint.sh /
COPY ./oh-my-zsh /opt/oh-my-zsh
ENTRYPOINT ["/entrypoint.sh"]

# Configure unprivileged user (remember NOT TO USE adduser from busybox!)
ONBUILD RUN \
    # create user & group if those don't exist
        ( getent group ${_GID} &>/dev/null || groupadd -g ${_GID} ${_USER} ) && \
        ( id ${_UID} &>/dev/null || useradd -s /bin/zsh -md /home/${_USER} -u ${_UID} -g ${_GID} ${_USER} ) && \
        echo "${_USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${_USER} && \
        chmod 440 /etc/sudoers.d/${_USER} && \
    # link to home oh-my-zsh
        export USER_HOME=$(getent passwd ${_UID} | cut -f6 -d:) && \
        chown -R $_UID:$_GID /opt/oh-my-zsh && \
        echo ". /opt/oh-my-zsh/oh-my-zsh.sh" > ${USER_HOME}/.zshrc && \
    # add plugins for k8s
        echo "plugins=(aws helm kops kubectl terraform)" >> ${USER_HOME}/.zshrc

ONBUILD USER $_UID:$_GID

VOLUME ["/code"]
WORKDIR "/code"
