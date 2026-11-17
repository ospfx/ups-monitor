'use strict';
'require view';

return view.extend({
	render: function() {
		window.location.replace('/ups/');

		return E('div', { 'class': 'cbi-map' }, [
			E('p', {}, _('Redirecting to UPS Monitor…'))
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
