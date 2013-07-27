#!/bin/sh

# Simply execute './run.sh' in virtualenv

set -ex

CLIENT=vagrant@192.168.33.10
SERVER=vagrant@192.168.33.11
CLIENT_PORT=10080
SERVER_PORT=8080
HTTP_SERVER_COMMAND="python -m SimpleHTTPServer ${SERVER_PORT}"
IDENITITY=$HOME/.vagrant.d/insecure_private_key
FABRIC_OPTIONS="-D -i ${IDENITITY}"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${IDENITITY}"

test_tunnel() {
	# Start a target HTTP server
	ssh ${SSH_OPTIONS} ${SERVER} "${HTTP_SERVER_COMMAND} < /dev/null > /dev/null 2> /dev/null &"
	# Test the tunnnel
	ssh ${SSH_OPTIONS} ${CLIENT} "curl http://localhost:${CLIENT_PORT}/"
	# Shutdown the target server
	ssh ${SSH_OPTIONS} ${SERVER} "pkill -f '${HTTP_SERVER_COMMAND}'"
}

# Run doctests
python -m doctest ../fabfile.py

# Bring up vms
vagrant up

# Setup a tunnel
fab ${FABRIC_OPTIONS} setup:${CLIENT},${SERVER},local_port=${CLIENT_PORT},remote_port=${SERVER_PORT}

# Test the tunnel
test_tunnel

# Reboot client
vagrant reload client

# Test that the tunnel is available even after rebooted
test_tunnel

# Shutdown vms
vagrant halt

echo "Test passed."
