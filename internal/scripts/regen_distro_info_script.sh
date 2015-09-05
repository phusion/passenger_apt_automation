#!/bin/bash
set -ex
exec erb internal/lib/distro_info.sh.erb > internal/lib/distro_info.sh
