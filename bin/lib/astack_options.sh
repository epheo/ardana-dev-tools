# -*- sh -*-
#
# (c) Copyright 2016-2017 Hewlett Packard Enterprise Development LP
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
# Source multiple times to reset variables. If a project-stack
# job defines a astack-options file, then we re-source this, resetting
# all the option variables that control astack.sh
#

OPTIONS=help,run-tests,ci,no-setup,no-build,no-git-update,build-hlinux-ova,rhel,rhel-compute,rhel-compute-nodes:,sles,sles-deployer,sles-control,sles-control-nodes:,sles-compute,sles-compute-nodes:,guest-images,tarball:,cobble-nodes:,cobble-hlinux-control,cobble-hlinux-compute,cobble-hlinux-nodes:,cobble-rhel-compute,cobble-rhel-nodes:,cobble-sles-control,cobble-sles-compute,cobble-sles-nodes:,cobble-all-nodes,no-config,no-site,skip-extra-playbooks,disable-services:,update-only,project-stack:,feature-dir:,no-prepare,restrict-by-project:,squashkit:,extra-vars:
TEMP=$(getopt -o -h -l $OPTIONS -n $SCRIPT_NAME -- "$@")
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

# Are you running in CI and should do extra steps
export CI=${CI:-}

NO_SETUP=
NO_BUILD=
BUILD_HLINUX_OVA=
export ARDANA_UPGRADE_NO_HLINUX=${ARDANA_UPGRADE_NO_HLINUX:-}
export ARDANA_HLINUX_ARTIFACTS=${ARDANA_HLINUX_ARTIFACTS:-}
export ARDANA_HLINUX_CONTROL=${ARDANA_HLINUX_CONTROL:-}
export ARDANA_HLINUX_CONTROL_NODES=${ARDANA_HLINUX_CONTROL_NODES:-}
export ARDANA_HLINUX_COMPUTE=${ARDANA_HLINUX_COMPUTE:-}
export ARDANA_HLINUX_COMPUTE_NODES=${ARDANA_HLINUX_COMPUTE_NODES:-}
export ARDANA_UPGRADE_NO_RHEL=${ARDANA_UPGRADE_NO_RHEL:-}
export ARDANA_RHEL_ARTIFACTS=${ARDANA_RHEL_ARTIFACTS:-}
export ARDANA_RHEL_COMPUTE=${ARDANA_RHEL_COMPUTE:-}
export ARDANA_RHEL_COMPUTE_NODES=${ARDANA_RHEL_COMPUTE_NODES:-}
export ARDANA_UPGRADE_NO_SLES=${ARDANA_UPGRADE_NO_SLES:-}
export ARDANA_SLES_ARTIFACTS=${ARDANA_SLES_ARTIFACTS:-}
export ARDANA_SLES_CONTROL=${ARDANA_SLES_CONTROL:-}
export ARDANA_SLES_CONTROL_NODES=${ARDANA_SLES_CONTROL_NODES:-}
export ARDANA_SLES_COMPUTE=${ARDANA_SLES_COMPUTE:-}
export ARDANA_SLES_COMPUTE_NODES=${ARDANA_SLES_COMPUTE_NODES:-}
export ARDANA_GUEST_IMAGE_ARTIFACTS=${ARDANA_GUEST_IMAGE_ARTIFACTS:-}
export ARDANA_DISABLE_SERVICES=${ARDANA_DISABLE_SERVICES:-}
export ARDANA_GIT_UPDATE=${ARDANA_GIT_UPDATE:-}
export EXTRA_VARS=${EXTRA_VARS:-}
# By default don't run the extra playbooks that we run during CI
# Override this if we declare that we in the CI system with --ci
SKIP_EXTRA_PLAYBOOKS=--skip-extra-playbooks
DEPLOYER_TARBALL=
# Nodes to re-image with cobbler
COBBLER_NODES=
COBBLER_HLINUX_NODES=
COBBLER_RHEL_NODES=
COBBLER_SLES_NODES=
COBBLER_HLINUX_CONTROL=
COBBLER_HLINUX_COMPUTE=
COBBLER_RHEL_COMPUTE=
COBBLER_SLES_CONTROL=
COBBLER_SLES_COMPUTE=
COBBLER_ALL_NODES=
COBBLER_ENABLED=
NO_CONFIG=
NO_SITE=
UPDATE_ONLY=
USE_PROJECT_STACK=
SQUASH_KIT=
FEATURE_DIRS=
FEATURE_PREPARE=1
RUN_TESTS=

