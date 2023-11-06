
FROM alpine

RUN apk update \
    && apk upgrade \
    && apk add --no-cache ncurses coreutils bash curl git icu-libs jq yq unzip make unzip python3  py3-pip  openssh 

ENV TARGETARCH="linux-musl-x64"

ENV VENDIR_VERSION=0.37.0
ENV KLUCTL_VERSION=2.21.2
ENV TERRAFORM_VERSION=1.6.3
ENV KUBECTL_VERSION=1.26.6
ENV KUBELOGIN_VERSION=0.0.32
ENV AZCLI_VERSION=2.53.1

# Install Azure CLI
RUN cd "$(mktemp -d)" \
    && apk add --no-cache --update --virtual=build gcc musl-dev python3-dev libffi-dev openssl-dev cargo \
    && pip3 install --no-cache-dir --prefer-binary --upgrade pip \
        azure-cli \
    && apk del build \
    && az version

# Install kubectl
RUN cd "$(mktemp -d)" \
    && curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/bin/kubectl \
    && kubectl version --client

# Install kubelogin
RUN cd "$(mktemp -d)" \
    && wget https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip \
    && unzip kubelogin-linux-amd64.zip \
    && mv bin/linux_amd64/kubelogin /usr/bin/kubelogin \
    && kubelogin --version

# Install terraform
RUN cd "$(mktemp -d)" \
    && curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/bin/terraform \
    && terraform version --version

# Install vendir
RUN cd "$(mktemp -d)" \
    && curl -s -L https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64 > /usr/bin/vendir \
    && chmod +x /usr/bin/vendir \
    && vendir --version 

# Install kluctl
RUN cd "$(mktemp -d)" \
    && curl -s https://kluctl.io/install.sh | bash \
    && kluctl version

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh \
    && adduser -D agent \
    && chown agent ./ \
    && chmod -R  777 /tmp \
    && chgrp -R agent /tmp \
    && chown -R agent /tmp
USER agent
# Another option is to run the agent as root.
ENV AGENT_ALLOW_RUNASROOT="false"

ENTRYPOINT ./start.sh