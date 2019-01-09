FROM python:3.6-alpine

ARG version
LABEL com.stackfeed.k8s-ops.vendor=StackFeed \
      com.stackfeed.k8s-ops.version=${version}

# List of plugins to enable in ZSH and theme
ENV ZSH_PLUGINS="aws helm kops kubectl terraform" \
    ZSH_THEME=cloud \
    HELM_BINARY=/usr/local/bin/helm-binary \
    HELM_FORCE_TLS=no

# Tooling versions
ENV \
    KUBECTL_SOURCE=kubernetes-release/release \
    KUBECTL_TRACK=stable.txt \
    TF_VERSION=0.11.11 \
    TG_RELEASE=v0.17.4 \
    KOPS_VERSION=1.11.0 \
    HELM_RELEASE=v2.12.1 \
    HELMFILE_RELEASE=v0.41.0 \
    ARK_RELEASE=v0.9.10 \
    AUTHENTICATOR_RELEASE=v0.3.0 \
    FIXUID_RELEASE=v0.4 \
    FIXUID_CHECKSUM=e901f3b21e62ebed92172df969bfc6cbfdfa8f53afb060f20f25e77dcbc20ff5 \
    SOPS_VERSION=3.2.0 \
    SOPS_CHECKSUM=fec5b5b5bbae922a829a6277f6d66a061d990c04132da3c82db32ccc309a22e7


# Additional packages for the toolbox
RUN apk add --no-cache zsh bash curl sudo coreutils findutils jq fping make git \
        sed nano vim openssl openssh-client iptables gnupg

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
    ver="${AUTHENTICATOR_RELEASE#v}" && \
    bin=/usr/local/bin/aws-iam-authenticator && \
    cd /tmp/ && curl --remote-name-all -sSLO https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${ver}/{heptio-authenticator-aws_${ver}_linux_amd64,authenticator_${ver}_checksums.txt} && \
        cat authenticator_${ver}_checksums.txt | grep "${ver}_linux_amd64" | sha256sum -c && \
        mv heptio-authenticator-aws_${ver}_linux_amd64 ${bin} && \
        chown root:root ${bin} && chmod 755 ${bin} && rm -rf /tmp/* && \
# install sops
    ver="${SOPS_RELEASE#v}" && \
    bin=/usr/local/bin/sops && \
    curl --remote-name-all -sSL https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux \
        -o ${bin} && printf "${SOPS_CHECKSUM}  ${bin}" | sha256sum -c && chown root:root ${bin} && chmod 755 ${bin}


# Copy data
ADD ./scripts/helm /usr/local/bin/helm

RUN cd /tmp && \
# install fixuid and create an unprivileged user (sudo enabled)
    USER=fixuid && GROUP=fixuid && ver=${FIXUID_RELEASE#v} && \
    curl -sSL https://github.com/boxboat/fixuid/releases/download/${FIXUID_RELEASE}/fixuid-${ver}-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
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
        helm init --client-only; \
        helm plugin install https://github.com/databus23/helm-diff --version master; \
        helm plugin install https://github.com/futuresimple/helm-secrets --version master; \
        curl -#SL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | bash -s; \
    " && \
# move current user home into a "skeleton" directory
    mv /home/${USER} /home/_home-skeleton_ && mkdir /home/${USER} && chown ${USER}:${GROUP} /home/${USER} && \
# cleanup
    rm -rf /tmp/*

ADD ./entrypoint.sh /
ENTRYPOINT ["/usr/local/bin/fixuid", "/entrypoint.sh"]
