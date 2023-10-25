
FROM  ubuntu:23.10
LABEL maintainer="bjr"
LABEL version="0.1.12"
LABEL description="AzDO Agent as Docker Container"
LABEL imagestatus="prod"

# To make it easier for build and release pipelines to run apt-get,
ENV DEBIAN_FRONTEND=noninteractive
ENV VENDIR_VERSION=0.35.0
ENV KLUCTL_VERSION=2.21.2
ENV TERRAFORM_VERSION=1.6.1
ENV KUBECTL_VERSION=1.26.6
ENV K8S_KUBELOGIN_VERSION=0.0.31
ENV K8S_HELMFILE_VERSION=0.156.0
ENV K8S_HELM_VERSION=3.12.2

ENV AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/3.227.2/vsts-agent-linux-x64-3.227.2.tar.gz
ENV AZP_URL=https://dev.azure.com/FeistyEric/Chickens
ENV AZP_TOKEN=6bbrgnpwwcljni3fpivke36f6qlr7zksgsxoy7g7i6at7od6jbsq

# Whenever possible, ease later changes by sorting multi-line arguments alphanumerically.
# https://github.com/docker/docker.github.io/blob/master/develop/develop-images/dockerfile_best-practices.md#sort-multi-line-arguments


# Create User and Base Install on Container

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        wget \
        git \
        gnupg \
        iputils-ping \
        jq \
        # libicu60=18.xx // libicu66=20.04 // libicu67=21.xx // libicu70=22.?
        lsb-release \
        openssh-client \
        software-properties-common \
        unzip \
        vim \
        file \
        python3-venv \
        make \
        unzip \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc \
    && rm -Rf /usr/share/man \
    && rm -Rf /var/cache/apt/* \
    && apt-get clean 

SHELL ["/bin/bash", "-xeo", "pipefail", "-c"]

# Install AZCLI 

RUN cd "$(mktemp -d)" \
	&& curl -L https://aka.ms/install-azd.sh | bash

# Install helm
RUN cd "$(mktemp -d)" \
	&& wget https://get.helm.sh/helm-v${K8S_HELM_VERSION}-linux-amd64.tar.gz \
	&& tar zxvf helm-v${K8S_HELM_VERSION}-linux-amd64.tar.gz \
	&& mv linux-amd64/helm /usr/bin \
	&& helm plugin install https://github.com/databus23/helm-diff

# Install helmfile
RUN cd "$(mktemp -d)" \
	&& 	wget https://github.com/helmfile/helmfile/releases/download/v${K8S_HELMFILE_VERSION}/helmfile_${K8S_HELMFILE_VERSION}_linux_amd64.tar.gz \
	&& 	tar zxvf helmfile_${K8S_HELMFILE_VERSION}_linux_amd64.tar.gz \
	&&  mv helmfile /usr/bin/helmfile

# Install kubectl
RUN cd "$(mktemp -d)" \
    && curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/bin/kubectl

# Install kubelogin
RUN cd "$(mktemp -d)" \
    && wget https://github.com/Azure/kubelogin/releases/download/v${K8S_KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip \
	&& unzip kubelogin-linux-amd64.zip \
	&& mv bin/linux_amd64/kubelogin /usr/bin/kubelogin

# Install powershell
RUN cd "$(mktemp -d)" \
    && curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.3.8/powershell-7.3.8-linux-x64.tar.gz \
    && mkdir -p /opt/microsoft/powershell/7 \
    && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# Install terraform
RUN cd "$(mktemp -d)" \
    && curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/bin/terraform

# Install terraspace
RUN wget https://apt.boltops.com/packages/terraspace/terraspace-latest.deb \
    && dpkg -i terraspace-latest.deb

# Install vendir
RUN cd "$(mktemp -d)" \
    && curl -s -L https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64 > /usr/bin/vendir \
    && chmod +x /usr/bin/vendir 

# Install kluctl
RUN cd "$(mktemp -d)" \
    && export kluctl_VERSION=${KLUCTL_VERSION} \
	&& curl -s https://kluctl.io/install.sh | bash

RUN cd "$(mktemp -d)" \
    && curl -LO https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew-linux_amd64.tar.gz \
    && tar zxvf krew-linux_amd64.tar.gz \
    &&  ./krew-linux_amd64 install krew 
    # && kubectl krew update \
    # && kubectl krew install kc ns ctx
    
RUN cd "$(mktemp -d)" \
    && curl -LO https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz \
    && tar zxvf k9s_Linux_amd64.tar.gz \
    && mv k9s /usr/bin
    
RUN cd "$(mktemp -d)" \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# Set the Working Directory
WORKDIR /azdo
COPY azdo_agent.sh ./
RUN wget https://vstsagentpackage.azureedge.net/agent/3.227.2/vsts-agent-linux-x64-3.227.2.tar.gz \
# Add the AzDO Agent User 
RUN groupadd --system --gid 1001 azdoagent \
    &&  useradd --system --gid 1001 --comment "Azure DevOps Agent User" --uid 1001 --home-dir /azdo  --shell /usr/sbin/nologin azdoagent \
    &&  chown -R azdoagent:azdoagent /azdo && chmod 755 /azdo \
    &&  chmod +x azdo_agent.sh

# Change to AzDO Agent User
USER azdoagent

# Start the AzDO Agent Script
CMD ["./azdo_agent.sh"]
