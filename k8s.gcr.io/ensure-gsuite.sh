#!/usr/bin/env bash
#
# Copyright 2019 The Kubernetes Authors.
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

# This script creates & configures the project that governs access to GSuite
# APIs.

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
. "${SCRIPT_DIR}/lib.sh"

function usage() {
    echo "usage: $0" > /dev/stderr
    echo > /dev/stderr
}

if [ $# != 0 ]; then
    usage
    exit 1
fi

# The GCP project name.
PROJECT="k8s-gsuite"

# The service account name in $PROJECT.
GSUITE_SVCACCT="gsuite-groups-manager"

# A user ID inside the GSuite who has enough power to set domain-wide
# delegation.
GSUITE_USER="wg-k8s-infra-api@kubernetes.io"


color 6 "Ensuring project exists: ${PROJECT}"
ensure_project "${PROJECT}"

color 6 "Configuring billing: ${PROJECT}"
ensure_billing "${PROJECT}"

# Enable GSuite APIs
color 6 "Enabling the GSuite admin API"
enable_api "${PROJECT}" admin.googleapis.com

color 6 "Enabling the GSuite groups API"
enable_api "${PROJECT}" groupssettings.googleapis.com

# Create a service account for gsuite to grant access to.
color 6 "Creating service account for ${GSUITE_SVCACCT}"
ensure_service_account \
    "${PROJECT}" \
    "${GSUITE_SVCACCT}" \
    "Grants access to the googlegroups API in kubernetes.io GSuite"

# Grant project owner for now because I have no idea exactly which specific
# permissions are needed, and the UI is really not helping.
color 6 "Empowering ${GSUITE_USER}"
gcloud projects add-iam-policy-binding "${PROJECT}" \
    --member "user:${GSUITE_USER}" \
    --role roles/owner

color 4 -n "The service account "
color 6 -n "${GSUITE_SVCACCT}"
color 4 " has been created"
color 4 -n "in project "
color 6 -n "${PROJECT}"
color 4 " ."
color 4 "For it to be granted GSuite access, a human must log in to the"
color 4 -n "cloud console as "
color 6 -n "${GSUITE_USER}"
color 4 " and:"
color 4 "  1: enable domain-wide delegation on that service account"
color 4 "  2: download the JSON key and give it to GSuite"
echo
color 4 "Press enter to acknowledge"
read -s

color 6 "Done"
