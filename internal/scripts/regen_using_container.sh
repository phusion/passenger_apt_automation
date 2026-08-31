#!/bin/bash
docker run -v "$PWD:/mnt/pwd" 'ubuntu:resolute' /mnt/pwd/internal/scripts/run-in-container.sh
