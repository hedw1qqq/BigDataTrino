#!/usr/bin/env bash
set -euo pipefail

docker compose up -d

ready=0
for _ in $(seq 1 60); do
  if docker compose exec -T trino trino --execute "SELECT 1" >/dev/null 2>&1; then
    ready=1
    break
  fi

  sleep 2
done

if [ "$ready" -ne 1 ]; then
  echo "Trino did not start in 120 seconds" >&2
  exit 1
fi

docker compose exec -T trino trino --file /sql/01_build_model.sql
docker compose exec -T trino trino --file /sql/02_build_reports.sql
docker compose exec -T trino trino --file /sql/03_check_result.sql