# Total system memory rounded up to nearest multiple of 8GB
TOTMEM_GB=$(awk '/^MemTotal:/ {gb_in_k=(1024*1024);tot_gb=int(($2+(8*gb_in_k)-1)/(8*gb_in_k))*8; print tot_gb}' /proc/meminfo)
BLDVM_MB=$(( (TOTMEM_GB / 4) * 1024 ))

while true ; do
    case "$1" in
        -h | --help) usage ; exit 0 ;;
        --run-tests) RUN_TESTS=1 ; shift ;;
        --ci)
            SKIP_EXTRA_PLAYBOOKS=
            export ARDANAUSER=ardanauser
            export CI=yes
            export ARDANA_BUILD_MEMORY=${ARDANA_BUILD_MEMORY:-${BLDVM_MB}}
            # Since there could be up to 3 build VMs, only overcommit
            # system CPU resources by at most 50%
            export ARDANA_BUILD_CPU=$(( $(nproc) / 2 ))
            shift ;;
        --no-setup) NO_SETUP=1 ; shift ;;
        --no-build) NO_BUILD=1 ; shift ;;
        --no-git-update) export ARDANA_GIT_UPDATE=no ; shift ;;
        --build-hlinux-ova) export BUILD_HLINUX_OVA=1 ; shift ;;
        --hlinux)
            export ARDANA_HLINUX_ARTIFACTS=1
            shift ;;
        --hlinux-deployer|--hlinux-control)
            export ARDANA_HLINUX_CONTROL=1
            shift ;;
        --hlinux-control-nodes)
            ARDANA_HLINUX_CONTROL_NODES="${ARDANA_HLINUX_CONTROL_NODES:+${ARDANA_HLINUX_CONTROL_NODES}:}$2"
            shift 2 ;;
        --hlinux-compute)
            export ARDANA_HLINUX_COMPUTE=1
            shift ;;
        --hlinux-compute-nodes)
            ARDANA_HLINUX_COMPUTE_NODES="${ARDANA_HLINUX_COMPUTE_NODES:+${ARDANA_HLINUX_COMPUTE_NODES}:}$2"
            shift 2 ;;
        --rhel) export ARDANA_RHEL_ARTIFACTS=1 ; shift ;;
        --rhel-compute)
            export ARDANA_RHEL_COMPUTE=1
            shift ;;
        --rhel-compute-nodes)
            ARDANA_RHEL_COMPUTE_NODES="${ARDANA_RHEL_COMPUTE_NODES:+${ARDANA_RHEL_COMPUTE_NODES}:}$2"
            shift 2 ;;
        --sles) export ARDANA_SLES_ARTIFACTS=1 ; shift ;;
        --sles-deployer|--sles-control)
            export ARDANA_SLES_CONTROL=1
            shift ;;
        --sles-control-nodes)
            ARDANA_SLES_CONTROL_NODES="${ARDANA_SLES_CONTROL_NODES:+${ARDANA_SLES_CONTROL_NODES}:}$2"
            shift 2 ;;
        --sles-compute)
            export ARDANA_SLES_COMPUTE=1
            shift ;;
        --sles-compute-nodes)
            ARDANA_SLES_COMPUTE_NODES="${ARDANA_SLES_COMPUTE_NODES:+${ARDANA_SLES_COMPUTE_NODES}:}$2"
            shift 2 ;;
        --guest-images) export ARDANA_GUEST_IMAGE_ARTIFACTS=1 ; shift ;;
        --tarball)
            export DEPLOYER_TARBALL=$2
            shift 2 ;;
        --cobble-nodes)
            COBBLER_NODES="${COBBLER_NODES:+${COBBLER_NODES}:}$2"
            shift 2 ;;
        --cobble-hlinux-nodes)
            COBBLER_HLINUX_NODES="${COBBLER_HLINUX_NODES:+${COBBLER_HLINUX_NODES}:}$2"
            shift 2 ;;
        --cobble-rhel-nodes)
            COBBLER_RHEL_NODES="${COBBLER_RHEL_NODES:+${COBBLER_RHEL_NODES}:}$2"
            shift 2 ;;
        --cobble-sles-nodes)
            COBBLER_SLES_NODES="${COBBLER_SLES_NODES:+${COBBLER_SLES_NODES}:}$2"
            shift 2 ;;
        --cobble-hlinux-control) COBBLER_HLINUX_CONTROL=1 ; shift ;;
        --cobble-hlinux-compute) COBBLER_HLINUX_COMPUTE=1 ; shift ;;
        --cobble-rhel-compute) COBBLER_RHEL_COMPUTE=1 ; shift ;;
        --cobble-sles-control) COBBLER_SLES_CONTROL=1 ; shift ;;
        --cobble-sles-compute) COBBLER_SLES_COMPUTE=1 ; shift ;;
        --cobble-all-nodes) COBBLER_ALL_NODES=1 ; shift ;;
        --disable-services)
            ARDANA_DISABLE_SERVICES="${ARDANA_DISABLE_SERVICES}${ARDANA_DISABLE_SERVICES:+' '}$2"
            shift 2 ;;
        --no-config)
            # If we don't run config processor then we shouldn't run site.yml either
            NO_CONFIG=1
            NO_SITE=1
            shift ;;
        --no-site) NO_SITE=1 ; shift ;;
        --skip-extra-playbooks) SKIP_EXTRA_PLAYBOOKS=--skip-extra-playbooks ; shift ;;
        --update-only) UPDATE_ONLY=1 ; shift ;;
        --project-stack)
            USE_PROJECT_STACK=$2
            shift 2 ;;
        --feature-dir)
            FEATURE_DIRS="$FEATURE_DIRS $2"
            shift 2 ;;
        --no-prepare) FEATURE_PREPARE= ; shift ;;
        --restrict-by-project) ZUUL_PROJECT=$2 ; shift 2 ;;
        --squashkit) SQUASH_KIT=$2 ; shift 2 ;;
        --extra-vars)
            export EXTRA_VARS=$2
            shift 2 ;;
        --) shift ; break;;
        *) break ;;
    esac
