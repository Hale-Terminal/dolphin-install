#!/usr/bin/env bash
set -e

COMPOSE_DOCKER_CLI_BUILD=0

MIN_DOCKER_VERSION='17.05.0'
MIN_COMPOSE_VERSION='1.19.0'
MIN_RAM=2400 # MB

DOLPHIN_CONFIG_ENV='./.env'
DOLPHIN_EXTRA_REQUIREMENTS='./requirements.txt'

COMPOSE_BUILD_ARGS="$(grep -E '^(VUE_APP)' ${DOLPHIN_CONFIG_ENV} | while read var ; do printf %b "--build-arg ${var} "; done)"
trap cleanup ERR INT TERM
echo "Checking minimum requirements..."
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
COMPOSE_VERSION=$(docker-compose --version | grep -o "[0-9]\{1,2\}\.[0-9]\{1,2\}\.[0-9]\{1,2\}")
RAM_AVAILABLE_IN_DOCKER=$(docker run --rm busybox free -m 2>/dev/null | awk '/Mem/ {print $2}');
# Compare dot-separated strings - function below is inspired by https://stackoverflow.com/a/37939589/808368
function ver () { echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }'; }
function ensure_file_from_example {
  if [ -f "$1" ]; then
    echo "$1 already exists, skipped creation."
  else
    echo "Creating $1..."
    cp -n $(echo "$1".example) "$1"
  fi
}
# Handle OSX sed
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed_suffix_arg="-i ''"
else
    sed_suffix_arg="-i"
fi
function fill_uninitialised_secret {
    secret_name=$1
    if [ -z ${!secret_name} ] || [ ${!secret_name} == "REPLACEWITHSOMETHIINGSECRET" ]; then
        echo "Generating ${secret_name}..."
    else
        echo "Leaving existing ${secret_name}..."
    fi
}
if [ $(ver $DOCKER_VERSION) -lt $(ver $MIN_DOCKER_VERSION) ]; then
    echo "FAIL: Expected minimum Docker version to be $MIN_DOCKER_VERSION but found $DOCKER_VERSION"
    exit -1
fi
if [ $(ver $COMPOSE_VERSION) -lt $(ver $MIN_COMPOSE_VERSION) ]; then
    echo "FAIL: Expected minimum docker-compose version to be $MIN_COMPOSE_VERSION but found $COMPOSE_VERSION"
    exit -1
fi
if [ "$RAM_AVAILABLE_IN_DOCKER" -lt "$MIN_RAM" ]; then
    echo "FAIL: Expected minimum RAM available to Docker to be $MIN_RAM MB but found $RAM_AVAILABLE_IN_DOCKER MB"
    exit -1
fi
echo ""
ensure_file_from_example $DOLPHIN_CONFIG_ENV
ensure_file_from_example $DOLPHIN_EXTRA_REQUIREMENTS
source $DOLPHIN_CONFIG_ENV
# Clean up old stuff and ensure nothing is working while we install/update
docker-compose down --rmi local --remove-orphans
echo ""
echo "Pulling, building, and tagging Docker images..."
echo ""
docker-compose build ${COMPOSE_BUILD_ARGS} --force-rm
echo ""
echo "Docker images pulled and built."
# Very naively check whether there's an existing dispatch-postgres volume and the PG version in it
echo ""
echo ""
echo ""
echo ""
echo "----------------"
echo "You're all done! Run the following command to get Dolphin running:"
echo ""
echo "  docker-compose up -d"
echo ""
echo "Once running, access the Documentation at:"
echo ""
echo "  http://localhost:8000/docs"
echo ""
echo "----------------"
echo ""