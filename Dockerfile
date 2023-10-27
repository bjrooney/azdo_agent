
FROM  ubuntu:22.04
LABEL maintainer="Hyperion"
LABEL version="0.1.12"
LABEL description="AzDO Agent as Docker Container"
LABEL imagestatus="prod"

# To make it easier for build and release pipelines to run apt-get,
ENV DEBIAN_FRONTEND=noninteractive
ENV VENDIR_VERSION=0.35.0
ENV KLUCTL_VERSION=2.21.2
ENV TERRAFORM_VERSION=1.6.2
ENV KUBECTL_VERSION=1.26.6
ENV KUBELOGIN_VERSION=0.0.32
ENV HELMFILE_VERSION=0.158.0
ENV HELM_VERSION=3.13.1
ENV PWSH_VERSION=7.3.8
ENV TERRASPACE_VERSION=latest
ENV AZCLI_VERSION=1.4.0
ENV K9S_VERSION=0.27.4
ENV YQ_VERSION=yq_linux_amd64
ENV YQ_BINARY=4.35.2


# Whenever possible, ease later changes by sorting multi-line arguments alphanumerically.
# https://github.com/docker/docker.github.io/blob/master/develop/develop-images/dockerfile_best-practices.md#sort-multi-line-arguments


# Create User and Base Install on Container

RUN apt update \
    && apt install -y --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    wget \
    git \
    gnupg \
    iputils-ping \
    jq \
    lsb-release \
    unzip \
    vim \
    file \
    python3-venv \
    make \
    unzip
 

SHELL ["/bin/bash", "-xeo", "pipefail", "-c"]

# Install AZCLI 

RUN cd "$(mktemp -d)" \
    && mkdir -p /etc/apt/keyrings \
    && curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/microsoft.gpg \
    && AZ_DIST=$(lsb_release -cs) \
    && echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" | tee /etc/apt/sources.list.d/azure-cli.list \
    && apt update \
    && apt install azure-cli -y \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc \
    && rm -Rf /usr/share/man \
    && rm -Rf /var/cache/apt/* \
    && apt-get clean

# Install yq
RUN cd "$(mktemp -d)" \
    && wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz -O - | tar xz && mv ${YQ_BINARY} /usr/bin/yq

# Install helm
RUN cd "$(mktemp -d)" \
    && wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz -O - | tar xz && mv linux-amd64/helm /usr/bin  \
    && helm plugin install https://github.com/databus23/helm-diff

# Install helmfile
RUN cd "$(mktemp -d)" \
    && 	wget https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz -O - | tar xz && mv helmfile /usr/bin/helmfile

# Install kubectl
RUN cd "$(mktemp -d)" \
    && curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/bin/kubectl

# Install kubelogin
RUN cd "$(mktemp -d)" \
    && wget https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip  -O - | unzip && mv bin/linux_amd64/kubelogin /usr/bin/kubelogin

# Install powershell
RUN cd "$(mktemp -d)"
RUN wget https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-x64.tar.gz 
RUN tar zxvf powershell-${PWSH_VERSION}-linux-x64.tar.gz -C /usr/bin 
RUN chmod +x /usr/bin/pwsh 

# Install terraform
RUN cd "$(mktemp -d)" \
    && curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/bin/terraform

# Install terraspace
RUN wget https://apt.boltops.com/packages/terraspace/terraspace-${TERRASPACE_VERSION}.deb \
    && dpkg -i terraspace-${TERRASPACE_VERSION}.deb

# Install vendir
RUN cd "$(mktemp -d)" \
    && curl -s -L https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64 > /usr/bin/vendir \
    && chmod +x /usr/bin/vendir 

# Install kluctl
RUN cd "$(mktemp -d)" \
    && curl -s https://kluctl.io/install.sh | bash

# Install krew
# RUN cd "$(mktemp -d)" \
#     && curl -LO https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew-linux_amd64.tar.gz \
#     && tar zxvf krew-linux_amd64.tar.gz \
#     &&  ./krew-linux_amd64 install krew 
# && kubectl krew update \
# && kubectl krew install kc ns ctx

# Install k9s
RUN cd "$(mktemp -d)" \
    && curl -LO https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz \
    && tar zxvf k9s_Linux_amd64.tar.gz -C /usr/bin

# Install aws cli
RUN cd "$(mktemp -d)" \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# Set the Working Directory
WORKDIR /azdo

ENV AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/3.227.2/vsts-agent-linux-x64-3.227.2.tar.gz
ENV AZP_URL=https://https://sita-pse.visualstudio.com/
ENV AZP_TOKEN=4hdrmqzfeb4pj2cnlzjsx3whaeahbvm6kqjcdzo6dszc2apkrs6q
ENV AZP_POOL="Hyperion-Dev"

# Add the AzDO Agent User 
RUN groupadd    --system --gid 1001 azdoagent \
    &&  useradd --system --gid 1001 --comment "Azure DevOps Agent User" --uid 1001 --home-dir /azdo  --shell /usr/sbin/nologin azdoagent \
    &&  chown -R azdoagent:azdoagent /azdo \
    &&  chmod 755 /azdo 

# Change to AzDO Agent User
USER azdoagent

RUN cd "$(mktemp -d)" \
    && wget ${AZP_AGENTPACKAGE_URL} \
    && tar zxvf vsts-agent-linux-x64-3.227.2.tar.gz -C /azdo \
    && cd /azdo \
    && ./config.sh --unattended \
        --agent "${AZP_AGENT_NAME:-$(hostname)}" \
        --url "${AZP_URL}" \
        --auth PAT \
        --token "${AZP_TOKEN}" \
        --pool "${AZP_POOL}" \
        --work "${AZP_WORK:-_work}" \
        --replace \
        --acceptTeeEula & wait $!

# Start the AzDO Agent Script
RUN chmod +x run-docker.sh
CMD ["./run-docker.sh"]
