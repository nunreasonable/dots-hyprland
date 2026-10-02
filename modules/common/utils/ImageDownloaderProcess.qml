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

    // Windows: no bash/mkdir -p/`file`. curl.exe ships with Windows and makes the parent
    // directory itself (--create-dirs); it is called directly because QProcess escapes quotes as
    // \" for C runtime parsing, which cmd.exe doesn't understand. The image size comes from the
    // native ImageTools helper instead of `file`.
    function rawFilePath() {
        return FileUtils.trimFileProtocol(filePath);
    }
    function windowsCommand() {
        if (WindowsNative.fsUtils?.classify(rawFilePath()) === "file") return ["cmd", "/c", "exit", "0"];
        const userAgent = downloadUserAgent ? ["-H", `User-Agent: ${downloadUserAgent}`] : [];
        return ["curl", "--create-dirs", "-sSL", root.sourceUrl, ...userAgent, "-o", rawFilePath()];
    }

    running: true
    command: Platform.isWindows
        ? windowsCommand()
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
