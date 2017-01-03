#!/bin/sh

BLACK="\033[0;30m"
DARK_GRAY="\033[1;30m"
RED="\033[0;31m"
LIGHT_RED="\033[1;31m"
GREEN="\033[0;32m"
LIGHT_GREEN="\033[1;32m"
BROWN="\033[33m"
YELLOW="\033[1;33m"
BLUE="\033[ 0;34m"
LIGHT_BLUE="\033[1;34m"
PURPLE="\033[0;35m"
LIGHT_PURPLE="\033[;35m"
CYAN="\033[0;36m"
LIGHT_CYAN="\033[ 1;36m"
LIGHT_GRAY="\033[0;37m"
WHITE="\033[1;37m"
NC="\033[0m"

USAGE="Usage: load-blueprint.sh <private_key> <blueprint_name> <ambari-server>"
fail() {
  echo "\n${RED}Error: ${NC}$1"
  exit 1
}

warn() {
  echo "\n${YELLOW}Warning: ${NC}$@"
}

status() {
  echo "\n${GREEN}$@${NC}"
}

if [[ $# -ne 3 ]]; then
  echo $USAGE
  fail "Expected three arguments"
fi

# Start: Resolve Script Directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "${SOURCE}" ]; do # resolve $SOURCE until the file is no longer a symlink
   bin="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
   SOURCE="$(readlink "${SOURCE}")"
   [[ "${SOURCE}" != /* ]] && SOURCE="${bin}/${SOURCE}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
bin="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
script=$( basename "${SOURCE}" )
# Stop: Resolve Script Directory

pk=$1
shift

blueprint_name=$1
shift

ambari_server=$1
shift

# I keep forgetting to change the hosts in cluster.json, so let's add a quick check to make sure that ping
# can reach them. A bit tied to the schema of Ambari's blueprints -- hopefully that doesn't change.
status 'Checking cluster.json file'
cluster_json_hosts=$(${bin}/extract_hosts.rb ${bin}/${blueprint_name}/cluster.json)
exit_code=$?

if [[ ${exit_code} -ne 0 ]]; then
  # I want to catch this when it fails, but, do I want it to fail? Maybe only a warning.
  fail "Could not parse cluster.json file to determine if hosts are reachable (exit code=${exit_code})"
else
  while read cluster_json_line; do
    printf "Checking ${cluster_json_line}... "
    ping -c 2 -q "$cluster_json_line" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
      echo "Failed."
      fail "'${cluster_json_line}' is not reachable by ping, is ${bin}/${blueprint_name}/clusters.json correct?"
    fi
    echo "Good!"
  done <<< "${cluster_json_hosts}"
fi

# TODO check response code in curl output

status "Loading blueprint"
curl --user admin:admin -H 'X-Requested-By: ambari' -X POST http://$ambari_server:8080/api/v1/blueprints/hadoop -d @${bin}/${blueprint_name}/blueprint.json || fail "Failed to put blueprint."

status "Loading cluster"
curl --user admin:admin -H 'X-Requested-By: ambari' -X POST http://$ambari_server:8080/api/v1/clusters/hadoop -d @${bin}/${blueprint_name}/cluster.json || fail "Failed to put cluster."

status "Done!"
