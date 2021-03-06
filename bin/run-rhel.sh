#!/bin/bash
#
# (c) Copyright 2016 Hewlett Packard Enterprise Development LP
# (c) Copyright 2017 SUSE LLC
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Called in CI
#

set -eu
set -o pipefail

eval "$($(dirname "$(readlink -e "${BASH_SOURCE[0]}")")/ardana-env)"

SCRIPT_NAME=$(basename $0)
SCRIPT_HOME=$(cd $(dirname $0) ; pwd)

export PYTHONUNBUFFERED=1

usage() {
    set +x
    echo "$SCRIPT_NAME [--ci] [cloud]"
    echo
}

TEMP=$(getopt -o -h -l help,ci,no-setup,no-build,no-site -n $SCRIPT_NAME -- "$@")
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

args=

while true ; do
    case "$1" in
        -h | --help) usage ; exit 0 ;;
        --ci)
            args="$args --ci"
            shift ;;
        --no-setup|--no-build|--no-site) args="$args $1" ; shift ;;
        --) shift ; break ;;
        *) break ;;
    esac
done

set -x

echo "Enabling RHEL for all compute nodes"

$SCRIPT_HOME/astack.sh $args --rhel --rhel-compute $*
