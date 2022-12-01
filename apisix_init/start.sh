#!/bin/bash

# log file path
log_file="/usr/local/apisix/init/log/init.log"
# upstream.json file path
upstream_data_file="/usr/local/apisix/upstream/upstream.json"
# routes.json file path
routes_data_file="/usr/local/apisix/routes/routes.json"
# cert file path
cert_path="/usr/local/apisix/cert/"

# Replace with your cert file name TODO
cert_file_name=""
# Replace with your key file name TODO
key_file_name=""
# Replace with your snis TODO
snis='["*.example.com", "example.com"]'

# config in ./apisix_conf/config.yaml -> deployment: admin: admin_key
ADMIN_API_KEY="edd1c9f034335f136f87ad84b625c8f1"

ADMIN_HTTP_HEADER="X-API-KEY: ${ADMIN_API_KEY}"
JSON_HTTP_HEADER="Content-Type: application/json"

CREATE_CERT_URL="http://apisix:9180/apisix/admin/ssls/"
CREATE_ROUTE_URL="http://apisix:9180/apisix/admin/routes/"
CREATE_UPSTREAM_URL="http://apisix:9180/apisix/admin/upstreams/"

_log() {
  DATE=$(date +'%Y-%m-%d %H:%M:%S')
  echo "${DATE} $0 [$1] $2" >> ${log_file}
}

log_info() {
  _log INFO "$1"
}

log_error() {
  _log ERROR "$1"
}

init() {

  # wait for apisix server started
  sleep 20s
  if [ -n "${cert_file_name}" ] && [ -n "${key_file_name}" ]; then
    load_cert
  fi
  init_upstream
  init_routes

}

# 读取upstream.json文件，调用apisix admin api初始化upstream信息
init_upstream() {

  log_info "init_upstream start..."

  total_cnt=$(jq '.|length' ${upstream_data_file})

  success_cnt=0
  failure_cnt=0
  declare -a failure_upstreams=()

  jq -c -r '.[]' ${upstream_data_file} > /tmp/$$.list
  
  while read row
  do
    upstream_id=$(echo "${row}" | jq -r '.id')
    url=${CREATE_UPSTREAM_URL}${upstream_id}

    retry_times=0
    while [ ${retry_times} -lt 60 ]; do
      status_code=$(curl -L -o /dev/null --connect-timeout 5 -s -w "%{http_code}" --location --request PUT "${url}" \
                            --header "${ADMIN_HTTP_HEADER}" \
                            --header "${JSON_HTTP_HEADER}" \
                            --data  "${row}")
      
      if [ "${status_code}" == 000 ] ; then
        (( ${retry_times++} ))
      elif [ "${status_code}" -ge 200 ] && [ "${status_code}" -lt 300 ]; then
        (( success_cnt++ ))
        log_info "Create upstream success: ${row} ."
      else
        (( failure_cnt++ ))
        failure_upstreams+=("${row}")
        log_error "Create upstream failed with code $status_code ： ${row} ."
      fi
    done

  done < /tmp/$$.list

  log_info "Init upstreams finished. total count ${total_cnt}, success count ${success_cnt}, failure count ${failure_cnt}"
  if [ ${#failure_upstreams[@]} -gt 0 ]; then
      for upstream_info in "${failure_upstreams[@]}"
      do
        log_info "${upstream_info}"
      done
  fi
}

# 读取routes.json文件，调用apisix admin api初始化路由信息
init_routes() {

  log_info "init_routes start..."

  total_cnt=$(jq '.|length' ${routes_data_file})

  success_cnt=0 failure_cnt=0
  declare -a failure_routes=()

  jq -c -r '.[]' ${routes_data_file} > /tmp/$$.list
  while read row
  do
    route_id=$(echo "${row}" | jq -r '.id')
    url=${CREATE_ROUTE_URL}${route_id}

    retry_times=0
    while [ ${retry_times} -lt 60 ]; do
      status_code=$(curl -L -o /dev/null --connect-timeout 5 -s -w "%{http_code}" --location --request PUT "${url}" \
                               --header "${ADMIN_HTTP_HEADER}" \
                               --header "${JSON_HTTP_HEADER}" \
                               --data  "${row}")

      if [ "${status_code}" == 000 ] ; then
        (( ${retry_times++} ))
      elif [ "${status_code}" -ge 200 ] && [ "${status_code}" -lt 300 ]; then
        (( success_cnt++ ))
        log_info "Create route success: ${row} ."
      else
        (( failure_cnt++ ))
        failure_routes+=("${row}")
        log_error "Create route failed with code $status_code ： ${row} ."
      fi
    done
  done < /tmp/$$.list

  log_info "Init routes finished. total count ${total_cnt}, success count ${success_cnt}, failure count ${failure_cnt}"
  if [ ${#failure_routes[@]} -gt 0 ]; then
    for route_info in "${failure_routes[@]}"
    do
      log_info "${route_info}"
    done
    exit 1
  fi
}

# 调用apisix admin api初始化证书信息
load_cert() {

  log_info "load_cert start..."

  cert_id="1"
  cert=$(cat "${cert_path}${cert_file_name}")
  key=$(cat "${cert_path}${key_file_name}")

  url=${CREATE_CERT_URL}${cert_id}
  request_body=$(echo '{}' | jq -c '{cert: $cert, key: $key, snis: $snis}' --arg cert "$cert" --arg key "$key" --argjson snis "$snis")

  retry_times=0
  while [ "${retry_times}" -le 60 ]; do
    status_code=$(curl -L -o /dev/null --connect-timeout 5 -s -w "%{http_code}" --location --request PUT "${url}" \
                     --header "${ADMIN_HTTP_HEADER}" \
                     --header "${JSON_HTTP_HEADER}" \
                     --data  "$request_body")
    # code 000 always means that the connection has not established yet, retry to wait for apisix server started.
    if [ "${status_code}" == 000 ]; then
      log_error "curl apisix admin endpoint failed with code 000."
      sleep 1s
      (( retry_times++ ))
    elif [ "${status_code}" -ge 200 ] && [ "${status_code}" -lt 300 ]; then
      log_info "update certificate success."
      break
    else
      log_error "update certificate failed with $status_code"
      exit 1
    fi
  done
}

init
