#!/bin/bash
set -euo pipefail

if [ -z "${AZP_URL:-}" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "${AZP_TOKEN_FILE:-}" ]; then
  if [ -z "${AZP_TOKEN:-}" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE="/azp/.token"
  chmod 0600 "${AZP_TOKEN_FILE}" 2>/dev/null || true
  echo -n "${AZP_TOKEN}" > "${AZP_TOKEN_FILE}"
  chmod 0600 "${AZP_TOKEN_FILE}"
fi

unset AZP_TOKEN

if [ -n "${AZP_WORK:-}" ]; then
  mkdir -p "${AZP_WORK}"
fi

cleanup() {
  trap "" EXIT

  if [ -e ./config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    # If the agent has some running jobs, the configuration removal process will fail.
    # Retry for up to 5 minutes (10 x 30s) before giving up.
    local retries=0
    while [ $retries -lt 10 ]; do
      ./config.sh remove --unattended --auth "PAT" --token "$(cat "${AZP_TOKEN_FILE}")" && break
      retries=$((retries + 1))
      echo "Retrying in 30 seconds... (attempt ${retries}/10)"
      sleep 30
    done

    if [ $retries -eq 10 ]; then
      echo 1>&2 "warning: agent deregistration timed out after 10 attempts"
    fi
  fi
}

print_header() {
  lightcyan="\033[1;36m"
  nocolor="\033[0m"
  echo -e "\n${lightcyan}$1${nocolor}\n"
}

# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE="AZP_TOKEN,AZP_TOKEN_FILE"

if [ -f "./run.sh" ]; then
  print_header "1. Azure Pipelines agent already present (pre-baked in image) — skipping download."
else
  print_header "1. Determining matching Azure Pipelines agent..."

  AZP_AGENT_PACKAGES=$(curl -fLsS \
      -u "user:$(cat "${AZP_TOKEN_FILE}")" \
      -H "Accept:application/json;" \
      "${AZP_URL}/_apis/distributedtask/packages/agent?platform=${TARGETARCH:?TARGETARCH is not set}&top=1")

  AZP_AGENT_PACKAGE_LATEST_URL=$(echo "${AZP_AGENT_PACKAGES}" | jq -r ".value[0].downloadUrl")

  if [ -z "${AZP_AGENT_PACKAGE_LATEST_URL}" ] || [ "${AZP_AGENT_PACKAGE_LATEST_URL}" = "null" ]; then
    echo 1>&2 "error: could not determine a matching Azure Pipelines agent"
    echo 1>&2 "check that account ${AZP_URL} is correct and the token is valid for that account"
    exit 1
  fi

  print_header "2. Downloading and extracting Azure Pipelines agent..."

  curl -fLsS "${AZP_AGENT_PACKAGE_LATEST_URL}" | tar -xz & wait $!
fi

source ./env.sh

trap "cleanup; exit 0" EXIT
trap "cleanup; exit 130" INT
trap "cleanup; exit 143" TERM

print_header "3. Configuring Azure Pipelines agent..."

./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "${AZP_URL}" \
  --auth "PAT" \
  --token "$(cat "${AZP_TOKEN_FILE}")" \
  --pool "${AZP_POOL:-Default}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula & wait $!

print_header "4. Running Azure Pipelines agent..."

chmod +x ./run.sh

# To be aware of TERM and INT signals call ./run.sh
# Running it with the --once flag at the end will shut down the agent after the build is executed
./run.sh "$@" & wait $!
