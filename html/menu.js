(() => {
    const panel = document.getElementById("panel");
    const overlay = document.getElementById("overlay");
    const closeBtn = document.getElementById("closeBtn");
    const navBtns = document.querySelectorAll(".nav-btn");
    const pages = document.querySelectorAll(".page");

    function show(visible) {
        panel.style.display = visible ? "block" : "none";
        overlay.style.display = visible ? "block" : "none";
        nui("menuOpen", { menuOpen: visible });
    }

    window.addEventListener("message", (e) => {
        if (e.data.menuOpen !== undefined) show(e.data.menuOpen);
        if (e.data.nuiData) {
            const rb = document.getElementById("routingBucket");
            if (rb && e.data.nuiData.routingBucket !== undefined)
                rb.value = e.data.nuiData.routingBucket;
        }
    });

    overlay.addEventListener("click", () => show(false));
    closeBtn.addEventListener("click", () => show(false));

    navBtns.forEach((btn) => {
        btn.addEventListener("click", () => {
            navBtns.forEach((b) => b.classList.remove("active"));
            btn.classList.add("active");
            const target = btn.dataset.page;
            pages.forEach((p) => {
                p.classList.toggle("active", p.id === `page-${target}`);
            });
        });
    });

    document.getElementById("deleteVehicles").addEventListener("click", () => {
        nui("nuiEvent", { type: "deleteVehicles" });
    });
    document.getElementById("deletePeds").addEventListener("click", () => {
        nui("nuiEvent", { type: "deletePeds" });
    });
    document.getElementById("deleteObjects").addEventListener("click", () => {
        nui("nuiEvent", { type: "deleteObjects" });
    });

    document.getElementById("routingBucket").addEventListener("change", (e) => {
        nui("nuiEvent", { type: "setRoutingBucket", value: parseInt(e.target.value) });
    });

    document.getElementById("espToggle").addEventListener("change", (e) => {
        nui("nuiEvent", { type: "ESP", value: e.target.checked });
    });

    nui("menuReady");
})();
