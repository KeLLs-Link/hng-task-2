#!/bin/sh
set -eu

NGINX_URL="${NGINX_URL:-http://localhost:8080/version}"
BLUE_CHAOS_START="${BLUE_CHAOS_START:-http://localhost:8081/chaos/start?mode=error}"
BLUE_CHAOS_STOP="${BLUE_CHAOS_STOP:-http://localhost:8081/chaos/stop}"

echo "Baseline check -- expect ACTIVE_POOL from .env (blue by default)"
hdr=$(curl -sI "$NGINX_URL" | tr -d '\r' | awk '/^X-App-Pool:/ {print $2; exit}' || true)
echo "X-App-Pool: ${hdr:-<missing>}"
if [ -z "$hdr" ]; then
  echo "FAIL: no X-App-Pool header"
  exit 1
fi

# Start chaos on blue
echo "Triggering chaos on blue: $BLUE_CHAOS_START"
curl -s -X POST "$BLUE_CHAOS_START" || true

# Query for ~10 seconds
end=$(( $(date +%s) + 10 ))
total=0
non200=0
green_count=0
while [ $(date +%s) -lt $end ]; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$NGINX_URL" || echo "000")
  pool=$(curl -sI "$NGINX_URL" | tr -d '\r' | awk '/^X-App-Pool:/ {print $2; exit}' || echo "")
  total=$((total+1))
  if [ "$status" != "200" ]; then
    non200=$((non200+1))
  else
    if echo "$pool" | grep -iq "green"; then
      green_count=$((green_count+1))
    fi
  fi
  sleep 0.25
done

echo "Results: total=$total non200=$non200 green=$green_count"
# Stop chaos
curl -s -X POST "$BLUE_CHAOS_STOP" || true

if [ "$non200" -ne 0 ]; then
  echo "FAIL: got $non200 non-200 responses"
  exit 2
fi

perc=$(awk "BEGIN{if ($total==0) print 0; else print ($green_count/$total)*100}")
echo "Green % = $perc"
awk "BEGIN{exit !($perc >= 95)}"
echo "PASS: failover OK"
exit 0
