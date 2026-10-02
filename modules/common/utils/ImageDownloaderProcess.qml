import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Process {
    id: root

    signal done(string path, int width, int height);
    required property string filePath;
    required property string sourceUrl;
    property string downloadUserAgent: Config.options?.networking.userAgent ?? ""
    
    function processFilePath() {
        return StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(filePath));
    }

    function processSourceUrl() {
        return StringUtils.shellSingleQuoteEscape(sourceUrl);
    }

    function curlUserAgentArg() {
        if (!downloadUserAgent) {
            return "";
        }
        return ` -H 'User-Agent: ${StringUtils.shellSingleQuoteEscape(downloadUserAgent)}'`;
    }

    // Windows: no bash/mkdir -p/`file`; curl.exe itself still exists, so mkdir the parent with
    // cmd and read the final image size with the native ImageTools helper instead of `file`.
    function rawFilePath() {
        return FileUtils.trimFileProtocol(filePath);
    }
    function rawParentDir() {
        return FileUtils.parentDirectory(rawFilePath());
    }
    function windowsUserAgentArg() {
        return downloadUserAgent ? ` -H "User-Agent: ${downloadUserAgent}"` : "";
    }

    running: true
    command: Platform.isWindows
        ? ["cmd", "/c", `if not exist "${rawParentDir()}" mkdir "${rawParentDir()}" & if not exist "${rawFilePath()}" curl -sSL "${root.sourceUrl}"${windowsUserAgentArg()} -o "${rawFilePath()}"`]
        : ["bash", "-c",
            `mkdir -p $(dirname '${processFilePath()}'); [ -f '${processFilePath()}' ] || curl -sSL '${processSourceUrl()}'${curlUserAgentArg()} -o '${processFilePath()}' && file '${processFilePath()}'`
        ]
    stdout: StdioCollector {
        id: imageSizeOutputCollector
        onStreamFinished: {
            if (Platform.isWindows) return; // handled in onExited below
            const output = imageSizeOutputCollector.text.trim();
            const match = output.match(/(\d+)\s*x\s*(\d+)/);

            if (match) {
                const width = Number(match[1]);
                const height = Number(match[2]);
                root.done(root.filePath, width, height);
            }
        }
    }
    onExited: (exitCode, exitStatus) => {
        if (!Platform.isWindows) return;
        const size = WindowsNative.imageTools?.imageSize(root.rawFilePath());
        if (size && size.width > 0 && size.height > 0) {
            root.done(root.filePath, size.width, size.height);
        }
    }
}
