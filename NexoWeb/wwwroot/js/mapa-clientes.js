// Mapa de clientes con Leaflet.js
// CDN via tile de OpenStreetMap — solo tiles, no datos del usuario
window.nexoMapa = (() => {
    const _mapas = {};

    function init(elementId, puntos) {
        if (_mapas[elementId]) {
            _mapas[elementId].remove();
            delete _mapas[elementId];
        }

        const el = document.getElementById(elementId);
        if (!el || typeof L === 'undefined') return;

        const mapa = L.map(elementId, { zoomControl: true }).setView([4.5, -74.1], 5);
        _mapas[elementId] = mapa;

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© <a href="https://openstreetmap.org">OpenStreetMap</a>',
            maxZoom: 18
        }).addTo(mapa);

        const maxTotal = Math.max(...puntos.map(p => p.total), 1);

        puntos.forEach(p => {
            const radio = 10 + Math.round((p.total / maxTotal) * 30);
            const marcador = L.circleMarker([p.lat, p.lng], {
                radius: radio,
                fillColor: '#2563eb',
                color: '#1d4ed8',
                weight: 2,
                opacity: 0.9,
                fillOpacity: 0.55
            }).addTo(mapa);

            const lista = p.nombres.map(n => `<li>${n}</li>`).join('');
            const mas   = p.total > 5 ? `<li>…y ${p.total - 5} más</li>` : '';
            marcador.bindPopup(`
                <strong>${p.dept}</strong><br>
                ${p.total} cliente${p.total !== 1 ? 's' : ''}<br>
                <ul style="padding-left:14px;margin:4px 0 0">${lista}${mas}</ul>
            `);
        });
    }

    function destroy(elementId) {
        if (_mapas[elementId]) {
            _mapas[elementId].remove();
            delete _mapas[elementId];
        }
    }

    return { init, destroy };
})();
