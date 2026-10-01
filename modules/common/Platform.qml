pragma Singleton

import Quickshell

/**
 * Tiny platform-detection singleton.
 *
 * ii is Linux-first; this fork adds a single, explicit switch so Linux-only
 * startup work (paths, Process/execDetached calls to bash and Linux CLIs)
 * can be guarded without scattering `Qt.platform.os` checks everywhere.
 * Real Windows backends for services land later - for now this just keeps
 * boot clean.
 */
Singleton {
    readonly property bool isWindows: Qt.platform.os === "windows"
}
