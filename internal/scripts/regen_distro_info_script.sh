#!/bin/bash
set -ex
exec erb -T - internal/lib/distro_info.sh.erb > internal/lib/distro_info.sh
