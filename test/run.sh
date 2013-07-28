#!/bin/sh

# Simply execute './run.sh' in virtualenv

set -ex

CLIENT=vagrant@192.168.33.10
SERVER=vagrant@192.168.33.11
CLIENT_PORT1=10080
SERVER_PORT1=8080
CLIENT_PORT2=10081
SERVER_PORT2=8081
HTTP_SERVER_COMMAND1="python -m SimpleHTTPServer ${SERVER_PORT1}"
HTTP_SERVER_COMMAND2="python -m SimpleHTTPServer ${SERVER_PORT2}"
IDENITITY=$HOME/.vagrant.d/insecure_private_key
FABRIC_OPTIONS="-D -i ${IDENITITY}"
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${IDENITITY}"

test_tunnel() {
	## Test local port forwarding
	# Start a target HTTP server
	ssh ${SSH_OPTIONS} ${SERVER} "${HTTP_SERVER_COMMAND1} < /dev/null > /dev/null 2> /dev/null &"
	# Wait for server to start
	sleep 1
	# Test the tunnnel
	ssh ${SSH_OPTIONS} ${CLIENT} "curl http://localhost:${CLIENT_PORT1}/"
	# Shutdown the target server
	ssh ${SSH_OPTIONS} ${SERVER} "pkill -f '${HTTP_SERVER_COMMAND1}'"

	## Test remote port forwarding
	# Start a target HTTP server
	ssh ${SSH_OPTIONS} ${CLIENT} "${HTTP_SERVER_COMMAND2} < /dev/null > /dev/null 2> /dev/null &"
	# Wait for server to start
	sleep 1
	# Test the tunnnel
	ssh ${SSH_OPTIONS} ${SERVER} "curl http://localhost:${CLIENT_PORT2}/"
	# Shutdown the target server
	ssh ${SSH_OPTIONS} ${CLIENT} "pkill -f '${HTTP_SERVER_COMMAND2}'"
}

# Run doctests
python -m doctest ../fabfile.py

# Bring up vms
vagrant up

# Setup a tunnel from client to server (local port forwarding)
fab ${FABRIC_OPTIONS} setup:${CLIENT},${SERVER},local_port=${CLIENT_PORT1},remote_port=${SERVER_PORT1}
# Setup a tunnel from server to client (remote port forwarding)
fab ${FABRIC_OPTIONS} setup:${CLIENT},${SERVER},local_port=${CLIENT_PORT2},remote_port=${SERVER_PORT2},direction=remote,service_name=autossh_remote

# Test the tunnel
test_tunnel

# Reboot client
vagrant reload client

# Test that the tunnel is available even after client is rebooted
test_tunnel

# Reboot server
vagrant reload server

# Test that the tunnel is available even after server is rebooted
test_tunnel

# Shutdown vms
vagrant halt

echo "Test passed."
