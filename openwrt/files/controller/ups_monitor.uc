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

return { action_data, get_data };

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

return { action_data, action_commands, action_run_command, get_data, get_commands, run_command };
