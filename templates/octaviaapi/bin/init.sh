#!/bin//bash
#
# Copyright 2020 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
set -ex

# This script generates the octavia.conf/logging.conf file and
# copies the result to the ephemeral /var/lib/config-data/merged volume.
#
# Secrets are obtained from ENV variables.
export PASSWORD=${AdminPassword:?"Please specify a AdminPassword variable."}
export DBHOST=${DatabaseHost:?"Please specify a DatabaseHost variable."}
export DBUSER=${DatabaseUser:?"Please specify a DatabaseUser variable."}
export DBPASSWORD=${DatabasePassword:?"Please specify a DatabasePassword variable."}
export DB=${DatabaseName:-"octavia"}
export TRANSPORTURL=${TransportURL:-""}

SVC_CFG=/etc/octavia/octavia.conf
SVC_CFG_MERGED=/var/lib/config-data/merged/octavia.conf

# expect that the common.sh is in the same dir as the calling script
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. ${SCRIPTPATH}/common.sh --source-only

# Copy default service config from container image as base
cp -a ${SVC_CFG} ${SVC_CFG_MERGED}

# Merge all templates from config CM
for dir in /var/lib/config-data/default; do
    merge_config_dir ${dir}
done

# set secrets
if [ -n "$TRANSPORTURL" ]; then
    crudini --set /var/lib/config-data/merged/octavia.conf DEFAULT transport_url $TRANSPORTURL
fi
# set secrets
crudini --set ${SVC_CFG_MERGED} database connection mysql+pymysql://${DBUSER}:${DBPASSWORD}@${DBHOST}/${DB}
crudini --set ${SVC_CFG_MERGED} keystone_authtoken password $PASSWORD
crudini --set ${SVC_CFG_MERGED} service_auth password $PASSWORD
