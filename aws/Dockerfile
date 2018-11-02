FROM stackfeed/alpine-python3:latest

ARG version
LABEL com.stackfeed.toolbox.vendor=StackFeed \
      com.stackfeed.toolbox.version=${version}

# Host user *IDs
ONBUILD ARG _USER=user
ONBUILD ARG _UID=1000
ONBUILD ARG _GID=1000

# Versions
ARG TF_VERSION=0.11.10
ARG TG_RELEASE=v0.17.1
ARG KOPS_VERSION=1.10.0
ARG HELM_RELEASE=v2.11.0
ARG HELMFILE_RELEASE=v0.40.1
ARG ARK_RELEASE=v0.9.10

ENV HELM_BINARY=/usr/bin/helm-binary

# List of plugins to enable in ZSH and theme
ONBUILD ARG ZSH_PLUGINS="aws helm kops kubectl terraform"
ONBUILD ARG ZSH_THEME=cloud

# KUBECTL_SOURCE: Change to kubernetes-dev/ci for CI
ARG KUBECTL_SOURCE=kubernetes-release/release
# KUBECTL_TRACK: Currently latest from KUBECTL_SOURCE. Change to latest-1.3.txt, etc. if desired.
ARG KUBECTL_TRACK=stable.txt

# Additional packages for the toolbox
RUN apk add --no-cache zsh sudo coreutils findutils jq fping make git \
        sed vim openssl openssh-client iptables gnupg

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
    DESIRED_VERSION="${HELM_RELEASE}" HELM_INSTALL_DIR="/usr/bin" sh -s && \
    mv /usr/bin/helm ${HELM_BINARY} && \
# fetch helmfile
    curl -sSL "https://github.com/roboll/helmfile/releases/download/${HELMFILE_RELEASE}/helmfile_linux_amd64" \
        -o /usr/bin/helmfile && chmod 755 /usr/bin/helmfile && \
# fetch heptio ark
    cd /tmp/ && curl --remote-name-all -sSLO https://github.com/heptio/ark/releases/download/${ARK_RELEASE}/{ark-${ARK_RELEASE}-linux-amd64.tar.gz,CHECKSUM} && \
        cat CHECKSUM | grep "${ARK_RELEASE}-linux-amd64" | sed "s/\s+/  /" | sha256sum -c && \
        tar -xzf ark-${ARK_RELEASE}-linux-amd64.tar.gz && mv ark /usr/bin && chmod 755 /usr/bin/ark && rm -rf /tmp/*

# Copy data
ADD ./entrypoint.sh /
ADD ./scripts/helm /usr/bin/helm

# Configure unprivileged user (remember NOT TO USE adduser from busybox!)
ONBUILD RUN \
# create user & group if those don't exist
    ( getent group ${_GID} &>/dev/null || groupadd -g ${_GID} ${_USER} ) && \
    ( id ${_UID} &>/dev/null || useradd -s /bin/zsh -md /home/${_USER} -u ${_UID} -g ${_GID} ${_USER} ) && \
    echo "#${_UID} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${_USER} && \
    chmod 440 /etc/sudoers.d/${_USER}

# Set unprivileged user
ONBUILD USER $_UID:$_GID
ONBUILD RUN \
# install oh-my-zsh and enable given plugins and theme (use bash to install)
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" && \
    awk '/^plugins=\(/,/\)/ { if ( $0 ~ /^plugins=\(/ ) print "plugins=('"${ZSH_PLUGINS}"')"; next } 1' ~/.zshrc > /tmp/.zshrc && \
    mv /tmp/.zshrc ~/.zshrc && sed -i 's/\(ZSH_THEME\)=".*"/\1="'${ZSH_THEME}'"/' ~/.zshrc

VOLUME ["/code"]
WORKDIR "/code"
ENTRYPOINT ["/entrypoint.sh"]
