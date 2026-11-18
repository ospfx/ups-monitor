'use strict';

import * as fs from 'fs';

const DEFAULT_UPS = 'ups';

function upsc(name, key) {
	let handle = fs.popen(sprintf('/usr/bin/upsc %s %s 2>/dev/null', name, key));

	if (!handle)
		return '';

	let value = handle.read('all');
	handle.close();

	return trim(value ?? '');
}

function num(value, fallback) {
	if (!match(value ?? '', /^-?[0-9]+(\.[0-9]+)?$/))
		return fallback;

	return +value;
}

function normalize_name(name) {
	return match(name ?? '', /^[A-Za-z0-9_.-]+$/) ? name : DEFAULT_UPS;
}

function get_data(name) {
	name = normalize_name(name);

	let status_text = ' ' + upsc(name, 'ups.status') + ' ';
	let status = 'unknown';

	if (match(status_text, / OL /))
		status = 'online';
	else if (match(status_text, / OB /))
		status = 'onbatt';
	else if (match(status_text, / OFF /))
		status = 'offline';

	let load = num(upsc(name, 'ups.load'), 0);
	let realpower = num(upsc(name, 'ups.realpower'), 0);
	let nominal = num(upsc(name, 'ups.realpower.nominal'), 0);
	let power = 0;

	if (realpower > 0)
		power = int(realpower);
	else if (nominal > 0)
		power = int(nominal * load / 100);

	let input_voltage = num(upsc(name, 'input.voltage'), 0);
	let input_frequency = num(upsc(name, 'input.frequency'), 0);
	let temperature = upsc(name, 'battery.temperature');

	let battery = {
		charge: num(upsc(name, 'battery.charge'), 0),
		runtime: num(upsc(name, 'battery.runtime'), 0),
		voltage: num(upsc(name, 'battery.voltage'), 0)
	};

	if (length(temperature))
		battery.temperature = num(temperature, 0);

	return {
		name: name,
		status: status,
		battery: battery,
		input: {
			voltage: input_voltage,
			frequency: input_frequency
		},
		output: {
			voltage: num(upsc(name, 'output.voltage'), input_voltage),
			frequency: num(upsc(name, 'output.frequency'), input_frequency),
			load: load,
			power: power
		},
		device: {
			manufacturer: upsc(name, 'device.mfr'),
			model: upsc(name, 'device.model'),
			serial: upsc(name, 'device.serial'),
			type: 'ups'
		},
		lastUpdate: time() * 1000
	};
}

function action_data() {
	let query = http.getenv('QUERY_STRING') ?? '';
	let name = DEFAULT_UPS;

	for (let part in split(query, '&')) {
		let pair = split(part, '=');

		if (pair[0] == 'ups' && length(pair[1])) {
			name = pair[1];
			break;
		}
	}

	http.prepare_content('application/json; charset=UTF-8');
	http.write_json(get_data(name));
}


function get_commands(name) {
	name = normalize_name(name);
	
	let handle = fs.popen(sprintf('/usr/bin/upscmd -l %s 2>/dev/null', name));
	
	if (!handle)
		return [];
	
	let output = handle.read('all');
	handle.close();
	
	if (!output)
		return [];
	
	let commands = [];
	let lines = split(output, '\n');
	let in_list = false;
	
	for (let line in lines) {
		line = trim(line);
		
		if (match(line, /^Instant commands supported/)) {
			in_list = true;
			continue;
		}
		
		if (!in_list || !length(line))
			continue;
		
		let parts = split(line, ' - ');
		if (length(parts) >= 2) {
			push(commands, {
				name: trim(parts[0]),
				description: trim(parts[1])
			});
		}
	}
	
	return commands;
}

function run_command(name, command) {
	name = normalize_name(name);
	
	if (!match(command ?? '', /^[a-zA-Z0-9._-]+$/))
		return { success: false, error: 'Invalid command name' };
	
	let handle = fs.popen(sprintf('/usr/bin/upscmd -u admin -p admin %s %s 2>&1', name, command));
	
	if (!handle)
		return { success: false, error: 'Failed to execute command' };
	
	let output = handle.read('all');
	let exit_code = handle.close();
	
	if (exit_code == 0)
		return { success: true, message: trim(output) };
	else
		return { success: false, error: trim(output) };
}

