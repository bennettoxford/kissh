# Base image for running tests.
#
# We are using docker as way to test scripts designed to run inside a regular
# ubuntu VM. We could user lxd or similar instead, but docker runs OOTB in GH
# actions. So we install ubuntu-server on top of the ubuntu:20.04 image, and
# this gets us much closer to a regular VM image.
#
# Importantly, we run system as PID 1, like a regular VM. This allows our
# scripts to install and run systemd services of their own.
# 
# Note: this means we need to run this image with some specific options:
# 
#   --cap-add SYS_ADMIN \
#   --tmpfs /tmp --tmpfs /run --tmpfs /run/lock \
#   -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
#
ARG BASE=you-must-set-base-image-explictly
FROM $BASE

# we need sudo and ssh installed
RUN apt-get update && apt-get install -y sudo ssh openssh-server python3 python3-requests
