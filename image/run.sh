#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function launchmaster() {
  if [[ ! -e /redis-master-data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /redis-master-data
  fi
  perl -pi -e "s/%password%/${REDIS_PASSWORD}/" /redis-master/redis.conf
  redis-server /redis-master/redis.conf
}

function launchsentinel() {
  while true; do
    master=$(redis-cli -h ${SENTINEL_HOST} -p ${SENTINEL_PORT} --csv SENTINEL get-master-addr-by-name ${CLUSTER_NAME} | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      master=$(hostname -i)
    fi

    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done

  sentinel_conf=sentinel.conf

  echo "sentinel monitor ${CLUSTER_NAME} ${master} 6379 2" > ${sentinel_conf}
  echo "sentinel auth-pass ${CLUSTER_NAME} ${REDIS_PASSWORD}" >> ${sentinel_conf}
  echo "sentinel down-after-milliseconds ${CLUSTER_NAME} 6000" >> ${sentinel_conf}
  echo "sentinel failover-timeout ${CLUSTER_NAME} 12000" >> ${sentinel_conf}
  echo "sentinel parallel-syncs ${CLUSTER_NAME} 1" >> ${sentinel_conf}

  cp ${sentinel_conf} ${sentinel_conf}.initial

  redis-sentinel ${sentinel_conf}
}

function launchslave() {
  while true; do
    master=$(redis-cli -h ${SENTINEL_HOST} -p ${SENTINEL_PORT} --csv SENTINEL get-master-addr-by-name ${CLUSTER_NAME} | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      echo "Failed to find master."
      sleep 60
      exit 1
    fi 
    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done
  perl -pi -e "s/%master-ip%/${master}/" /redis-slave/redis.conf
  perl -pi -e "s/%master-port%/6379/" /redis-slave/redis.conf
  perl -pi -e "s/%password%/${REDIS_PASSWORD}/" /redis-slave/redis.conf
  redis-server /redis-slave/redis.conf
}

if [[ "${MASTER}" == "true" ]]; then
  launchmaster
  exit 0
fi

if [[ "${SENTINEL}" == "true" ]]; then
  launchsentinel
  exit 0
fi

launchslave
