#!/bin/bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
docker compose --profile konga up -d --wait --wait-timeout 120
docker compose --profile konga ps
