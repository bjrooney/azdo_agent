
# NOTE: This Dockerfile is a reference/fallback only.
# It does NOT verify SHA256 checksums for downloaded binaries and is NOT suitable for production.
# Use the melange + apko pipeline (build-apko.sh) for production builds.

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:918a593b8268c222afd4e2c4f06860ac984e60719b4697e4c71d796bc8fcd042

ARG MELANGE_VERSION=0.45.3-r1
ARG AZCLI_VERSION=~2.84.0

RUN apk update \
    && apk upgrade \
    && apk add --no-cache ncurses coreutils bash curl git icu-libs jq yq unzip make openssh \
        "melange=${MELANGE_VERSION}" \
        "az=${AZCLI_VERSION}" \
    && az version

ENV TARGETARCH="linux-musl-x64"
ENV MELANGE_VERSION=${MELANGE_VERSION}

ENV VENDIR_VERSION=0.45.2
ENV KLUCTL_VERSION=2.27.0
ENV TERRAFORM_VERSION=1.14.7
ENV KUBECTL_VERSION=1.35.2
ENV KUBELOGIN_VERSION=0.2.16

# Install kubectl
RUN cd "$(mktemp -d)" \
    && curl -fsSLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/bin/kubectl \
    && kubectl version --client

# Install kubelogin
RUN cd "$(mktemp -d)" \
    && curl -fsSLO "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" \
    && unzip kubelogin-linux-amd64.zip \
    && mv bin/linux_amd64/kubelogin /usr/bin/kubelogin \
    && kubelogin --version

# Install terraform
RUN cd "$(mktemp -d)" \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/bin/terraform \
    && terraform version --version

# Install vendir
RUN cd "$(mktemp -d)" \
    && curl -fsSL "https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/vendir-linux-amd64" > /usr/bin/vendir \
    && chmod +x /usr/bin/vendir \
    && vendir --version

# Install kluctl
RUN cd "$(mktemp -d)" \
    && curl --retry 5 --retry-delay 2 --retry-all-errors -fsSL -o kluctl.tar.gz "https://github.com/kluctl/kluctl/releases/download/v${KLUCTL_VERSION}/kluctl_v${KLUCTL_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf kluctl.tar.gz \
    && mv kluctl /usr/bin/kluctl \
    && chmod +x /usr/bin/kluctl \
    && kluctl version

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod +x ./start.sh \
    && adduser -D agent \
    && chown agent:agent ./start.sh \
    && chmod 1777 /tmp \
    && chown -R agent:agent /tmp
USER agent
# Another option is to run the agent as root.
ENV AGENT_ALLOW_RUNASROOT="false"

ENTRYPOINT ["./start.sh"]