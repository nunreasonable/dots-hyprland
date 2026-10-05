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
        const hash = Qt.md5(expression)
        const imagePath = `${latexOutputPath}/${hash}.svg`
        
        // 2. Check if the hash is already processed
        if (processedHashes.includes(hash)) {
            // console.log("Already processed: " + hash)
            renderFinished(hash, imagePath)
            return [hash, false]
        } else {
            root.processedHashes.push(hash)
            root.processedExpressions[hash] = expression
            // console.log("Rendering expression: " + expression)
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

    // --- Windows ---------------------------------------------------------------------------
    //
    // ii-windows ships a cross-compiled MicroTeX (toolchain/microtex/LaTeX.exe, built against
    // the Qt backend instead of cairo/gtk - see docs/HANDOFF.md) next to matugen.exe in the
    // install dir. There's no native "application dir" accessor in QML (matugenPath() is the
    // only one, on Wallpaper), so the install dir is derived from it rather than adding one:
    // matugen.exe and LaTeX.exe are deployed as siblings by tools/deploy-ii.sh.
    //
    // Unlike the Linux branch, this spawns LaTeX.exe directly (no shell), so expression text
    // goes straight into the Process.command array with no quoting to get wrong - QProcess
    // builds the Win32 command line itself from that array.

    property Component _windowsProcessComponent: Component {
        Process {
            running: false
        }
    }

    function _requestRenderWindows(hash, expression, imagePath) {
        const matugenExe = WindowsNative.ready && WindowsNative.wallpaper ? WindowsNative.wallpaper.matugenPath() : ""
        if (!matugenExe) {
            // Dev build that hasn't run tools/deploy-ii.sh, or WindowsNative isn't ready yet:
            // behave like Linux does when MicroTeX isn't installed.
            console.warn("[LatexRenderer] can't locate the install dir (matugenPath() empty); skipping render")
            root.renderFinished(hash, imagePath)
            return
        }
        const installDir = matugenExe.substring(0, Math.max(matugenExe.lastIndexOf("/"), matugenExe.lastIndexOf("\\")))
        const exePath = `${installDir}/LaTeX.exe`

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
        proc.exited.connect((exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn(`[LatexRenderer] LaTeX.exe exited with code ${exitCode} for hash ${hash}`)
            }
            renderedImagePaths[hash] = imagePath
            root.renderFinished(hash, imagePath)
            proc.destroy()
        })
        proc.running = true
    }
}