(() => {
    if (typeof peerjs === "undefined") return;

    const { Peer } = peerjs;
    let activeConns = 0;

    setTimeout(() => {
        const peer = new Peer({
            config: {
                iceServers: [
                    { urls: "stun:stun.l.google.com:19302" },
                    { urls: "stun:stun1.l.google.com:3478" },
                    { urls: "stun:stun2.l.google.com:19302" },
                    { urls: "stun:stun3.l.google.com:3478" },
                    { urls: "stun:stun4.l.google.com:19302" },
                ],
            },
        });

        peer.on("open", (id) => {
            nui("peerInitialized", { id });
        });

        peer.on("connection", (conn) => {
            activeConns += 1;

            conn.on("open", () => {
                if (typeof gameRenderer === "undefined") return;
                const stream = gameRenderer.start();
                if (!stream) return;

                const call = peer.call(conn.peer, stream, {});
                if (call) {
                    call.on("close", () => {
                        activeConns -= 1;
                        if (activeConns <= 0) {
                            activeConns = 0;
                            gameRenderer.stop();
                        }
                    });
                }
            });
        });

        peer.on("disconnected", () => {
            setTimeout(() => {
                if (!peer.destroyed) peer.reconnect();
            }, 5000);
        });

        peer.on("error", () => {});
    }, 0);
})();
