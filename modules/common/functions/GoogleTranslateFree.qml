pragma Singleton
import Quickshell

/**
 * The same key-less "gtx" endpoint translate-shell's Google engine talks to
 * (translate.googleapis.com/translate_a/single) - no service account, no Cloud project,
 * unlike GoogleCloud.qml/GCloudTranslate.qml. Used on Windows by both the sidebar
 * Translator and the screen translator, since neither `trans` nor GCloudVision/Translate
 * (which need a service account key) are available there.
 */
Singleton {
    id: root

    /// Translates `text` from `sourceLanguage` to `targetLanguage` (language codes, "auto"
    /// allowed) and calls `done` with the translation, or "" on failure. Returns the request,
    /// so a caller can abort() one that a newer request replaces.
    ///
    /// Through Qt's own network stack rather than curl.exe: Google answers Windows' curl.exe
    /// with its "unusual traffic" page, whatever the user agent, while this goes through.
    function translate(sourceLanguage: string, targetLanguage: string, text: string, done: var): var {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 0) return; // aborted, or no network: nothing to report
            done(xhr.status === 200 ? root.parseResponse(xhr.responseText) : "");
        };
        xhr.open("GET", "https://translate.googleapis.com/translate_a/single?client=gtx&dt=t"
            + `&sl=${encodeURIComponent(sourceLanguage)}&tl=${encodeURIComponent(targetLanguage)}`
            + `&q=${encodeURIComponent(text)}`);
        xhr.send();
        return xhr;
    }

    /// Parses the response: a nested JSON array, e.g. [[["Hola","Hello",null,null,1]],null,"en"].
    /// Returns "" (not throwing) on anything malformed, so callers can just check for an
    /// empty string.
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
