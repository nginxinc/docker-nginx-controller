#!/bin/sh
#
# This script launches nginx and the NGINX Controller Agent.
#
# If several instances use the same imagename, the metrics will
# be aggregated into a single object in Controller. Otherwise NGINX Controller
# will create separate objects for monitoring (an object per instance).

# Variables
agent_conf_file="/etc/controller-agent/agent.conf"
agent_log_file="/var/log/nginx-controller/agent.log"
nginx_status_conf="/etc/nginx/conf.d/stub_status.conf"
api_key=""
controller_hostname=""
controller_url=""
location=""

# Launch nginx
echo "starting nginx ..."
nginx -g "daemon off;" &

nginx_pid=$!

test -n "${ENV_API_KEY}" && \
    api_key=${ENV_API_KEY}

# if controller_hostname is defined in the env vars, use it
test -n "${ENV_CONTROLLER_HOSTNAME}" && \
    controller_hostname=${ENV_CONTROLLER_HOSTNAME}

# if controller_hostname is not defined in the env vars, fail back to hostname
test -z "${controller_hostname}" && \
    controller_hostname=$(hostname -f)

test -n "${ENV_CONTROLLER_URL}" && \
    controller_url=${ENV_CONTROLLER_URL}

test -n "${ENV_LOCATION}" && \
    location=${ENV_LOCATION}

if [ -n "${api_key}" -o -n "${controller_hostname}" -o -n "${controller_url}" -o -n "${location}" ]; then
    echo "updating ${agent_conf_file} ..."

    if [ ! -f "${agent_conf_file}" ]; then
	test -f "${agent_conf_file}.default" && \
	cp -p "${agent_conf_file}.default" "${agent_conf_file}" || \
	{ echo "no ${agent_conf_file}.default found! exiting."; exit 1; }
    fi

    test -n "${api_key}" && \
    echo " ---> using api_key = ${api_key}" && \
    sh -c "sed -i.old -e 's/api_key.*$/api_key = $api_key/' \
	${agent_conf_file}"

    test -n "${controller_hostname}" && \
    echo " ---> using hostname = ${controller_hostname}" && \
    sh -c "sed -i.old -e 's/instance_name.*$/instance_name = $controller_hostname/' \
	${agent_conf_file}"
    
    test -n "${controller_url}" && \
    echo " ---> using controller = ${controller_url}" && \
    sh -c "sed -i.old -e 's@api_url.*@api_url = $controller_url@' \
	${agent_conf_file}"

    test -n "${location}" && \
    echo " ---> using location = ${location}" && \
    sh -c "sed -i.old -e 's/location_name.*$/location_name = $location/' \
	${agent_conf_file}"

    test -f "${agent_conf_file}" && \
    chmod 644 ${agent_conf_file} && \
    chown nginx ${agent_conf_file} > /dev/null 2>&1

    test -f "${nginx_status_conf}" && \
    chmod 644 ${nginx_status_conf} && \
    chown nginx ${nginx_status_conf} > /dev/null 2>&1
fi

if ! grep '^api_key.*=[ ]*[[:alnum:]].*' ${agent_conf_file} > /dev/null 2>&1; then
    echo "no api_key found in ${agent_conf_file}! exiting."
fi

echo "starting controller-agent ..."
service controller-agent start > /dev/null 2>&1 < /dev/null

if [ $? != 0 ]; then
    echo "couldn't start the agent, please check ${agent_log_file}"
    exit 1
fi

wait ${nginx_pid}

echo "nginx master process has stopped, exiting."
