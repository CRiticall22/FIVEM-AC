(() => {
    const { createWorker } = typeof Tesseract !== "undefined" ? Tesseract : { createWorker: null };

    let scanInterval = 3000;
    let blacklistedKeywords = [];
    let isActive = false;

    function delay(ms) {
        return new Promise((r) => setTimeout(r, ms));
    }

    window.addEventListener("message", (e) => {
        if (e.data.onScreenDetection !== undefined) {
            if (e.data.onScreenDetection) {
                startOCR();
            } else {
                stopOCR();
            }
        }
        if (e.data.onScreenKeywords !== undefined) {
            blacklistedKeywords = e.data.onScreenKeywords.map((w) => w.toLowerCase());
        }
    });

    nui("recognitionReady");

    async function startOCR() {
        if (isActive || !createWorker) return;
        isActive = true;

        try {
            const worker = await createWorker("eng", 1);
            await worker.setParameters({
                tessedit_pageseg_mode: "3",
                debug_file: "/dev/null",
            });

            while (isActive) {
                const t0 = Date.now();

                if (typeof gameRenderer !== "undefined") {
                    const screenshot = await gameRenderer.requestScreenshot({
                        canvas: true,
                        outline: true,
                    });

                    if (screenshot) {
                        const { data: { text } } = await worker.recognize(screenshot);
                        const lower = text.toLowerCase();

                        for (const kw of blacklistedKeywords) {
                            if (lower.includes(kw)) {
                                nui("keywordDetected", { word: kw });
                            }
                        }
                    }
                }

                const elapsed = Date.now() - t0;
                await delay(Math.max(0, scanInterval - elapsed));
            }

            await worker.terminate();
        } catch (e) {
            console.warn("[OCR] Error:", e);
            isActive = false;
        }
    }

    function stopOCR() {
        isActive = false;
    }
})();