function action_commands() {
	let query = http.getenv('QUERY_STRING') ?? '';
	let name = DEFAULT_UPS;
	
	for (let part in split(query, '&')) {
		let pair = split(part, '=');
		
		if (pair[0] == 'ups' && length(pair[1])) {
			name = pair[1];
			break;
		}
	}
	
	http.prepare_content('application/json; charset=UTF-8');
	http.write_json({ commands: get_commands(name) });
}

function action_run_command() {
	let query = http.getenv('QUERY_STRING') ?? '';
	let name = DEFAULT_UPS;
	let command = '';
	
	for (let part in split(query, '&')) {
		let pair = split(part, '=');
		
		if (pair[0] == 'ups' && length(pair[1]))
			name = pair[1];
		else if (pair[0] == 'command' && length(pair[1]))
			command = pair[1];
	}
	
	http.prepare_content('application/json; charset=UTF-8');
	http.write_json(run_command(name, command));
}


function uci_get(config, section, option) {
	let handle = fs.popen(sprintf('uci -q get %s.%s.%s 2>/dev/null', config, section, option));
	if (!handle) return null;
	let value = handle.read('all');
	handle.close();
	return trim(value ?? '');
}

function get_config() {
	let config = {
		drivers: [],
		upsd: null,
		users: []
	};
	
	// Get driver configurations
	let handle = fs.popen('uci -q show nut_server 2>/dev/null');
	if (handle) {
		let output = handle.read('all');
		handle.close();
		
		for (let line in split(output, '\n')) {
			line = trim(line);
			if (!length(line)) continue;
			
			if (match(line, /^nut_server\..*=driver$/)) {
				let section = split(split(line, '.')[1], '=')[0];
				let driver = {
					name: section,
					enabled: uci_get('nut_server', section, 'enabled') == '1',
					driver: uci_get('nut_server', section, 'driver') || 'usbhid-ups',
					port: uci_get('nut_server', section, 'port') || 'auto',
					desc: uci_get('nut_server', section, 'desc') || ''
				};
				push(config.drivers, driver);
			}
			else if (match(line, /^nut_server\.upsd=/)) {
				config.upsd = {
					enabled: uci_get('nut_server', 'upsd', 'enabled') == '1',
					listen_address: uci_get('nut_server', 'upsd', 'listen_address') || '127.0.0.1',
					listen_port: int(uci_get('nut_server', 'upsd', 'listen_port') || '3493')
				};
			}
			else if (match(line, /^nut_server\..*=user$/)) {
				let section = split(split(line, '.')[1], '=')[0];
				let user = {
					name: section,
					password: uci_get('nut_server', section, 'password') || '',
					actions: uci_get('nut_server', section, 'actions') || '',
					instcmds: uci_get('nut_server', section, 'instcmds') || '',
					upsmon: uci_get('nut_server', section, 'upsmon') || ''
				};
				push(config.users, user);
			}
		}
	}
	
	return config;
}

function save_config(config_data) {
	// Validate input
	if (type(config_data) != 'object')
		return { success: false, error: 'Invalid configuration data' };
	
	// Save driver configuration
	if (type(config_data.drivers) == 'array') {
		for (let driver in config_data.drivers) {
			let name = driver.name || 'ups';
			
			// Create or update driver section
			system(sprintf("uci -q delete nut_server.%s 2>/dev/null; uci set nut_server.%s=driver", name, name));
			system(sprintf("uci set nut_server.%s.enabled='%s'", name, driver.enabled ? '1' : '0'));
			system(sprintf("uci set nut_server.%s.driver='%s'", name, driver.driver || 'usbhid-ups'));
			system(sprintf("uci set nut_server.%s.port='%s'", name, driver.port || 'auto'));
			system(sprintf("uci set nut_server.%s.desc='%s'", name, driver.desc || 'UPS Device'));
		}
	}
	
	// Save upsd configuration
	if (type(config_data.upsd) == 'object') {
		system("uci -q delete nut_server.upsd 2>/dev/null; uci set nut_server.upsd=upsd");
		system(sprintf("uci set nut_server.upsd.enabled='%s'", config_data.upsd.enabled ? '1' : '0'));
		system(sprintf("uci set nut_server.upsd.listen_address='%s'", config_data.upsd.listen_address || '127.0.0.1'));
		system(sprintf("uci set nut_server.upsd.listen_port='%d'", int(config_data.upsd.listen_port) || 3493));
	}
	
	// Save user configuration
	if (type(config_data.users) == 'array') {
		for (let user in config_data.users) {
			let name = user.name || 'admin';
			
			system(sprintf("uci -q delete nut_server.%s 2>/dev/null; uci set nut_server.%s=user", name, name));
			system(sprintf("uci set nut_server.%s.password='%s'", name, user.password || ''));
			
			if (length(user.actions))
				system(sprintf("uci set nut_server.%s.actions='%s'", name, user.actions));
			if (length(user.instcmds))
				system(sprintf("uci set nut_server.%s.instcmds='%s'", name, user.instcmds));
			if (length(user.upsmon))
				system(sprintf("uci set nut_server.%s.upsmon='%s'", name, user.upsmon));
		}
	}
	
	// Commit changes
	let commit_result = system('uci commit nut_server');
	if (commit_result != 0)
		return { success: false, error: 'Failed to commit UCI configuration' };
	
	// Convert UCI to NUT config files
	let convert_result = system('/usr/lib/nut/uci-to-nut.sh 2>&1');
	if (convert_result != 0)
		return { success: false, error: 'Failed to convert UCI configuration' };
	
	// Restart NUT service
	let restart_result = system('/etc/init.d/nut-server restart 2>&1');
	if (restart_result != 0)
		return { success: false, error: 'Failed to restart NUT service' };
	
	return { success: true, message: 'Configuration saved and service restarted' };
}

