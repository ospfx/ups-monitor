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
