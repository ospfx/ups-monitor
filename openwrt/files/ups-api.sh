#!/bin/sh
# UPS Monitor - NUT API Gateway
# Returns JSON formatted UPS status data

echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# Parse UPS name from query string (default: ups)
UPS_NAME="${QUERY_STRING:-ups}"

# Query UPS data via upsc
get_value() {
	upsc "$UPS_NAME" "$1" 2>/dev/null || echo "${2:-0}"
}

# Get all values
BATTERY_CHARGE=$(get_value "battery.charge")
BATTERY_RUNTIME=$(get_value "battery.runtime")
BATTERY_VOLTAGE=$(get_value "battery.voltage")
BATTERY_TEMP=$(get_value "battery.temperature")
INPUT_VOLTAGE=$(get_value "input.voltage" "220")
INPUT_FREQ=$(get_value "input.frequency" "50")
OUTPUT_VOLTAGE=$(get_value "output.voltage" "220")
OUTPUT_FREQ=$(get_value "output.frequency" "50")
OUTPUT_LOAD=$(get_value "ups.load")
UPS_STATUS=$(get_value "ups.status" "OL")
DEVICE_MFR=$(get_value "device.mfr" "Unknown")
DEVICE_MODEL=$(get_value "device.model" "Unknown")
DEVICE_SERIAL=$(get_value "device.serial")

# Convert NUT status to frontend format
case "$UPS_STATUS" in
	*OL*) STATUS="online" ;;
	*OB*) STATUS="onbatt" ;;
	*OFF*) STATUS="offline" ;;
	*) STATUS="unknown" ;;
esac

# Calculate power (W) from load percentage
POWER=$((OUTPUT_LOAD * 12))

# Output JSON
cat << JSON
{
  "name": "$UPS_NAME",
  "status": "$STATUS",
  "battery": {
    "charge": ${BATTERY_CHARGE},
    "runtime": ${BATTERY_RUNTIME},
    "voltage": ${BATTERY_VOLTAGE}${BATTERY_TEMP:+,
    "temperature": ${BATTERY_TEMP}}
  },
  "input": {
    "voltage": ${INPUT_VOLTAGE},
    "frequency": ${INPUT_FREQ}
  },
  "output": {
    "voltage": ${OUTPUT_VOLTAGE},
    "frequency": ${OUTPUT_FREQ},
    "load": ${OUTPUT_LOAD},
    "power": ${POWER}
  },
  "device": {
    "manufacturer": "$DEVICE_MFR",
    "model": "$DEVICE_MODEL"${DEVICE_SERIAL:+,
    "serial": "$DEVICE_SERIAL"},
    "type": "ups"
  },
  "lastUpdate": $(date +%s)000
}
JSON
