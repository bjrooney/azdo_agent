
FROM  ubuntu:lunar-20231004
LABEL maintainer="bjr"
LABEL version="0.1.12"
LABEL description="AzDO Agent as Docker Container"
LABEL imagestatus="prod"

# To make it easier for build and release pipelines to run apt-get,
ENV DEBIAN_FRONTEND=noninteractive
ENV VENDIR_VERSION=0.33.1
ENV KLUCTL_VERSION=2.21.2
ENV TERRAFORM_VERSION=1.6.1
ENV KUBECTL_VERSION=1.26.6

# Whenever possible, ease later changes by sorting multi-line arguments alphanumerically.
# https://github.com/docker/docker.github.io/blob/master/develop/develop-images/dockerfile_best-practices.md#sort-multi-line-arguments


# Create User and Base Install on Container

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
        # libicu60=18.xx // libicu66=20.04 // libicu67=21.xx // libicu70=22.?
        lsb-release \
        openssh-client \
        software-properties-common \
        unzip \
        vim \
        file \
        python3-venv \
        make \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc \
    && rm -Rf /usr/share/man \
    && rm -Rf /var/cache/apt/* \
    && apt-get clean 

SHELL ["/bin/bash", "-xeo", "pipefail", "-c"]

RUN cd "$(mktemp -d)" \
    && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    && chmod +x get_helm.sh \
    && ./get_helm.sh 


RUN cd "$(mktemp -d)" \
    && curl -LO https://github.com/kubernetes-sigs/krew/releases/download/v0.4.4/krew-linux_amd64.tar.gz \
    && tar zxvf krew-linux_amd64.tar.gz \
    &&  ./krew-linux_amd64 install krew \
    && kubectl krew update \
    && kubectl krew install kc ns ctx
    
RUN cd "$(mktemp -d)" \
    && curl -LO https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz \
    && tar zxvf k9s_Linux_amd64.tar.gz \
    && mv k9s /usr/bin
    
RUN cd "$(mktemp -d)" \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# Install helmfile


RUN curl -Ls "https://github.com/helmfile/helmfile/releases/download/v0.155.0/helmfile_0.155.0_linux_amd64.tar.gz" -o "helmfile.tar.gz" \
    && mkdir helmfile \
    && tar -xf helmfile.tar.gz -C helmfile \
    && mv helmfile/helmfile /usr/bin \
    && rm -r helmfile

# Install terraspace
RUN curl -s https://apt.boltops.com/boltops-key.public | apt-key add - \
    && echo "deb https://apt.boltops.com stable main" > /etc/apt/sources.list.d/boltops.list \
    && apt-get update \
    && apt-get install -y terraspace \ 
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install kubelogin
RUN curl -Ls "https://github.com/Azure/kubelogin/releases/download/v0.0.28/kubelogin-linux-amd64.zip" -o "kubelogin.zip" \
    && unzip kubelogin.zip \
    && mv bin/linux_amd64/kubelogin /usr/bin \
    && rm kubelogin.zip

# Install powershell
RUN wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y powershell

# Install kubectl
RUN cd "$(mktemp -d)" \
    && curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/kubectl

# Install terraform
RUN cd "$(mktemp -d)" \
    && curl "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/terraform

# Install vendir
RUN cd "$(mktemp -d)" \
    && curl -s -L https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64 > /usr/local/bin/vendir \
    && chmod +x /usr/local/bin/vendir \
    && vendir version

# Install kluctl
RUN cd "$(mktemp -d)" \
    && export kluctl_VERSION=${KLUCTL_VERSION} \
	&& curl -s https://kluctl.io/install.sh | bash

# Set the Working Directory
WORKDIR /azdo
COPY azdo_agent.sh ./

# Add the AzDO Agent User 
RUN groupadd --system --gid 1001 azdoagent \
    &&  useradd --system --gid 1001 --comment "Azure DevOps Agent User" --uid 1001 --home-dir /azdo  --shell /usr/sbin/nologin azdoagent \
    &&  chown -R azdoagent:azdoagent /azdo && chmod 755 /azdo \
    &&  chmod +x azdo_agent.sh

# Change to AzDO Agent User
USER azdoagent

# Start the AzDO Agent Script
CMD ["./azdo_agent.sh"]
