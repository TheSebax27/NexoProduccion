window.nexoAppSelect = {
    getRect: (el) => {
        const r = el.getBoundingClientRect();
        return { Bottom: r.bottom, Left: r.left, Width: r.width };
    },
    positionList: (comboEl, listEl) => {
        if (!comboEl || !listEl) return;
        const r = comboEl.getBoundingClientRect();
        const vh = window.innerHeight;
        const gap = 4;
        const maxH = 300;
        const spaceBelow = vh - r.bottom - gap;
        listEl.style.position = 'fixed';
        listEl.style.left = r.left + 'px';
        listEl.style.width = r.width + 'px';
        listEl.style.right = 'auto';
        listEl.style.margin = '0';
        if (spaceBelow >= 120) {
            listEl.style.top = (r.bottom + gap) + 'px';
            listEl.style.bottom = 'auto';
            listEl.style.maxHeight = Math.min(maxH, spaceBelow) + 'px';
        } else {
            const spaceAbove = r.top - gap;
            listEl.style.bottom = (vh - r.top + gap) + 'px';
            listEl.style.top = 'auto';
            listEl.style.maxHeight = Math.min(maxH, spaceAbove) + 'px';
        }
    }
};
