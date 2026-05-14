#!/bin/bash
set -e

nginx
exec docker-entrypoint.sh postgres