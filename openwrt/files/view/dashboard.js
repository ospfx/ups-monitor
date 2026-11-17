'use strict';
'require view';

return view.extend({
	render: function() {
		const query = window.location.search || '';

		return E('div', {
			'style': 'height: calc(100vh - 150px); margin: -16px;'
		}, [
			E('iframe', {
				'src': '/ups/' + query,
				'style': 'width: 100%; height: 100%; border: 0; display: block; background: #0f172a;'
			})
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
