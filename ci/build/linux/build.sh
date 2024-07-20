#!/usr/bin/env bash

set -eux

flutter_distributor release --name release --jobs linux-deb,linux-rpm
