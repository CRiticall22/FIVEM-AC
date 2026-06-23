(() => {
    const $ = (s) => document.getElementById(s);
    const panel = $("panel");
    const overlay = $("overlay");
    const pageTitle = $("pageTitle");
    const pageSub = $("pageSubtitle");
    const navItems = document.querySelectorAll(".nav-item");
    const pages = document.querySelectorAll(".page");

    let isOpen = false;
    let detectionCount = 0;
    let startTime = Date.now();
    let detections = [];

    const pageData = {
        dashboard:  { title: "Dashboard",  sub: "Real-time server overview" },
        players:    { title: "Players",    sub: "Online player management" },
        bans:       { title: "Bans",       sub: "Ban history & management" },
        detections: { title: "Detections", sub: "Anticheat detection feed" },
        threats:    { title: "Threat Map", sub: "Player threat levels" },
        tools:      { title: "Tools",      sub: "Admin controls & utilities" },
    };

    navItems.forEach((btn) => {
        btn.addEventListener("click", () => {
            const page = btn.dataset.page;
            navItems.forEach((b) => b.classList.remove("active"));
            btn.classList.add("active");
            pages.forEach((p) => p.classList.remove("active"));
            const target = $("page-" + page);
            if (target) target.classList.add("active");
            const pd = pageData[page];
            if (pd) { pageTitle.textContent = pd.title; pageSub.textContent = pd.sub; }

            if (page === "players") nui("getPlayers");
            if (page === "bans") nui("getBans");
        });
    });

    $("closeBtn").addEventListener("click", closePanel);
    overlay.addEventListener("click", closePanel);

    function openPanel() {
        isOpen = true;
        panel.classList.add("open");
        overlay.classList.add("active");
        nui("menuOpen", { menuOpen: true });
    }

    function closePanel() {
        isOpen = false;
        panel.classList.remove("open");
        overlay.classList.remove("active");
        nui("menuOpen", { menuOpen: false });
    }

    function toast(msg, type) {
        const c = $("toastContainer");
        const t = document.createElement("div");
        t.className = "toast " + (type || "success");
        const icon = type === "error" ? "M18 6L6 18M6 6l12 12" :
                     type === "warning" ? "M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" :
                     "M22 11.08V12a10 10 0 11-5.93-9.14";
        t.innerHTML = `<svg class="toast-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="${icon}"/></svg><span>${esc(msg)}</span>`;
        c.appendChild(t);
        setTimeout(() => t.remove(), 3200);
    }

    window.addEventListener("message", (e) => {
        const d = e.data;

        if (d.menuOpen === true) openPanel();
        if (d.menuOpen === false) closePanel();

        if (d.nuiData) {
            if (d.nuiData.routingBucket !== undefined) {
                const el = $("routingBucket");
                if (el) el.value = d.nuiData.routingBucket;
            }
            if (d.nuiData.players !== undefined) {
                $("statPlayers").textContent = d.nuiData.players;
                $("navPlayerCount").textContent = d.nuiData.players;
                const bar = $("playerBar");
                if (bar) bar.style.width = Math.min(100, (d.nuiData.players / 64) * 100) + "%";
            }
            if (d.nuiData.totalBans !== undefined) {
                $("statBans").textContent = d.nuiData.totalBans;
                $("navBanCount").textContent = d.nuiData.totalBans;
            }
        }

        if (d.playerList) renderPlayers(d.playerList);
        if (d.banList) renderBans(d.banList);

        if (d.detection) {
            detectionCount++;
            $("statDetections").textContent = detectionCount;
            const badge = $("navDetectionCount");
            badge.textContent = detectionCount;
            badge.style.display = "";
            const bar = $("detBar");
            if (bar) bar.style.width = Math.min(100, detectionCount * 5) + "%";

            detections.unshift(d.detection);
            if (detections.length > 100) detections.pop();

            addFeedItem("detectionFeed", d.detection);
            addFeedItem("dashboardFeed", d.detection);
            toast(
                (d.detection.player || "Player") + " — " + (d.detection.reason || "Detection"),
                d.detection.type === "BAN" ? "error" : "warning"
            );
        }

        if (d.type === "ping") nui("pong");
    });

    function updateUptime() {
        const s = Math.floor((Date.now() - startTime) / 1000);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const txt = h > 0 ? h + "h " + m + "m" : m + "m";
        $("statUptime").textContent = txt;
        const el = $("shieldUptime");
        if (el) el.textContent = txt + " uptime";
    }
    setInterval(updateUptime, 15000);
    updateUptime();

    function renderPlayers(players) {
        const body = $("playerBody");
        if (!players || !players.length) {
            body.innerHTML = '<tr><td colspan="5" class="feed-empty">No players online</td></tr>';
            return;
        }
        body.innerHTML = players.map((p) => {
            const threat = p.threat || 0;
            const tClass = threat >= 80 ? "crit" : threat >= 50 ? "high" : threat >= 25 ? "med" : "low";
            return `<tr>
                <td><div class="player-cell"><div class="player-av">${(p.name || "?")[0].toUpperCase()}</div><span class="player-nm">${esc(p.name)}</span></div></td>
                <td style="font-family:'JetBrains Mono';font-size:11px;color:var(--text-muted)">${p.id}</td>
                <td style="font-family:'JetBrains Mono';font-size:11px;color:var(--text-muted)">${p.ping || "--"}ms</td>
                <td><span class="threat-badge ${tClass}">${threat}</span></td>
                <td><div class="action-btns">
                    <button class="act-btn" onclick="nui('kickPlayer',{id:${p.id}})">Kick</button>
                    <button class="act-btn danger" onclick="nui('banPlayer',{id:${p.id}})">Ban</button>
                </div></td>
            </tr>`;
        }).join("");

        renderThreatMap(players);
    }

    function renderBans(bans) {
        const body = $("banBody");
        if (!bans || !bans.length) {
            body.innerHTML = '<tr><td colspan="5" class="feed-empty">No active bans</td></tr>';
            return;
        }
        body.innerHTML = bans.map((b) => `<tr>
            <td><span class="ban-id-cell">${esc(b.id)}</span></td>
            <td><span class="player-nm">${esc(b.name)}</span></td>
            <td style="color:var(--text-muted);font-size:11px">${esc(b.reason)}</td>
            <td style="font-family:'JetBrains Mono';font-size:10px;color:var(--text-muted)">${esc(b.date || "")}</td>
            <td><button class="act-btn success" onclick="nui('unbanPlayer',{banId:'${esc(b.id)}'})">Unban</button></td>
        </tr>`).join("");
    }

    function renderThreatMap(players) {
        const grid = $("threatGrid");
        if (!grid) return;
        if (!players || !players.length) {
            grid.innerHTML = '<div class="feed-empty"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg><span>No threat data</span></div>';
            return;
        }
        const r = 15.9;
        const circ = 2 * Math.PI * r;
        grid.innerHTML = players.map((p) => {
            const t = p.threat || 0;
            const pct = t / 100;
            const offset = circ * (1 - pct);
            const color = t >= 80 ? "var(--red)" : t >= 50 ? "var(--amber)" : t >= 25 ? "#eab308" : "var(--green)";
            const tClass = t >= 80 ? "crit" : t >= 50 ? "high" : t >= 25 ? "med" : "low";
            return `<div class="threat-player">
                <div class="threat-ring">
                    <svg viewBox="0 0 36 36"><circle class="ring-bg" cx="18" cy="18" r="${r}"/><circle class="ring-fill" cx="18" cy="18" r="${r}" stroke="${color}" stroke-dasharray="${circ}" stroke-dashoffset="${offset}"/></svg>
                    <span class="threat-score-text" style="color:${color}">${t}</span>
                </div>
                <div class="threat-player-info">
                    <span class="threat-player-name">${esc(p.name)}</span>
                    <span class="threat-player-id">ID: ${p.id}</span>
                </div>
                <span class="threat-badge ${tClass}">${t >= 80 ? "CRIT" : t >= 50 ? "HIGH" : t >= 25 ? "MED" : "LOW"}</span>
            </div>`;
        }).join("");
    }

    function addFeedItem(containerId, det) {
        const container = $(containerId);
        const empty = container.querySelector(".feed-empty");
        if (empty) empty.remove();

        const el = document.createElement("div");
        el.className = "feed-item";
        el.dataset.type = det.type || "";
        const cls = det.type === "BAN" ? "ban" : det.type === "KICK" ? "kick" : "warn";
        const now = new Date();
        const time = now.getHours().toString().padStart(2, "0") + ":" +
                     now.getMinutes().toString().padStart(2, "0") + ":" +
                     now.getSeconds().toString().padStart(2, "0");
        el.innerHTML = `
            <div class="feed-severity ${cls}"></div>
            <div class="feed-body">
                <span class="feed-title">${esc(det.player || "Unknown")}</span>
                <span class="feed-desc">${esc(det.reason || "")}</span>
            </div>
            <span class="feed-time">${time}</span>`;
        container.prepend(el);

        const max = containerId === "dashboardFeed" ? 20 : 50;
        while (container.children.length > max) container.lastChild.remove();
    }

    function esc(str) {
        if (!str) return "";
        const d = document.createElement("div");
        d.textContent = str;
        return d.innerHTML;
    }

    $("deleteVehicles").addEventListener("click", () => { nui("nuiEvent", { type: "deleteVehicles" }); toast("Vehicles deleted", "success"); });
    $("deletePeds").addEventListener("click", () => { nui("nuiEvent", { type: "deletePeds" }); toast("Peds deleted", "success"); });
    $("deleteObjects").addEventListener("click", () => { nui("nuiEvent", { type: "deleteObjects" }); toast("Objects deleted", "success"); });

    $("setBucket").addEventListener("click", () => {
        const val = parseInt($("routingBucket").value) || 0;
        nui("nuiEvent", { type: "setRoutingBucket", value: val });
        toast("Routing bucket set to " + val, "success");
    });

    $("espToggle").addEventListener("change", (e) => {
        nui("nuiEvent", { type: "ESP", value: e.target.checked });
        toast(e.target.checked ? "ESP enabled" : "ESP disabled", "success");
    });

    const shadowToggle = $("shadowToggle");
    if (shadowToggle) {
        shadowToggle.addEventListener("change", (e) => {
            nui("nuiEvent", { type: "shadowMode", value: e.target.checked });
            toast(e.target.checked ? "Shadow mode ON — logging only" : "Shadow mode OFF — punishments active", e.target.checked ? "warning" : "success");
        });
    }

    $("clearFeed").addEventListener("click", () => {
        $("detectionFeed").innerHTML = '<div class="feed-empty"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="32" height="32"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg><span>Monitoring for threats...</span></div>';
        detections = [];
        toast("Feed cleared", "success");
    });

    const detFilter = $("detectionFilter");
    if (detFilter) {
        detFilter.addEventListener("change", (e) => {
            const v = e.target.value;
            document.querySelectorAll("#detectionFeed .feed-item").forEach((item) => {
                item.style.display = v === "all" || item.dataset.type === v ? "" : "none";
            });
        });
    }

    const playerSearch = $("playerSearch");
    if (playerSearch) {
        playerSearch.addEventListener("input", (e) => {
            const q = e.target.value.toLowerCase();
            document.querySelectorAll("#playerBody tr").forEach((row) => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(q) ? "" : "none";
            });
        });
    }

    const banSearch = $("banSearch");
    if (banSearch) {
        banSearch.addEventListener("input", (e) => {
            const q = e.target.value.toLowerCase();
            document.querySelectorAll("#banBody tr").forEach((row) => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(q) ? "" : "none";
            });
        });
    }

    document.addEventListener("keydown", (e) => {
        if (e.key === "Escape" && isOpen) closePanel();
    });

    nui("menuReady");
})();
