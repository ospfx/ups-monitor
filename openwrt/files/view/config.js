'use strict';
'require view';

return view.extend({
	render: function() {
		const params = new URLSearchParams(window.location.search || '');
		params.set('embed', '1');
		// 移除任何现有的 hash
		params.delete('hash');
		const query = '?' + params.toString();

		return E('div', {
			'style': 'height: calc(100vh - 150px); margin: -16px;'
		}, [
			E('iframe', {
				'src': '/ups/' + query,
				'onload': function(e) {
					// iframe 加载完成后，向其中注入导航命令
					try {
						const iframe = e.target;
						iframe.contentWindow.location.hash = '#/config';
					} catch(err) {
						console.error('Failed to navigate iframe:', err);
					}
				},
				'style': 'width: 100%; height: 100%; border: 0; display: block; background: #0f172a;'
			})
		]);
	},

	handleSave: null,
	handleSaveApply: null,
	handleReset: null
});
