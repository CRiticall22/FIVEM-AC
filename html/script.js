(() => {
    const getResource = () =>
        typeof GetParentResourceName !== "undefined" ? GetParentResourceName() : "electronac";

    const nui = async (event, data = {}) => {
        try {
            return await fetch(`https://${getResource()}/${event}`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(data),
            });
        } catch {}
    };

    window.nui = nui;

    window.addEventListener("message", (e) => {
        if (e.data.type === "ping") nui("pong");
    });

    window.addEventListener("offline", () => nui("playerOffline"));

    const devToolsTrap = Object.defineProperties(new Error(), {
        message: { get() { nui("NUIDevTools"); } },
    });
    console.log(devToolsTrap);

    nui("ready");
})();
