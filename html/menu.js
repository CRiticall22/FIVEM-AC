(() => {
    const panel = document.getElementById("panel");
    const overlay = document.getElementById("overlay");
    const pageTitle = document.getElementById("pageTitle");
    const navItems = document.querySelectorAll(".nav-item");
    const pages = document.querySelectorAll(".page");

    let isOpen = false;
    let detectionCount = 0;
    let startTime = Date.now();

    const titles = {
        dashboard: "Dashboard",
        players: "Players",
        bans: "Bans",
        detections: "Detections",
        tools: "Tools",
    };

    navItems.forEach((btn) => {
        btn.addEventListener("click", () => {
            const page = btn.dataset.page;
            navItems.forEach((b) => b.classList.remove("active"));
            btn.classList.add("active");
            pages.forEach((p) => p.classList.remove("active"));
            const target = document.getElementById("page-" + page);
            if (target) target.classList.add("active");
            pageTitle.textContent = titles[page] || page;

            if (page === "players") nui("getPlayers");
            if (page === "bans") nui("getBans");
        });
    });

    document.getElementById("closeBtn").addEventListener("click", () => {
        closePanel();
    });

    overlay.addEventListener("click", () => {
        closePanel();
    });

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

    window.addEventListener("message", (e) => {
        const d = e.data;

        if (d.menuOpen === true) openPanel();
        if (d.menuOpen === false) closePanel();

        if (d.nuiData) {
            if (d.nuiData.routingBucket !== undefined) {
                const el = document.getElementById("routingBucket");
                if (el) el.value = d.nuiData.routingBucket;
            }
            if (d.nuiData.players !== undefined) {
                document.getElementById("statPlayers").textContent = d.nuiData.players;
            }
            if (d.nuiData.totalBans !== undefined) {
                document.getElementById("statBans").textContent = d.nuiData.totalBans;
            }
        }

        if (d.playerList) renderPlayers(d.playerList);
        if (d.banList) renderBans(d.banList);

        if (d.detection) {
            detectionCount++;
            document.getElementById("statDetections").textContent = detectionCount;
            addDetectionFeed(d.detection);
            addDashboardFeed(d.detection);
        }

        if (d.type === "ping") nui("pong");
    });

    function updateUptime() {
        const elapsed = Math.floor((Date.now() - startTime) / 1000);
        const h = Math.floor(elapsed / 3600);
        const m = Math.floor((elapsed % 3600) / 60);
        document.getElementById("statUptime").textContent =
            h > 0 ? h + "h " + m + "m" : m + "m";
    }
    setInterval(updateUptime, 30000);
    updateUptime();

    function renderPlayers(players) {
        const container = document.getElementById("playerList");
        if (!players || players.length === 0) {
            container.innerHTML = '<div class="feed-empty">No players online</div>';
            return;
        }
        container.innerHTML = players
            .map(
                (p) => `
            <div class="player-row" data-id="${p.id}">
                <div class="player-avatar">${(p.name || "?")[0].toUpperCase()}</div>
                <div class="player-info">
                    <span class="player-name">${esc(p.name)}</span>
                    <span class="player-id">ID: ${p.id}</span>
                </div>
                <div class="player-actions">
                    <button class="btn-icon danger" onclick="nui('kickPlayer',{id:${p.id}})" title="Kick">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>
                    </button>
                    <button class="btn-icon danger" onclick="nui('banPlayer',{id:${p.id}})" title="Ban">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m4.93 4.93 14.14 14.14"/></svg>
                    </button>
                </div>
            </div>`
            )
            .join("");
    }

    function renderBans(bans) {
        const container = document.getElementById("banList");
        if (!bans || bans.length === 0) {
            container.innerHTML = '<div class="feed-empty">No active bans</div>';
            return;
        }
        container.innerHTML = bans
            .map(
                (b) => `
            <div class="ban-row">
                <span class="ban-id">${esc(b.id)}</span>
                <div class="ban-info">
                    <span class="ban-name">${esc(b.name)}</span>
                    <span class="ban-reason">${esc(b.reason)} — ${esc(b.date || "")}</span>
                </div>
                <button class="btn-small" onclick="nui('unbanPlayer',{banId:'${esc(b.id)}'})">Unban</button>
            </div>`
            )
            .join("");
    }

    function addDetectionFeed(det) {
        const container = document.getElementById("detectionFeed");
        const empty = container.querySelector(".feed-empty");
        if (empty) empty.remove();

        const el = document.createElement("div");
        el.className = "feed-item";
        const cls = det.type === "BAN" ? "ban" : det.type === "KICK" ? "kick" : "warn";
        const now = new Date();
        const time = now.getHours().toString().padStart(2, "0") + ":" + now.getMinutes().toString().padStart(2, "0");
        el.innerHTML = `
            <span class="feed-dot ${cls}"></span>
            <span class="feed-text"><strong>${esc(det.player || "?")}</strong> — ${esc(det.reason || "")}</span>
            <span class="feed-time">${time}</span>`;
        container.prepend(el);

        while (container.children.length > 50) container.lastChild.remove();
    }

    function addDashboardFeed(det) {
        const container = document.getElementById("dashboardFeed");
        const empty = container.querySelector(".feed-empty");
        if (empty) empty.remove();

        const el = document.createElement("div");
        el.className = "feed-item";
        const cls = det.type === "BAN" ? "ban" : det.type === "KICK" ? "kick" : "warn";
        const now = new Date();
        const time = now.getHours().toString().padStart(2, "0") + ":" + now.getMinutes().toString().padStart(2, "0");
        el.innerHTML = `
            <span class="feed-dot ${cls}"></span>
            <span class="feed-text"><strong>${esc(det.player || "?")}</strong> — ${esc(det.reason || "")}</span>
            <span class="feed-time">${time}</span>`;
        container.prepend(el);

        while (container.children.length > 20) container.lastChild.remove();
    }

    function esc(str) {
        const d = document.createElement("div");
        d.textContent = str;
        return d.innerHTML;
    }

    document.getElementById("deleteVehicles").addEventListener("click", () => nui("nuiEvent", { type: "deleteVehicles" }));
    document.getElementById("deletePeds").addEventListener("click", () => nui("nuiEvent", { type: "deletePeds" }));
    document.getElementById("deleteObjects").addEventListener("click", () => nui("nuiEvent", { type: "deleteObjects" }));

    document.getElementById("setBucket").addEventListener("click", () => {
        const val = parseInt(document.getElementById("routingBucket").value) || 0;
        nui("nuiEvent", { type: "setRoutingBucket", value: val });
    });

    document.getElementById("espToggle").addEventListener("change", (e) => {
        nui("nuiEvent", { type: "ESP", value: e.target.checked });
    });

    document.getElementById("clearFeed").addEventListener("click", () => {
        document.getElementById("detectionFeed").innerHTML = '<div class="feed-empty">Waiting for detections...</div>';
    });

    const playerSearch = document.getElementById("playerSearch");
    if (playerSearch) {
        playerSearch.addEventListener("input", (e) => {
            const q = e.target.value.toLowerCase();
            document.querySelectorAll(".player-row").forEach((row) => {
                const name = row.querySelector(".player-name")?.textContent.toLowerCase() || "";
                const id = row.querySelector(".player-id")?.textContent.toLowerCase() || "";
                row.style.display = name.includes(q) || id.includes(q) ? "" : "none";
            });
        });
    }

    const banSearch = document.getElementById("banSearch");
    if (banSearch) {
        banSearch.addEventListener("input", (e) => {
            const q = e.target.value.toLowerCase();
            document.querySelectorAll(".ban-row").forEach((row) => {
                const name = row.querySelector(".ban-name")?.textContent.toLowerCase() || "";
                const id = row.querySelector(".ban-id")?.textContent.toLowerCase() || "";
                row.style.display = name.includes(q) || id.includes(q) ? "" : "none";
            });
        });
    }

    nui("menuReady");
})();
