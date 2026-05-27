#!/bin/bash

cd "$(dirname "${BASH_SOURCE[0]}")"

# Disable Gatekeeper assessments before the rest of the kiosk setup so unsigned
# creative coding apps can launch on fresh installs.
sudo spctl --master-disable || sudo spctl --global-disable

# Keep kiosk setup discoverable under the script name used by current issue
# tracking while preserving the existing .osx setup entry point.
./.osx
