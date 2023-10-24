# FROM xscntrlregprod.azurecr.io/ims/base/ubuntu:20.04
FROM  ubuntu:22.04
LABEL maintainer="sita-sgs-ims"
LABEL version="0.1.0"
LABEL description="AzDO Agent as Docker Container - Digtal Twin"
LABEL imagestatus="testing"

# To make it easier for build and release pipelines to run apt-get,
ENV DEBIAN_FRONTEND=noninteractive
ENV VENDIR_VERSION=0.33.1
ENV KLUCTL_VERSION=2.21.2
ENV TERRAFORM_VERSION=1.6.1
ENV KUBECTL_VERSION=1.26.6

# Whenever possible, ease later changes by sorting multi-line arguments alphanumerically.
# https://github.com/docker/docker.github.io/blob/master/develop/develop-images/dockerfile_best-practices.md#sort-multi-line-arguments

# hadolint ignore=DL3008 was set to ignore the rule to pin versions as I want to let the pipeline scan for vuln automatically
# moreover from a breaking changing perspective, it is not worth controlling versions for the components within the azdo agents
# it will be more productive to work reactively instead, if ever needed

# Create User and Base Install on Container
# hadolint ignore=DL3008 
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        curl \
        git \
        gnupg \
        iputils-ping \
        jq \
        libcurl4 \
        libicu70 \
        # libicu60=18.xx // libicu66=20.04 // libicu67=21.xx // libicu70=22.??
        libssl1.0 \
        libunwind8 \
        lsb-release \
        netcat \
        openssh-client \
        software-properties-common \
        unzip \
        vim \
        file \
        python3-venv \
        make \
        openjdk-17-jre \
        wget \
    && add-apt-repository ppa:rmescandon/yq -y \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        yq \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc \
    && rm -Rf /usr/share/man \
    && rm -Rf /var/cache/apt/* \
    && apt-get clean 

SHELL ["/bin/bash", "-xeo", "pipefail", "-c"]
# DL4006 - Set the SHELL option -o pipefail before RUN with a pipe in
# Since there are some shells that do not accept the -o pipefail option, it is not enough to add set -o pipefail inside the RUN instruction.
# https://emmer.dev/blog/reducing-docker-layers/

# Install AZCLI 
# hadolint ignore=DL3008
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
    && AZ_REPO=$(lsb_release -cs) \
    && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends azure-cli \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install helm
# hadolint ignore=DL3008
RUN curl https://baltocdn.com/helm/signing.asc |  apt-key add - \
    && echo "deb https://baltocdn.com/helm/stable/debian/ all main" |  tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends helm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install helmfile
# hadolint ignore=DL3008
RUN curl -Ls "https://github.com/helmfile/helmfile/releases/download/v0.155.0/helmfile_0.155.0_linux_amd64.tar.gz" -o "helmfile.tar.gz" \
    && mkdir helmfile \
    && tar -xf helmfile.tar.gz -C helmfile \
    && mv helmfile/helmfile /usr/bin \
    && rm -r helmfile

# Install terraspace
# hadolint ignore=DL3008
RUN curl -s https://apt.boltops.com/boltops-key.public | apt-key add - \
    && echo "deb https://apt.boltops.com stable main" > /etc/apt/sources.list.d/boltops.list \
    && apt-get update \
    && apt-get install -y terraspace \ 
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install graphviz
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y graphviz \ 
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install kubelogin
# hadolint ignore=DL3008
RUN curl -Ls "https://github.com/Azure/kubelogin/releases/download/v0.0.28/kubelogin-linux-amd64.zip" -o "kubelogin.zip" \
    && unzip kubelogin.zip \
    && mv bin/linux_amd64/kubelogin /usr/bin \
    && rm kubelogin.zip

# Install powershell
# hadolint ignore DL3008
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell

RUN cd "$(mktemp -d)" \
    && curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

RUN cd "$(mktemp -d)" \
    && curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/terraform

RUN cd "$(mktemp -d)" \
    && curl -s -L https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64 > /usr/local/bin/vendir \
    && chmod +x /usr/local/bin/vendir \
    && vendir version

RUN cd "$(mktemp -d)" \
    && export kluctl_VERSION=${KLUCTL_VERSION} \
	&& curl -s https://kluctl.io/install.sh | bash

# Set the Working Directory
WORKDIR /azp
COPY lin_azdo_agent.sh ./

# Add the AzDO Agent User 
RUN groupadd --system --gid 1001 azdoagent \
    &&  useradd --system --gid 1001 --comment "Azure DevOps Agent User" --uid 1001 --home-dir /azp  --shell /usr/sbin/nologin azdoagent \
    &&  chown -R azdoagent:azdoagent /azp && chmod 755 /azp \
    &&  chmod +x lin_azdo_agent.sh

# Change to AzDO Agent User
USER azdoagent

# Start the AzDO Agent Script
CMD ["./lin_azdo_agent.sh"]
