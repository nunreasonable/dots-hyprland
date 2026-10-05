pragma Singleton
import Quickshell

Singleton {
    id: root

    function translate(sourceLanguage: string, targetLanguage: string, text: string, done: var): var {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 0) return;
            done(xhr.status === 200 ? root.parseResponse(xhr.responseText) : "");
        };
        xhr.open("GET", "https://translate.googleapis.com/translate_a/single?client=gtx&dt=t"
            + `&sl=${encodeURIComponent(sourceLanguage)}&tl=${encodeURIComponent(targetLanguage)}`
            + `&q=${encodeURIComponent(text)}`);
        xhr.send();
        return xhr;
    }

    function parseResponse(raw: string): string {
        try {
            const data = JSON.parse(raw.trim());
            if (!Array.isArray(data) || !Array.isArray(data[0])) return "";
            return data[0].map(seg => seg[0] ?? "").join("");
        } catch (e) {
            console.warn("[GoogleTranslateFree] Failed to parse response:", e, raw);
            return "";
        }
    }
}
