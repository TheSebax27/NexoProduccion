/* =========================================================================
   FORGE — app.js
   Vanilla JS interactions: sidebar, theme, dropdowns, table, widgets
   ========================================================================= */
(function () {
  'use strict';

  const shell = document.getElementById('shell');

  /* ---------------------------------------------------------------------
     1. SIDEBAR COLLAPSE / MOBILE NAV
     --------------------------------------------------------------------- */
  const collapseBtn = document.getElementById('collapseBtn');
  const navToggle = document.getElementById('navToggle');

  collapseBtn.addEventListener('click', () => {
    shell.classList.toggle('shell--collapsed');
  });

  navToggle.addEventListener('click', () => {
    shell.classList.toggle('shell--nav-open');
  });

  function syncMobileNav() {
    const isMobile = window.innerWidth <= 860;
    navToggle.style.display = isMobile ? 'flex' : 'none';
  }
  window.addEventListener('resize', syncMobileNav);
  syncMobileNav();

  /* ---------------------------------------------------------------------
     2. SUBMENU TOGGLE
     --------------------------------------------------------------------- */
  document.querySelectorAll('[data-submenu]').forEach((trigger) => {
    trigger.addEventListener('click', () => {
      const key = trigger.getAttribute('data-submenu');
      const submenu = document.getElementById('submenu-' + key);
      const expanded = trigger.getAttribute('aria-expanded') === 'true';
      trigger.setAttribute('aria-expanded', String(!expanded));
      submenu.classList.toggle('sidebar__submenu--open');
    });
    trigger.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); trigger.click(); }
    });
  });

  /* ---------------------------------------------------------------------
     3. THEME TOGGLE (light / dark)
     --------------------------------------------------------------------- */
  const themeToggle = document.getElementById('themeToggle');
  const root = document.documentElement;

  function applyTheme(theme) {
    if (theme === 'dark') root.setAttribute('data-theme', 'dark');
    else root.removeAttribute('data-theme');
  }

  let currentTheme = 'light';
  applyTheme(currentTheme);

  themeToggle.addEventListener('click', () => {
    currentTheme = currentTheme === 'light' ? 'dark' : 'light';
    applyTheme(currentTheme);
  });

  /* ---------------------------------------------------------------------
     4. DROPDOWN PANELS (notifications / tasks)
     --------------------------------------------------------------------- */
  function setupPanel(btnId, panelId) {
    const btn = document.getElementById(btnId);
    const panel = document.getElementById(panelId);
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const isOpen = panel.classList.contains('panel--open');
      closeAllPanels();
      if (!isOpen) panel.classList.add('panel--open');
    });
  }
  function closeAllPanels() {
    document.querySelectorAll('.panel').forEach((p) => p.classList.remove('panel--open'));
  }
  setupPanel('notifBtn', 'notifPanel');
  setupPanel('tasksBtn', 'tasksPanel');
  document.addEventListener('click', closeAllPanels);

  /* ---------------------------------------------------------------------
     5. OEE GAUGE ANIMATION
     --------------------------------------------------------------------- */
  const oeeRing = document.getElementById('oeeRing');
  const OEE_VALUE = 0.912;
  const CIRCUMFERENCE = 439.8;
  requestAnimationFrame(() => {
    setTimeout(() => {
      oeeRing.style.transition = 'stroke-dashoffset 1100ms cubic-bezier(.16,1,.3,1)';
      oeeRing.style.strokeDashoffset = String(CIRCUMFERENCE * (1 - OEE_VALUE));
    }, 150);
  });

  /* ---------------------------------------------------------------------
     6. MACHINE STATUS GRID (generated)
     --------------------------------------------------------------------- */
  const machineGrid = document.getElementById('machineGrid');
  const STATUS_WEIGHTS = [
    { cls: '', weight: 24 },
    { cls: 'machine--warn', weight: 4 },
    { cls: 'machine--bad', weight: 1 },
    { cls: 'machine--idle', weight: 3 },
  ];
  function pickWeighted(items) {
    const total = items.reduce((s, i) => s + i.weight, 0);
    let r = Math.random() * total;
    for (const item of items) {
      if (r < item.weight) return item.cls;
      r -= item.weight;
    }
    return items[0].cls;
  }
  const MACHINE_COUNT = 32;
  for (let i = 0; i < MACHINE_COUNT; i++) {
    const div = document.createElement('div');
    const cls = pickWeighted(STATUS_WEIGHTS);
    div.className = 'machine' + (cls ? ' ' + cls : '');
    div.title = 'Máquina ' + (i + 1).toString().padStart(2, '0');
    machineGrid.appendChild(div);
  }

  /* ---------------------------------------------------------------------
     7. MINI CALENDAR (generated for current month)
     --------------------------------------------------------------------- */
  const miniCal = document.getElementById('miniCal');
  const DOW = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  const TODAY = new Date(2026, 6, 29); // July 29, 2026
  const EVENT_DAYS = [3, 8, 15, 22, 29];

  function buildCalendar() {
    miniCal.innerHTML = '';
    DOW.forEach((d) => {
      const el = document.createElement('div');
      el.className = 'mini-cal__dow';
      el.textContent = d;
      miniCal.appendChild(el);
    });

    const year = TODAY.getFullYear();
    const month = TODAY.getMonth();
    const firstDay = new Date(year, month, 1);
    // Convert Sunday=0 based to Monday=0 based
    let startOffset = firstDay.getDay() - 1;
    if (startOffset < 0) startOffset = 6;
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrevMonth = new Date(year, month, 0).getDate();

    for (let i = 0; i < startOffset; i++) {
      const el = document.createElement('div');
      el.className = 'mini-cal__day mini-cal__day--muted';
      el.textContent = daysInPrevMonth - startOffset + i + 1;
      miniCal.appendChild(el);
    }
    for (let d = 1; d <= daysInMonth; d++) {
      const el = document.createElement('div');
      el.className = 'mini-cal__day';
      if (d === TODAY.getDate()) el.classList.add('mini-cal__day--today');
      if (EVENT_DAYS.includes(d)) el.classList.add('mini-cal__day--event');
      el.textContent = d;
      miniCal.appendChild(el);
    }
  }
  buildCalendar();

  /* ---------------------------------------------------------------------
     8. HEATMAP (production intensity per line / hour)
     --------------------------------------------------------------------- */
  const heatmapWrap = document.getElementById('heatmapWrap');
  const LINES = ['Línea 1', 'Línea 2', 'Línea 3', 'Línea 4', 'Línea 5'];
  const HOURS = 24;

  function heatColor(intensity) {
    // intensity 0..1 -> mapped from signal-100 to signal-600
    const stops = [
      { t: 0, c: [242, 246, 253] },
      { t: 0.5, c: [91, 132, 232] },
      { t: 1, c: [23, 39, 92] },
    ];
    let lower = stops[0], upper = stops[stops.length - 1];
    for (let i = 0; i < stops.length - 1; i++) {
      if (intensity >= stops[i].t && intensity <= stops[i + 1].t) {
        lower = stops[i]; upper = stops[i + 1]; break;
      }
    }
    const range = upper.t - lower.t || 1;
    const localT = (intensity - lower.t) / range;
    const rgb = lower.c.map((v, idx) => Math.round(v + (upper.c[idx] - v) * localT));
    return `rgb(${rgb[0]},${rgb[1]},${rgb[2]})`;
  }

  LINES.forEach((line) => {
    const row = document.createElement('div');
    row.className = 'heatmap__row';
    const label = document.createElement('div');
    label.className = 'heatmap__row-label';
    label.textContent = line;
    row.appendChild(label);

    const grid = document.createElement('div');
    grid.className = 'heatmap';
    for (let h = 0; h < HOURS; h++) {
      const cell = document.createElement('div');
      cell.className = 'heatmap__cell';
      // Simulate shift-based intensity curve with some noise
      const shiftCurve = Math.sin((h / HOURS) * Math.PI * 2 - 1.4) * 0.35 + 0.55;
      const intensity = Math.min(1, Math.max(0, shiftCurve + (Math.random() - 0.5) * 0.25));
      cell.style.background = heatColor(intensity);
      cell.title = `${line} · ${h}:00 — ${Math.round(intensity * 100)}%`;
      grid.appendChild(cell);
    }
    row.appendChild(grid);
    heatmapWrap.appendChild(row);
  });

  /* ---------------------------------------------------------------------
     9. ORDERS TABLE — data, render, sort, filter
     --------------------------------------------------------------------- */
  const ORDERS = [
    { op: 'OP-2291', product: 'Chasis modelo X4', line: 'Línea 1', operator: 'Julián Pardo', progress: 82, status: 'proceso', due: '2026-07-29' },
    { op: 'OP-2290', product: 'Motor eléctrico M2', line: 'Línea 2', operator: 'Sara Rincón', progress: 64, status: 'proceso', due: '2026-07-29' },
    { op: 'OP-2288', product: 'Panel de control V1', line: 'Línea 3', operator: 'Diego León', progress: 31, status: 'retrasada', due: '2026-07-28' },
    { op: 'OP-2287', product: 'Carcasa aluminio', line: 'Línea 1', operator: 'Ana Torres', progress: 100, status: 'completada', due: '2026-07-28' },
    { op: 'OP-2285', product: 'Ensamble final X4', line: 'Línea 4', operator: 'Mateo Ruiz', progress: 47, status: 'proceso', due: '2026-07-30' },
    { op: 'OP-2283', product: 'Sistema de frenos', line: 'Línea 5', operator: 'Laura Gómez', progress: 12, status: 'retrasada', due: '2026-07-27' },
    { op: 'OP-2281', product: 'Cableado interno', line: 'Línea 2', operator: 'Carlos Mena', progress: 100, status: 'completada', due: '2026-07-27' },
    { op: 'OP-2279', product: 'Cubierta de motor', line: 'Línea 3', operator: 'Nicolás Vega', progress: 55, status: 'proceso', due: '2026-07-29' },
  ];

  const STATUS_MAP = {
    proceso: { label: 'En proceso', cls: 'badge--good' },
    retrasada: { label: 'Retrasada', cls: 'badge--bad' },
    completada: { label: 'Completada', cls: 'badge--idle' },
  };

  function initials(name) {
    return name.split(' ').map((p) => p[0]).slice(0, 2).join('').toUpperCase();
  }

  function formatDate(iso) {
    const d = new Date(iso + 'T00:00:00');
    return d.toLocaleDateString('es-CO', { day: '2-digit', month: 'short' });
  }

  const ordersBody = document.getElementById('ordersBody');
  let sortKey = null;
  let sortDir = 1;

  function renderOrders(data) {
    ordersBody.innerHTML = '';
    data.forEach((row) => {
      const status = STATUS_MAP[row.status];
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td class="mono">${row.op}</td>
        <td>${row.product}</td>
        <td>${row.line}</td>
        <td>
          <div class="dtable__op">
            <div class="dtable__op-avatar">${initials(row.operator)}</div>
            ${row.operator}
          </div>
        </td>
        <td>
          <div class="dtable__progress">
            <div class="dtable__progress-track"><div class="dtable__progress-fill" style="width:${row.progress}%"></div></div>
            <span class="mono">${row.progress}%</span>
          </div>
        </td>
        <td><span class="badge ${status.cls}">${status.label}</span></td>
        <td class="mono">${formatDate(row.due)}</td>
        <td>
          <div class="dtable__actions">
            <button class="icon-btn-sm" aria-label="Ver">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
            </button>
            <button class="icon-btn-sm" aria-label="Más opciones">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="5" r="1.5"/><circle cx="12" cy="12" r="1.5"/><circle cx="12" cy="19" r="1.5"/></svg>
            </button>
          </div>
        </td>
      `;
      ordersBody.appendChild(tr);
    });
  }

  function applySort(data) {
    if (!sortKey) return data;
    const sorted = [...data].sort((a, b) => {
      const av = a[sortKey], bv = b[sortKey];
      if (typeof av === 'number') return (av - bv) * sortDir;
      return String(av).localeCompare(String(bv)) * sortDir;
    });
    return sorted;
  }

  function applyFilter(data, query) {
    if (!query) return data;
    const q = query.toLowerCase();
    return data.filter((row) =>
      row.op.toLowerCase().includes(q) ||
      row.product.toLowerCase().includes(q) ||
      row.line.toLowerCase().includes(q) ||
      row.operator.toLowerCase().includes(q)
    );
  }

  function refreshTable() {
    const query = document.getElementById('tableSearch').value;
    renderOrders(applySort(applyFilter(ORDERS, query)));
  }

  document.querySelectorAll('#ordersTable thead th[data-key]').forEach((th) => {
    th.addEventListener('click', () => {
      const key = th.getAttribute('data-key');
      if (sortKey === key) sortDir *= -1;
      else { sortKey = key; sortDir = 1; }
      refreshTable();
    });
  });

  document.getElementById('tableSearch').addEventListener('input', refreshTable);

  document.querySelectorAll('.table-tab').forEach((tab) => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.table-tab').forEach((t) => t.classList.remove('table-tab--active'));
      tab.classList.add('table-tab--active');
    });
  });

  renderOrders(ORDERS);

  /* ---------------------------------------------------------------------
     10. CHECKLIST TOGGLE
     --------------------------------------------------------------------- */
  document.querySelectorAll('.check-item').forEach((item) => {
    item.addEventListener('click', () => {
      item.classList.toggle('check-item--done');
      const box = item.querySelector('.check-item__box');
      box.textContent = item.classList.contains('check-item--done') ? '✓' : '';
    });
  });

  /* ---------------------------------------------------------------------
     11. TOAST — simulate a live alert arriving
     --------------------------------------------------------------------- */
  function showToast(message) {
    const stack = document.getElementById('toastStack');
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<span class="toast__dot"></span><span>${message}</span>`;
    stack.appendChild(toast);
    setTimeout(() => {
      toast.style.transition = 'opacity 300ms, transform 300ms';
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(8px)';
      setTimeout(() => toast.remove(), 300);
    }, 4000);
  }

  setTimeout(() => showToast('Línea 1 alcanzó el 100% de la meta de turno'), 3000);

})();