function detect_devices() {
	let devices = [];
	
	// Check for hidraw devices
	let handle = fs.popen('ls /dev/hidraw* 2>/dev/null');
	if (handle) {
		let output = handle.read('all');
		handle.close();
		
		for (let device in split(output, '\n')) {
			device = trim(device);
			if (!length(device)) continue;
			
			// Try to get device info
			let info_handle = fs.popen(sprintf('cat /sys/class/hidraw/%s/device/uevent 2>/dev/null', replace(device, '/dev/', '')));
			if (info_handle) {
				let info = info_handle.read('all');
				info_handle.close();
				
				let name = '';
				let vendor_id = '';
				let product_id = '';
				
				for (let line in split(info, '\n')) {
					if (match(line, /^HID_NAME=/))
						name = replace(line, 'HID_NAME=', '');
					else if (match(line, /^HID_ID=/)) {
						let parts = split(replace(line, 'HID_ID=', ''), ':');
						if (length(parts) >= 3) {
							vendor_id = parts[1];
							product_id = parts[2];
						}
					}
				}
				
				push(devices, {
					path: device,
					name: name,
					vendor_id: vendor_id,
					product_id: product_id,
					suggested_driver: 'usbhid-ups'
				});
			}
		}
	}
	
	return devices;
}

function list_drivers() {
	let drivers = [
		{ name: 'usbhid-ups', desc: 'USB HID UPS driver (most common)' },
		{ name: 'blazer_usb', desc: 'Megatec/Q1 protocol USB driver' },
		{ name: 'nutdrv_qx', desc: 'Q* protocol driver (Qx/Megatec)' },
		{ name: 'blazer_ser', desc: 'Megatec/Q1 protocol serial driver' },
		{ name: 'apcsmart', desc: 'APC Smart protocol serial driver' },
		{ name: 'bcmxcp_usb', desc: 'BCM/XCP protocol USB driver' },
		{ name: 'dummy-ups', desc: 'Dummy driver for testing' }
	];
	
	return drivers;
}

function action_get_config() {
	http.prepare_content('application/json; charset=UTF-8');
	http.write_json(get_config());
}

function action_save_config() {
	let content_type = http.getenv('CONTENT_TYPE') ?? '';
	let content_length = int(http.getenv('CONTENT_LENGTH') ?? '0');
	
	if (content_length == 0) {
		http.prepare_content('application/json; charset=UTF-8');
		http.write_json({ success: false, error: 'No configuration data provided' });
		return;
	}
	
	let body = http.content();
	let config_data = json(body);
	
	http.prepare_content('application/json; charset=UTF-8');
	http.write_json(save_config(config_data));
}

function action_detect_devices() {
	http.prepare_content('application/json; charset=UTF-8');
	http.write_json({ devices: detect_devices() });
}

function action_list_drivers() {
	http.prepare_content('application/json; charset=UTF-8');
	http.write_json({ drivers: list_drivers() });
}

return {
	action_data,
	action_commands,
	action_run_command,
	action_get_config,
	action_save_config,
	action_detect_devices,
	action_list_drivers,
	get_data,
	get_commands,
	run_command,
	get_config,
	save_config,
	detect_devices,
	list_drivers
};
