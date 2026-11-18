#!/bin/sh
# UCI to NUT configuration converter
# Converts /etc/config/nut_server to NUT configuration files

set -e

UPS_CONF="/var/etc/nut/ups.conf"
UPSD_CONF="/var/etc/nut/upsd.conf"
UPSD_USERS="/var/etc/nut/upsd.users"

# Ensure directory exists
mkdir -p /var/etc/nut

# Generate ups.conf
echo "# Generated from UCI config" > "$UPS_CONF"
uci -q show nut_server | grep "^nut_server\..*=driver" | while read line; do
	section=$(echo "$line" | cut -d. -f2 | cut -d= -f1)
	enabled=$(uci -q get nut_server.$section.enabled || echo "1")
	
	[ "$enabled" = "1" ] || continue
	
	driver=$(uci -q get nut_server.$section.driver || echo "usbhid-ups")
	port=$(uci -q get nut_server.$section.port || echo "auto")
	desc=$(uci -q get nut_server.$section.desc || echo "UPS Device")
	
	echo "" >> "$UPS_CONF"
	echo "[$section]" >> "$UPS_CONF"
	echo "    driver = $driver" >> "$UPS_CONF"
	echo "    port = $port" >> "$UPS_CONF"
	echo "    desc = \"$desc\"" >> "$UPS_CONF"
	
	# Additional driver options
	uci -q show nut_server.$section | grep -v "=driver$" | grep -v "\.enabled=" | \
		grep -v "\.driver=" | grep -v "\.port=" | grep -v "\.desc=" | while read opt; do
		key=$(echo "$opt" | cut -d. -f3 | cut -d= -f1)
		val=$(echo "$opt" | cut -d= -f2- | sed "s/'//g")
		echo "    $key = $val" >> "$UPS_CONF"
	done
done

# Generate upsd.conf
echo "# Generated from UCI config" > "$UPSD_CONF"
if uci -q show nut_server | grep -q "^nut_server\.upsd="; then
	enabled=$(uci -q get nut_server.upsd.enabled || echo "1")
	
	if [ "$enabled" = "1" ]; then
		listen_addr=$(uci -q get nut_server.upsd.listen_address || echo "127.0.0.1")
		listen_port=$(uci -q get nut_server.upsd.listen_port || echo "3493")
		echo "LISTEN $listen_addr $listen_port" >> "$UPSD_CONF"
	fi
fi

# Generate upsd.users
echo "# Generated from UCI config" > "$UPSD_USERS"
uci -q show nut_server | grep "^nut_server\..*=user" | while read line; do
	section=$(echo "$line" | cut -d. -f2 | cut -d= -f1)
	
	password=$(uci -q get nut_server.$section.password || echo "")
	[ -n "$password" ] || continue
	
	echo "" >> "$UPSD_USERS"
	echo "[$section]" >> "$UPSD_USERS"
	echo "    password = $password" >> "$UPSD_USERS"
	
	actions=$(uci -q get nut_server.$section.actions || echo "")
	[ -n "$actions" ] && echo "    actions = $actions" >> "$UPSD_USERS"
	
	instcmds=$(uci -q get nut_server.$section.instcmds || echo "")
	[ -n "$instcmds" ] && echo "    instcmds = $instcmds" >> "$UPSD_USERS"
	
	upsmon=$(uci -q get nut_server.$section.upsmon || echo "")
	[ -n "$upsmon" ] && echo "    upsmon $upsmon" >> "$UPSD_USERS"
done

echo "NUT configuration files generated successfully"
