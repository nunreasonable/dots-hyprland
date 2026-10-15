pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common.functions
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Renders LaTeX snippets with MicroTeX.
 * For every request:
 *   1. Hash it
 *   2. Check if the hash is already processed
 *   3. If not, render it with MicroTeX and mark as processed
 */
Singleton {
    id: root
    
    readonly property var renderPadding: 4 // This is to prevent cutoff in the rendered images

    property list<string> processedHashes: []
    property var processedExpressions: ({})
    property var renderedImagePaths: ({})
    readonly property int maxEntries: 300

    function _remember(hash, expression) {
        const index = root.processedHashes.indexOf(hash)
        if (index !== -1) root.processedHashes.splice(index, 1)
        root.processedHashes.push(hash)
        root.processedExpressions[hash] = expression
        while (root.processedHashes.length > root.maxEntries) {
            const evicted = root.processedHashes.shift()
            delete root.processedExpressions[evicted]
            delete root.renderedImagePaths[evicted]
        }
    }

    function _forget(hash) {
        const index = root.processedHashes.indexOf(hash)
        if (index !== -1) root.processedHashes.splice(index, 1)
        delete root.processedExpressions[hash]
        delete root.renderedImagePaths[hash]
    }
    property string microtexBinaryDir: "/opt/MicroTeX"
    property string microtexBinaryName: "LaTeX"
    property string latexOutputPath: Directories.latexOutput

    signal renderFinished(string hash, string imagePath)

    /**
    * Requests rendering of a LaTeX expression.
    * Returns the [hash, isNew]
    */
    function requestRender(expression) {
        // 1. Hash it and initialize necessary variables
        const hash = Qt.md5(`${expression}|${Appearance.colors.colOnLayer1}|${Appearance.font.pixelSize.normal}`)
        const imagePath = `${latexOutputPath}/${hash}.svg`
        
        // 2. Check if the hash is already processed
        if (root.processedExpressions[hash] !== undefined) {
            // console.log("Already processed: " + hash)
            root._remember(hash, expression)
            renderFinished(hash, imagePath)
            return [hash, false]
        } else {
            root._remember(hash, expression)
            // console.log("Rendering expression: " + expression)
        }

        if (Platform.isWindows && WindowsNative.fsUtils?.classify(imagePath) === "file") {
            root.renderedImagePaths[hash] = imagePath
            Qt.callLater(() => root.renderFinished(hash, imagePath))
            return [hash, false]
        }

        if (Platform.isWindows) {
            root._requestRenderWindows(hash, expression, imagePath)
            return [hash, true]
        }

        // 3. If not, render it with MicroTeX and mark as processed
        // console.log(`[LatexRenderer] Rendering expression: ${expression} with hash: ${hash}`)
        // console.log(`                to file: ${imagePath}`)
        // console.log(`                with command: cd ${microtexBinaryDir} && ./${microtexBinaryName} -headless -input=${StringUtils.shellSingleQuoteEscape(expression)} -output=${imagePath} -textsize=${Appearance.font.pixelSize.normal} -padding=${renderPadding} -background=${Appearance.m3colors.m3tertiary} -foreground=${Appearance.m3colors.m3onTertiary} -maxwidth=0.85`)
        const processQml = `
            import Quickshell.Io
            Process {
                id: microtexProcess${hash}
                running: true
                command: [ "bash", "-c", 
                    "cd ${root.microtexBinaryDir} && ./${root.microtexBinaryName} -headless '-input=${StringUtils.shellSingleQuoteEscape(StringUtils.escapeBackslashes(expression))}' "
                    + "'-output=${imagePath}' " 
                    + "'-textsize=${Appearance.font.pixelSize.normal}' "
                    + "'-padding=${renderPadding}' "
                    // + "'-background=${Appearance.m3colors.m3tertiary}' "
                    + "'-foreground=${Appearance.colors.colOnLayer1}' "
                    + "-maxwidth=0.85 "
                ]
                // stdout: SplitParser {
                //     onRead: data => { console.log("MicroTeX: " + data) }
                // }
                onExited: (exitCode, exitStatus) => {
                    // console.log("[LatexRenderer] MicroTeX process exited with code: " + exitCode + ", status: " + exitStatus)
                    renderedImagePaths["${hash}"] = "${imagePath}"
                    root.renderFinished("${hash}", "${imagePath}")
                    microtexProcess${hash}.destroy()
                }
            }
        `
        // console.log("MicroTeX: " + processQml)
        Qt.createQmlObject(processQml, root, `MicroTeXProcess_${hash}`)
        return [hash, true]
    }

    property Component _windowsProcessComponent: Component {
        Process {
            running: false
        }
    }

    property bool _windowsOutputDirReady: false

    function _ensureWindowsOutputDir() {
        if (root._windowsOutputDirReady) return
        root._windowsOutputDirReady = true
        const fs = WindowsNative.fsUtils
        if (fs && typeof fs.makePath === "function") {
            fs.makePath(root.latexOutputPath)
            return
        }
        Quickshell.execDetached(["powershell", "-NoProfile", "-Command",
            `New-Item -ItemType Directory -Force -Path "${root.latexOutputPath}" | Out-Null`])
    }

    function _requestRenderWindows(hash, expression, imagePath) {
        const matugenExe = WindowsNative.ready && WindowsNative.wallpaper ? WindowsNative.wallpaper.matugenPath() : ""
        if (!matugenExe) {
            root._forget(hash)
            console.warn("[LatexRenderer] can't locate the install dir (matugenPath() empty); will retry")
            root.renderFinished(hash, imagePath)
            return
        }
        const installDir = matugenExe.substring(0, Math.max(matugenExe.lastIndexOf("/"), matugenExe.lastIndexOf("\\")))
        const exePath = `${installDir}/LaTeX.exe`
        root._ensureWindowsOutputDir()

        const proc = root._windowsProcessComponent.createObject(root, {
            command: [
                exePath,
                "-headless",
                `-input=${expression}`,
                `-output=${imagePath}`,
                `-textsize=${Appearance.font.pixelSize.normal}`,
                `-padding=${renderPadding}`,
                `-foreground=${Appearance.colors.colOnLayer1}`,
                "-maxwidth=0.85",
            ],
            workingDirectory: installDir,
        })

        let _finished = false
        const finish = () => {
            if (_finished) return
            _finished = true
            renderedImagePaths[hash] = imagePath
            root.renderFinished(hash, imagePath)
            proc.destroy()
        }
        proc.exited.connect((exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn(`[LatexRenderer] LaTeX.exe exited with code ${exitCode} for hash ${hash}`)
            }
            finish()
        })
        proc.runningChanged.connect(() => {
            if (!proc.running && !_finished) {
                console.warn(`[LatexRenderer] LaTeX.exe failed to start for hash ${hash} (missing/broken deploy?)`)
                finish()
            }
        })
        proc.running = true
    }
}