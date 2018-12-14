FROM stackfeed/alpine-python3:latest

ARG version
LABEL com.stackfeed.k8s-ops.vendor=StackFeed \
      com.stackfeed.k8s-ops.version=${version}

# Versions
ARG TF_VERSION=0.11.10
ARG TG_RELEASE=v0.17.1
ARG KOPS_VERSION=1.10.0
ARG HELM_RELEASE=v2.11.0
ARG HELMFILE_RELEASE=v0.40.2
ARG ARK_RELEASE=v0.9.10
ARG AUTHENTICATOR_RELEASE=v0.3.0

# List of plugins to enable in ZSH and theme
ENV ZSH_PLUGINS="aws helm kops kubectl terraform"
ENV ZSH_THEME=cloud

ENV HELM_BINARY=/usr/local/bin/helm-binary
ENV HELM_FORCE_TLS=no
ENV FIXUID_CHECKSUM=e901f3b21e62ebed92172df969bfc6cbfdfa8f53afb060f20f25e77dcbc20ff5


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
        -o /tmp/terraform.zip && unzip /tmp/terraform.zip -d /usr/local/bin && \
    curl -sSL https://github.com/gruntwork-io/terragrunt/releases/download/${TG_RELEASE}/terragrunt_linux_amd64 \
        -o /usr/local/bin/terragrunt && chmod 755 /usr/local/bin/terragrunt && \
    rm -rf /tmp/* /tmp/.* /root/* /root/.* &>/dev/null || /bin/true

RUN \
# fetch kops
    curl -sSL https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
        -o /usr/local/bin/kops && \
# fetch kubectl
    KUBECTL_VERSION=$(curl -sSL "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_TRACK}") && \
#
    curl -sSL "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
        -o /usr/local/bin/kubectl && chmod 755 /usr/local/bin/kubectl /usr/local/bin/kops && \
# fetch helm
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | \
    DESIRED_VERSION="${HELM_RELEASE}" HELM_INSTALL_DIR="/usr/local/bin" sh -s && \
    mv /usr/local/bin/helm ${HELM_BINARY} && \
# fetch helmfile
    curl -sSL "https://github.com/roboll/helmfile/releases/download/${HELMFILE_RELEASE}/helmfile_linux_amd64" \
        -o /usr/local/bin/helmfile && chmod 755 /usr/local/bin/helmfile && \
# fetch heptio ark
    cd /tmp/ && curl --remote-name-all -sSLO https://github.com/heptio/ark/releases/download/${ARK_RELEASE}/{ark-${ARK_RELEASE}-linux-amd64.tar.gz,CHECKSUM} && \
        cat CHECKSUM | grep "${ARK_RELEASE}-linux-amd64" | sed "s/\s+/  /" | sha256sum -c && \
        tar -xzf ark-${ARK_RELEASE}-linux-amd64.tar.gz && mv ark /usr/local/bin && \
        chown root:root /usr/local/bin/ark && chmod 755 /usr/local/bin/ark && rm -rf /tmp/* && \
# fetch aws iam authenticator
    export ver="${AUTHENTICATOR_RELEASE#v}" && \
    export bin=/usr/local/bin/aws-iam-authenticator && \
    cd /tmp/ && curl --remote-name-all -sSLO https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${ver}/{heptio-authenticator-aws_${ver}_linux_amd64,authenticator_${ver}_checksums.txt} && \
        cat authenticator_${ver}_checksums.txt | grep "${ver}_linux_amd64" | sha256sum -c && \
        mv heptio-authenticator-aws_${ver}_linux_amd64 ${bin} && \
        chown root:root ${bin} && chmod 755 ${bin} && rm -rf /tmp/*

# Copy data
ADD ./scripts/helm /usr/local/bin/helm

RUN \
# install fixuid and create an unprivileged user (sudo enabled)
    USER=fixuid && GROUP=fixuid && \
    curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.4/fixuid-0.4-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    printf "${FIXUID_CHECKSUM}  /usr/local/bin/fixuid" | sha256sum -c && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: ${USER}\ngroup: ${GROUP}\n" > /etc/fixuid/config.yml && \
    adduser -Ds /bin/zsh fixuid && \
    echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} && \
    chmod 440 /etc/sudoers.d/${USER} && \
# init helm with plugins and install zsh
    sudo -H -u ${USER} sh -c "\
        helm init --client-only && \
        helm plugin install https://github.com/databus23/helm-diff --version master \
        curl -#SL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | bash -s && \
        zsh -c /bin/true \
    " && \
# move current user home into a "skeleton" directory
    mv /home/${USER} /home/_home-skeleton_ && mkdir /home/${USER} && chown ${USER}:${GROUP} /home/${USER}

ADD ./entrypoint.sh /
ENTRYPOINT ["/usr/local/bin/fixuid", "/entrypoint.sh"]
