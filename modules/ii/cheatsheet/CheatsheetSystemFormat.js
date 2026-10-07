.pragma library

function isNum(v) {
    return typeof v === "number" && isFinite(v);
}

function dash(s) {
    return (s === undefined || s === null || s === "") ? "—" : s;
}

function clamp01(v) {
    if (!isNum(v)) return 0;
    return Math.max(0, Math.min(1, v));
}

function percentValue(v) {
    return isNum(v) ? Math.round(v * 100) : 0;
}

function percentString(v) {
    return isNum(v) ? (Math.round(v * 100) + "%") : "—";
}

function cpuName(name) {
    if (!name) return name;
    return name.replace(/\((R|TM|tm|r)\)/g, "")
        .replace(/^\s*\d+(st|nd|rd|th) Gen\s+/i, "")
        .replace(/\s+CPU\s+@.*$/i, "")
        .replace(/\s+/g, " ")
        .trim();
}

function ghzString(mhz, digits) {
    if (!isNum(mhz)) return "—";
    const d = (digits === undefined) ? 2 : digits;
    return (mhz / 1000).toFixed(d) + " GHz";
}

function ghzNumber(mhz, digits) {
    if (!isNum(mhz)) return "—";
    const d = (digits === undefined) ? 1 : digits;
    return (mhz / 1000).toFixed(d);
}

function mhzString(mhz) {
    return isNum(mhz) ? (Math.round(mhz) + " MHz") : "—";
}

function celsiusValue(c) {
    return isNum(c) ? Math.round(c) : null;
}

function celsiusString(c) {
    return isNum(c) ? (Math.round(c) + "°C") : "—";
}

function wattsString(w) {
    return isNum(w) ? (Math.round(w) + " W") : "—";
}

function bytesToGiB(bytes) {
    return bytes / (1024 * 1024 * 1024);
}

function sizeString(bytes, digits) {
    if (!isNum(bytes) || bytes < 0) return "—";
    const d = (digits === undefined) ? 1 : digits;
    const gib = bytesToGiB(bytes);
    if (gib >= 1000) return (gib / 1024).toFixed(d) + " TB";
    return gib.toFixed(d) + " GB";
}

function usedTotalString(used, total, digits) {
    if (!isNum(used) || !isNum(total) || total <= 0) return "— / —";
    const d = (digits === undefined) ? 1 : digits;
    return sizeString(used, d) + " / " + sizeString(total, d);
}

function ratio(used, total) {
    if (!isNum(used) || !isNum(total) || total <= 0) return 0;
    return clamp01(used / total);
}

function mibString(bytes) {
    if (!isNum(bytes) || bytes <= 0) return "—";
    return Math.round(bytes / (1024 * 1024)) + " MiB";
}

function diskIcon(kind) {
    switch (kind) {
    case "NVMe SSD":
        return "sd_storage";
    case "SSD":
        return "sd_storage";
    case "HDD":
        return "storage";
    case "USB":
        return "usb";
    case "Removable":
        return "usb";
    default:
        return "save";
    }
}

function durationParts(totalSeconds) {
    if (!isNum(totalSeconds) || totalSeconds < 0) return null;
    let s = Math.floor(totalSeconds);
    const days = Math.floor(s / 86400);
    s %= 86400;
    const hours = Math.floor(s / 3600);
    s %= 3600;
    const minutes = Math.floor(s / 60);
    const out = [];
    if (days > 0) out.push(days + "d");
    if (days > 0 || hours > 0) out.push(hours + "h");
    out.push(minutes + "m");
    return out.join(" ");
}
