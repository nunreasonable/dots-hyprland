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

    // Several texts in one request, each with its own detected language: joined
    // into one text, a source of "auto" takes the language of most of it and
    // leaves lines in any other untouched. `done` gets the translations in
    // order, or [] if the request failed.
    function translateMany(sourceLanguage: string, targetLanguage: string, texts: var, done: var): var {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 0) return;
            done(xhr.status === 200 ? root.parseManyResponse(xhr.responseText, texts.length) : []);
        };
        xhr.open("GET", "https://translate.googleapis.com/translate_a/t?client=gtx"
            + `&sl=${encodeURIComponent(sourceLanguage)}&tl=${encodeURIComponent(targetLanguage)}`
            + texts.map(text => `&q=${encodeURIComponent(text)}`).join(""));
        xhr.send();
        return xhr;
    }

    function parseManyResponse(raw: string, count: int): var {
        try {
            const data = JSON.parse(raw.trim());
            if (!Array.isArray(data) || data.length !== count) return [];
            // With "auto", each entry is [translation, detected language].
            return data.map(entry => Array.isArray(entry) ? (entry[0] ?? "") : (entry ?? ""));
        } catch (e) {
            console.warn("[GoogleTranslateFree] Failed to parse response:", e, raw);
            return [];
        }
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
