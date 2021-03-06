#!/bin/bash
#
# (c) Copyright 2015-2017 Hewlett Packard Enterprise Development LP
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
# Called by CI
#
# Parse the artifacts file and copy all listed files to location to be
# uploaded to Gozer static server by Jenkins in the ardana-artifact-publisher
#
# Relies on the following set (from jenkins environment):
#  - WORKSPACE path to the build workspace
#  - GOZER_BUILD_ID  a uniquie identifier for the build
#
# Note that Jenkins needs to be configured to copy back any artifacts from
# the same root as this script uses (the major.minor stream - e.g.
# 'ardana-0.9')
#
# E.g. the jenkins scp publisher jjb configuration should look like the
# following, and the value for {stream} must match that derived for STREAM in
# the script below.
#
# - scp:
#     site: 'server.suse.provo.cloud'
#     files:
#       - target: 'tarballs/ardana'
#         source: '{stream}/**'
#         ...
#

set -eux
set -o pipefail

eval "$($(dirname "$(readlink -e "${BASH_SOURCE[0]}")")/ardana-env)"

# Source library module.
# Note that it sets DEVTOOLS, used below.
source $(dirname $0)/libci.sh

if [ -z "${WORKSPACE:-}" ] ; then
    echo "ERROR: WORKSPACE environment variable must be set."
    exit 1
fi

BUILD_TYPE=${1:-'canary_build'}

if [ ! -e $ARTIFACTS_FILE ] ; then
    echo "ERROR: Artifacts file '$ARTIFACTS_FILE' does not exist." >&2
    exit 1
fi

if [[ -z "${GOZER_BUILD_ID:-}" ]]; then
    echo "ERROR: GOZER_BUILD_ID not set." >&2
    exit 1
fi


# Use the 'deployer' artifact version as the overall version.
VERSION=$(grep ^deployer $ARTIFACTS_FILE | tail -n1 | cut -d' ' -f3)
if [[ -z "$VERSION" ]]; then
    echo "ERROR: Failed to get deployer version." >&2
    exit 1
fi
# VERSION will be at least a major.minor.patch version spec.
# Truncate down to major.minor for the stream.
STREAM=$(cut -d. -f1,2 <<< $VERSION)

# Customise DEST for hotfix builds
if [[ ${BUILD_TYPE} = 'hotfix_build' ]]; then
    DEST=${WORKSPACE}/${STREAM}/${BUILD_TYPE}/${HOTFIX_VERSION}_${GOZER_BUILD_ID}
else
    DEST=$WORKSPACE/$STREAM/$BUILD_TYPE/$GOZER_BUILD_ID
fi

while read type branch version filename; do
    name=$(basename $filename)

    # We are generating URL from the branch so swap /'s with -'s
    branch=$(echo $branch | sed -e 's,/,-,g')

    # Organise artifacts such that
    # - All manifests go under manifests/
    # - Deployer tarball goes into the build root.
    # - All other artifacts into artifacts/
    case $name in
        *.manifest*)
            fdest=$DEST/manifests
            ;;
        $VERSION*.tar)
            deployer_tarball=$name
            fdest=$DEST
            ;;
        *.iso)
            ardana_iso=$name
            fdest=$DEST
            ;;
        *)
            fdest=$DEST/artifacts
            ;;
    esac
    echo "DEBUG: $type $branch $version $filename $name $fdest"

    mkdir -p $fdest
    cp $filename $fdest/$name
done < $ARTIFACTS_FILE

echo "ardana_iso=${ardana_iso:?Unable to determine ISO artifact name}"
echo "deployer_tarball=${deployer_tarball:?Unable to determine deployer artifact name}"
(cd $DEST && md5sum $deployer_tarball $ardana_iso > MD5SUMS)
(cd $DEST && sha256sum $deployer_tarball $ardana_iso > SHA256SUMS)