done

# Select default control plane and compute distros  if none selected
if [ -z "${ARDANA_SLES_CONTROL:-}" -a \
     -z "${ARDANA_SLES_CONTROL_NODES:-}" -a \
     -z "${ARDANA_HLINUX_CONTROL:-}" -a \
     -z "${ARDANA_HLINUX_CONTROL_NODES:-}" ]; then
    export ARDANA_SLES_CONTROL=1
fi
if [ -z "${ARDANA_SLES_COMPUTE:-}" -a \
     -z "${ARDANA_SLES_COMPUTE_NODES:-}" -a \
     -z "${ARDANA_HLINUX_COMPUTE:-}" -a \
     -z "${ARDANA_HLINUX_COMPUTE_NODES:-}" -a \
     -z "${ARDANA_RHEL_COMPUTE:-}" -a \
     -z "${ARDANA_RHEL_COMPUTE_NODES:-}" ]; then
    export ARDANA_SLES_COMPUTE=1
fi

# If a distro has been selected for control plane, compute or cobbler
# usage then we will need to build the required artifacts for it.
if [ -n "${ARDANA_HLINUX_CONTROL:-}" -o \
     -n "${ARDANA_HLINUX_COMPUTE:-}" -o \
     -n "${ARDANA_HLINUX_CONTROL_NODES:-}" -o \
     -n "${ARDANA_HLINUX_COMPUTE_NODES:-}" -o \
     -n "${COBBLER_HLINUX_CONTROL:-}" -o \
     -n "${COBBLER_HLINUX_COMPUTE:-}" -o \
     -n "${COBBLER_HLINUX_NODES:-}" ]; then
    export ARDANA_HLINUX_ARTIFACTS=1
fi
if [ -n "${ARDANA_SLES_CONTROL:-}" -o \
     -n "${ARDANA_SLES_COMPUTE:-}" -o \
     -n "${ARDANA_SLES_CONTROL_NODES:-}" -o \
     -n "${ARDANA_SLES_COMPUTE_NODES:-}" -o \
     -n "${COBBLER_SLES_CONTROL:-}" -o \
     -n "${COBBLER_SLES_COMPUTE:-}" -o \
     -n "${COBBLER_SLES_NODES:-}" ]; then
    export ARDANA_SLES_ARTIFACTS=1
fi
if [ -n "${ARDANA_RHEL_COMPUTE:-}" -o \
     -n "${ARDANA_RHEL_COMPUTE_NODES:-}" -o \
     -n "${COBBLER_RHEL_COMPUTE:-}" -o \
     -n "${COBBLER_RHEL_NODES:-}" ]; then
    export ARDANA_RHEL_ARTIFACTS=1
fi

# Will we be cobbling any nodes
if [ -n "${COBBLER_NODES:-}" -a \
     -n "${COBBLER_ALL_NODES}" ]; then
     COBBLER_ENABLED=1
fi

# vim:shiftwidth=4:tabstop=4:expandtab
