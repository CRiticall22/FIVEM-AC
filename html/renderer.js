(() => {
    let mediaStream = null;
    let canvas = null;

    const gameRenderer = {
        start() {
            if (mediaStream) return mediaStream;
            try {
                canvas = document.createElement("canvas");
                canvas.width = 1280;
                canvas.height = 720;
                mediaStream = canvas.captureStream(15);
                this._drawLoop();
            } catch (e) {
                console.warn("[Renderer] Could not start capture:", e);
            }
            return mediaStream;
        },

        stop() {
            if (mediaStream) {
                mediaStream.getTracks().forEach((t) => t.stop());
                mediaStream = null;
            }
            canvas = null;
        },

        _drawLoop() {
            if (!canvas || !mediaStream) return;
            const ctx = canvas.getContext("2d");
            ctx.fillStyle = "#000";
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.fillStyle = "#fff";
            ctx.font = "14px monospace";
            ctx.fillText("2F4R Live View", 10, 20);
            requestAnimationFrame(() => this._drawLoop());
        },

        async requestScreenshot(opts = {}) {
            return new Promise((resolve) => {
                try {
                    const w = 640, h = 360;
                    const c = document.createElement("canvas");
                    c.width = w;
                    c.height = h;
                    const ctx = c.getContext("2d");

                    if (opts.outline) {
                        ctx.fillStyle = "#111";
                        ctx.fillRect(0, 0, w, h);
                        ctx.strokeStyle = "#0f0";
                        ctx.lineWidth = 2;
                        ctx.strokeRect(10, 10, w - 20, h - 20);
                        ctx.fillStyle = "#0f0";
                        ctx.font = "12px monospace";
                        ctx.fillText("2F4R OCR Capture", 20, 30);
                    }

                    if (opts.canvas) {
                        resolve(c);
                    } else {
                        c.toBlob((blob) => resolve(blob), "image/png");
                    }
                } catch (e) {
                    resolve(null);
                }
            });
        },
    };

    window.gameRenderer = gameRenderer;
})();
