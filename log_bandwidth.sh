#!/bin/bash
INTERFACE="wlan0"
LOG_FILE="/home/smyeni/hourly_bandwidth.log"
THRESHOLD_MIB=${1:-50}
[[ -f "$LOG_FILE" ]] || echo "Date,Hour,RX,TX,Total,Avg_Rate,Alert" > "$LOG_FILE"
TARGET_DATE=$(date -d "1 hour ago" +"%Y-%m-%d")
TARGET_HOUR=$(date -d "1 hour ago" +"%H:00")
ROW=$(vnstat -i "$INTERFACE" -h 2>/dev/null | awk -v date="$TARGET_DATE" -v hour="$TARGET_HOUR" '
    $0 ~ date { found=1 }
    found && $1 == hour { gsub(/\|/,""); print $1,$2,$3,$4,$5,$6,$7,$8,$9; exit }
')
if [[ -z "$ROW" ]]; then
    echo "$TARGET_DATE,$TARGET_HOUR,0 B,0 B,0 B,0 bit/s,OK" >> "$LOG_FILE"
    exit 0
fi
read -r HOUR RX RX_UNIT TX TX_UNIT TOTAL TOTAL_UNIT AVG_RATE RATE_UNIT <<< "$ROW"
ALERT="OK"
[[ "$TOTAL_UNIT" == "GiB" ]] && ALERT="CRITICAL_HIGH_USAGE"
[[ "$TOTAL_UNIT" == "MiB" ]] && awk "BEGIN {exit !($TOTAL >= $THRESHOLD_MIB)}" && ALERT="HIGH_USAGE"
echo "$TARGET_DATE,$HOUR,$RX $RX_UNIT,$TX $TX_UNIT,$TOTAL $TOTAL_UNIT,$AVG_RATE $RATE_UNIT,$ALERT" >> "$LOG_FILE"
