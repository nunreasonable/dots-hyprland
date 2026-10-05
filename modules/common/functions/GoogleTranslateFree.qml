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

    /// Builds the curl.exe argv for translating `text` from `sourceLanguage` to
    /// `targetLanguage` (language codes, "auto" allowed for source). Passed straight to
    /// Process.command: each value is its own argument, so cmd's quote-escaping rule
    /// (see AGENTS.md) never comes into play.
    function requestArgs(sourceLanguage: string, targetLanguage: string, text: string): list<string> {
        // `--data-urlencode` (not plain `-d`) for `q`: curl's own URL parser rejects a raw
        // space in the assembled URL, and -G/-d doesn't encode values for you.
        return ["curl.exe", "-s", "-G", "https://translate.googleapis.com/translate_a/single",
            "-d", "client=gtx", "-d", "dt=t",
            "-d", `sl=${sourceLanguage}`, "-d", `tl=${targetLanguage}`,
            "--data-urlencode", `q=${text}`];
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
