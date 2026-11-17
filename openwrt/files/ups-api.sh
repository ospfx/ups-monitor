#!/bin/sh
# UPS Monitor - JSON API for the NUT client (upsc)
#
# Usage: /cgi-bin/ups-api.sh[?ups=<upsname>]
# Returns the subset of NUT variables used by the dashboard.

printf 'Content-Type: application/json\r\n'
printf 'Cache-Control: no-store\r\n'
printf 'X-Content-Type-Options: nosniff\r\n'
printf '\r\n'

QUERY="${QUERY_STRING:-}"
UPS_NAME="ups"

case "$QUERY" in
	*ups=*)
		UPS_NAME="${QUERY#*ups=}"
		UPS_NAME="${UPS_NAME%%&*}"
		;;
	'')
		;;
	*)
		# Backwards compatible: a bare query string is the UPS name
		UPS_NAME="$QUERY"
		;;
esac

case "$UPS_NAME" in
	''|*[!A-Za-z0-9_.-]*)
		UPS_NAME="ups"
		;;
esac

get() {
	local_value=$(upsc "$UPS_NAME" "$1" 2>/dev/null)
	if [ -n "$local_value" ]; then
		printf '%s' "$local_value"
	else
		printf '%s' "$2"
	fi
}

json_escape() {
	printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\r\n'
}

num() {
	awk -v v="$1" -v d="$2" 'BEGIN {
		if (v ~ /^-?[0-9]+(\.[0-9]+)?$/) print v; else print d
	}'
}

CHARGE=$(get battery.charge 0)
RUNTIME=$(get battery.runtime 0)
BATT_VOLT=$(get battery.voltage 0)
BATT_TEMP=$(get battery.temperature "")
INPUT_VOLT=$(get input.voltage 0)
INPUT_FREQ=$(get input.frequency 0)
OUTPUT_VOLT=$(get output.voltage "$INPUT_VOLT")
OUTPUT_FREQ=$(get output.frequency "$INPUT_FREQ")
LOAD=$(get ups.load 0)
STATUS_RAW=$(get ups.status "")
REALPOWER=$(get ups.realpower "")
NOMINAL_POWER=$(get ups.realpower.nominal "")
MFR=$(get device.mfr "")
MODEL=$(get device.model "")
SERIAL=$(get device.serial "")

case " $STATUS_RAW " in
	*" OL "*) STATUS="online" ;;
	*" OB "*) STATUS="onbatt" ;;
	*" OFF "*) STATUS="offline" ;;
	*) STATUS="unknown" ;;
esac

POWER=$(awk -v rp="$REALPOWER" -v nom="$NOMINAL_POWER" -v l="$LOAD" 'BEGIN {
	if (rp ~ /^-?[0-9]+(\.[0-9]+)?$/ && rp + 0 > 0)
		printf "%d", rp + 0;
	else if (nom ~ /^-?[0-9]+(\.[0-9]+)?$/ && nom + 0 > 0 &&
	         l ~ /^-?[0-9]+(\.[0-9]+)?$/ && l + 0 >= 0)
		printf "%d", nom * l / 100;
	else
		print 0;
}')

TEMP_LINE=""
if [ -n "$BATT_TEMP" ]; then
	TEMP_LINE=",
    \"temperature\": $(num "$BATT_TEMP" 0)"
fi

SERIAL_LINE=""
if [ -n "$SERIAL" ]; then
	SERIAL_LINE=",
    \"serial\": \"$(json_escape "$SERIAL")\""
fi

cat <<JSON
{
  "name": "$(json_escape "$UPS_NAME")",
  "status": "$STATUS",
  "battery": {
    "charge": $(num "$CHARGE" 0),
    "runtime": $(num "$RUNTIME" 0),
    "voltage": $(num "$BATT_VOLT" 0)${TEMP_LINE}
  },
  "input": {
    "voltage": $(num "$INPUT_VOLT" 0),
    "frequency": $(num "$INPUT_FREQ" 0)
  },
  "output": {
    "voltage": $(num "$OUTPUT_VOLT" 0),
    "frequency": $(num "$OUTPUT_FREQ" 0),
    "load": $(num "$LOAD" 0),
    "power": ${POWER}
  },
  "device": {
    "manufacturer": "$(json_escape "$MFR")",
    "model": "$(json_escape "$MODEL")"${SERIAL_LINE},
    "type": "ups"
  },
  "lastUpdate": $(($(date +%s) * 1000))
}
JSON
