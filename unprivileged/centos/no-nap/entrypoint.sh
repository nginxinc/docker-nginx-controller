#!/bin/sh
#
# This script launches nginx and the NGINX Controller Agent.
#

# Variables
agent_conf_file="/etc/controller-agent/agent.conf"
agent_log_file="/var/log/nginx-controller/agent.log"
nginx_status_conf="/etc/nginx/conf.d/stub_status.conf"
api_key=""
instance_name="$(hostname -f)"
controller_api_url=""
location=""

handle_term()
{
    echo "received TERM signal"
    echo "stopping controller-agent ..."
    kill -TERM "${agent_pid}" 2>/dev/null
    echo "stopping nginx ..."
    kill -TERM "${nginx_pid}" 2>/dev/null
}

trap 'handle_term' TERM

# Launch nginx
echo "starting nginx ..."
nginx -g "daemon off;" &

nginx_pid=$!

wait_workers()
{
    while ! pgrep -f 'nginx: worker process' >/dev/null 2>&1; do
        echo "waiting for nginx workers ..."
        sleep 2
    done
}

wait_workers

test -n "${ENV_CONTROLLER_API_KEY}" && \
    api_key=${ENV_CONTROLLER_API_KEY}

# if instance_name is defined in the env vars, use it
test -n "${ENV_CONTROLLER_INSTANCE_NAME}" && \
    instance_name=${ENV_CONTROLLER_INSTANCE_NAME}

test -n "${ENV_CONTROLLER_API_URL}" && \
    controller_api_url=${ENV_CONTROLLER_API_URL}

test -n "${ENV_CONTROLLER_LOCATION}" && \
    location=${ENV_CONTROLLER_LOCATION}

if [ -n "${api_key}" -o -n "${instance_name}" -o -n "${controller_api_url}" -o -n "${location}" ]; then
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

    test -n "${controller_api_url}" && \
    echo " ---> using controller api url = ${controller_api_url}" && \
    sh -c "sed -i.old -e 's@^api_url.*@api_url = $controller_api_url@' \
	${agent_conf_file}"

    test -n "${instance_name}" && \
    echo " ---> using instance_name = ${instance_name}" && \
    sh -c "sed -i.old -e 's/instance_name.*$/instance_name = $instance_name/' \
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
    exit 1
fi

echo "starting controller-agent ..."
/usr/bin/nginx-controller-agent > /dev/null 2>&1 < /dev/null &

agent_pid=$!

if [ $? != 0 ]; then
    echo "couldn't start the agent, please check ${agent_log_file}"
    exit 1
fi

wait_term()
{
    wait ${agent_pid}
    trap - TERM
    kill -QUIT "${nginx_pid}" 2>/dev/null
    echo "waiting for nginx to stop..."
    wait ${nginx_pid}
}

wait_term

echo "controller-agent process has stopped, exiting."
