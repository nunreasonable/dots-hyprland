pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property QtObject blendedColors: Appearance.colors
    property MprisPlayer player: null
    property string displayedArtFilePath: ""
    signal closeRequested()

    property var bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property string presetName: "Flat"
    property string editingCustomPresetName: ""
    property bool pending: false
    readonly property var bandLabels: ["32", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property real bandRange: 12
    property real preamp: 0
    readonly property real preampRange: 12

    property real dimAmount: 0.3
    readonly property real dimAmountMax: 0.85
    property bool dimExpanded: false

    readonly property int itemSpacing: 6
    readonly property int sectionSpacing: 10
    readonly property int pageSpacing: 16

    readonly property int panelRadius: Appearance.rounding.normal
    readonly property int panelPadding: 16
    readonly property color panelColor: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.55)
    readonly property color panelBorderColor: ColorUtils.transparentize(root.blendedColors.colSubtext, 0.88)

    readonly property var presetValues: ({
        "Flat":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":    [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
        "Treble":  [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
        "Vocal":   [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
        "Pop":     [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
        "Rock":    [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
        "Jazz":    [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
        "Classic": [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]
    })
    readonly property var presetIcons: ({
        "Flat": "horizontal_rule", "Bass": "graphic_eq", "Treble": "trending_up",
        "Vocal": "mic", "Pop": "star", "Rock": "bolt", "Jazz": "piano", "Classic": "music_note"
    })

    readonly property bool autoEnabled: EqualizerAutoService.autoEnabled

    readonly property QtObject apo: Platform.isWindows ? WindowsNative.equalizer : null
    readonly property bool apoInstalled: !!root.apo && root.apo.installed
    readonly property bool apoActiveOnDevice: !!root.apo && root.apo.activeOnDefaultDevice
    readonly property bool apoHooked: !!root.apo && root.apo.hooked
    readonly property bool apoUiReady: !Platform.isWindows || (root.apoInstalled && root.apoActiveOnDevice && root.apoHooked)
    readonly property bool apoBypassed: Platform.isWindows && EqualizerApoBackend.bypassed
    readonly property var oemAudioApps: Platform.isWindows ? OemAudioApps.installed() : []

    function toggleBypass() {
        if (!Platform.isWindows) return
        EqualizerApoBackend.toggleBypass()
    }

    property string lastfmKey: ""
    property bool showLastfmKeyDialog: false
    property bool lastfmKeyRevealed: false
    property bool needsManualSave: false
    property var customPresets: ({})
    property bool showSaveDialog: false
    property bool pendingSaveRowScroll: false
    onShowSaveDialogChanged: {
        if (root.showSaveDialog) {
            newPresetNameField.text = ""
            newPresetNameField.forceActiveFocus()
            root.pendingSaveRowScroll = true
        } else {
            newPresetNameField.focus = false
            root.pendingSaveRowScroll = false
        }
    }
    property bool customEditMode: false

    property string activePreset: "output"
    property var availablePresets: []
    property bool showActivePresetDialog: false
    property string pendingNewPresetName: ""
    property bool activePresetEditMode: false
    property string pendingDeletePresetName: ""
    onShowActivePresetDialogChanged: {
        if (root.showActivePresetDialog) {
            activePresetField.text = root.activePreset
            activePresetField.forceActiveFocus()
            root.refreshAvailablePresets()
        } else {
            activePresetField.focus = false
            root.pendingNewPresetName = ""
            root.activePresetEditMode = false
            root.pendingDeletePresetName = ""
        }
    }

    function bandAccentColor(index) {
        const t = root.bandLabels.length > 1 ? index / (root.bandLabels.length - 1) : 0
        return ColorUtils.mix(root.blendedColors.colPrimary, root.blendedColors.colSecondary, t)
    }

    function refresh() {
        if (Platform.isWindows) {
            root.bands = EqualizerApoBackend.bands.slice()
            root.presetName = EqualizerApoBackend.presetName
            if (Object.prototype.hasOwnProperty.call(root.customPresets, root.presetName))
                root.editingCustomPresetName = root.presetName
            EqualizerAutoService.currentPresetName = root.presetName
            root.pending = EqualizerApoBackend.pending
            root.preamp = EqualizerApoBackend.preamp
            root.dimAmount = EqualizerApoBackend.dim
            return
        }
        eqGetProc.running = false
        eqGetProc.running = true
    }

    function setBand(index, value) {
        root.bands[index] = value
        root.bandsChanged()
        root.presetName = "Custom"
        EqualizerAutoService.currentPresetName = "Custom"
        root.pending = true
        if (Platform.isWindows) {
            EqualizerApoBackend.setBand(index, value)
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "set_band", String(index + 1), String(Math.round(value))])
        }
        liveApplyTimer.restart()
    }

    function setPreamp(value) {
        root.preamp = value
        root.pending = true
        if (Platform.isWindows) {
            EqualizerApoBackend.setPreamp(value)
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "set_preamp", String(Math.round(value))])
        }
        liveApplyTimer.restart()
    }

    function setDim(value) {
        root.dimAmount = value
        if (Platform.isWindows) {
            EqualizerApoBackend.setDim(value)
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "set_dim", String(value)])
        }
    }

    function saveChanges() {
        if (Platform.isWindows) {
            EqualizerApoBackend.saveChanges()
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "save"])
        }
        root.pending = false
        needsSaveRecheckTimer.restart()
    }

    function previewChanges() {
        Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "preview"])
    }

    Timer {
        id: liveApplyTimer
        interval: 160
        repeat: false
        onTriggered: {
            if (Platform.isWindows) root.pending = false
            else root.previewChanges()
        }
    }

    function applyPreset(name) {
        const vals = root.presetValues[name]
        if (vals) root.bands = vals.slice()
        root.presetName = name
        root.editingCustomPresetName = ""
        EqualizerAutoService.currentPresetName = name
        root.pending = false
        if (Platform.isWindows) {
            EqualizerApoBackend.applyPreset(name)
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "preset", name])
            needsSaveRecheckTimer.restart()
        }
    }

    function refreshNeedsSave() {
        if (Platform.isWindows) return
        eqGetNeedsSaveProc.running = false
        eqGetNeedsSaveProc.running = true
    }

    function refreshLastfmKey() {
        if (Platform.isWindows) {
            root.lastfmKey = EqualizerApoBackend.lastfmKey
            return
        }
        eqGetLastfmKeyProc.running = false
        eqGetLastfmKeyProc.running = true
    }

    function saveLastfmKey(key) {
        const trimmed = key.trim()
        root.lastfmKey = trimmed
        if (Platform.isWindows) {
            EqualizerApoBackend.setLastfmKey(trimmed)
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "set_lastfm_key", trimmed])
        }
        root.showLastfmKeyDialog = false
        EqualizerAutoService.lastLookupKey = ""
        EqualizerAutoService.maybeLookupGenre()
    }

    function toggleAuto() {
        const goingOn = !EqualizerAutoService.autoEnabled
        EqualizerAutoService.toggleAuto()
        if (goingOn && root.lastfmKey.length === 0) root.showLastfmKeyDialog = true
    }

    function refreshCustomPresets() {
        if (Platform.isWindows) {
            root.customPresets = Object.assign({}, EqualizerApoBackend.customPresets)
            if (Object.prototype.hasOwnProperty.call(root.customPresets, root.presetName))
                root.editingCustomPresetName = root.presetName
            return
        }
        eqGetCustomProc.running = false
        eqGetCustomProc.running = true
    }

    function applyCustomPreset(name) {
        const vals = root.customPresets[name]
        if (vals) root.bands = vals.slice()
        root.presetName = name
        root.editingCustomPresetName = name
        EqualizerAutoService.currentPresetName = name
        root.pending = false
        if (Platform.isWindows) {
            EqualizerApoBackend.applyCustomPreset(name)
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "preset", name])
            needsSaveRecheckTimer.restart()
        }
    }

    function saveCustomPreset(name) {
        const trimmed = name.trim()
        if (!trimmed) return
        if (Platform.isWindows) {
            EqualizerApoBackend.saveCustomPreset(trimmed)
        } else {
            const args = ["bash", Directories.eqScriptPath, Directories.eqStateDir, "save_custom", trimmed]
            for (const v of root.bands) args.push(String(Math.round(v)))
            Quickshell.execDetached(args)
        }
        const updated = Object.assign({}, root.customPresets)
        updated[trimmed] = root.bands.slice()
        root.customPresets = updated
        root.presetName = trimmed
        root.editingCustomPresetName = trimmed
        root.pending = false
        EqualizerAutoService.currentPresetName = trimmed
        root.showSaveDialog = false
        if (!Platform.isWindows) needsSaveRecheckTimer.restart()
    }

    function deleteCustomPreset(name) {
        if (Platform.isWindows) {
            EqualizerApoBackend.deleteCustomPreset(name)
        } else {
            Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "delete_custom", name])
        }
        const updated = Object.assign({}, root.customPresets)
        delete updated[name]
        root.customPresets = updated
        if (root.presetName === name) {
            root.presetName = "Custom"
            root.editingCustomPresetName = ""
            EqualizerAutoService.currentPresetName = "Custom"
        }
    }

    function refreshActivePreset() {
        eqGetActivePresetProc.running = false
        eqGetActivePresetProc.running = true
    }

    function refreshAvailablePresets() {
        eqListPresetsProc.running = false
        eqListPresetsProc.running = true
    }

    function setActivePreset(name) {
        const trimmed = name.trim()
        if (!trimmed) return
        if (root.availablePresets.indexOf(trimmed) === -1) {
            root.pendingNewPresetName = trimmed
            return
        }
        root.activePreset = trimmed
        root.showActivePresetDialog = false
        root.pendingNewPresetName = ""
        Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "set_active_preset", trimmed])
        needsSaveRecheckTimer.restart()
        root.refreshAvailablePresets()
    }

    function createActivePreset(name) {
        const trimmed = name.trim()
        if (!trimmed) return
        root.activePreset = trimmed
        root.showActivePresetDialog = false
        root.pendingNewPresetName = ""
        Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "create_preset", trimmed])
        needsSaveRecheckTimer.restart()
        root.refreshAvailablePresets()
    }

    function requestDeleteEasyEffectsPreset(name) {
        if (name === root.activePreset) return
        root.pendingDeletePresetName = name
    }

    function deleteEasyEffectsPreset(name) {
        if (name === root.activePreset) return
        Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "delete_preset", name])
        root.availablePresets = root.availablePresets.filter(p => p !== name)
        root.pendingDeletePresetName = ""
    }

    Timer {
        id: needsSaveRecheckTimer
        interval: 350
        onTriggered: root.refreshNeedsSave()
    }

    Connections {
        target: EqualizerAutoService
        function onCurrentPresetNameChanged() {
            const name = EqualizerAutoService.currentPresetName
            const vals = root.presetValues[name]
            if (vals) {
                root.bands = vals.slice()
                root.presetName = name
                root.pending = false
                needsSaveRecheckTimer.restart()
            }
        }
    }

    Component.onCompleted: {
        if (Platform.isWindows) root.apo?.refresh()
        root.refresh()
        root.refreshLastfmKey()
        root.refreshCustomPresets()
        root.refreshNeedsSave()
        if (!Platform.isWindows) {
            root.refreshActivePreset()
            root.refreshAvailablePresets()
        }
    }

    Timer {
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Connections {
        target: GlobalStates
        function onEqualizerOpenChanged() {
            if (!GlobalStates.equalizerOpen) {
                root.dimExpanded = false
                if (root.pending) {
                    liveApplyTimer.stop()
                    if (Platform.isWindows) root.pending = false
                    else Quickshell.execDetached(["bash", Directories.eqScriptPath, Directories.eqStateDir, "revert_preview"])
                }
            }
        }
    }

    Process {
        id: eqGetProc
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    root.bands = [
                    Number(data.b1), Number(data.b2), Number(data.b3), Number(data.b4), Number(data.b5),
                    Number(data.b6), Number(data.b7), Number(data.b8), Number(data.b9), Number(data.b10)
                    ]
                    root.presetName = data.preset ?? "Custom"
                    if (Object.prototype.hasOwnProperty.call(root.customPresets, root.presetName))
                        root.editingCustomPresetName = root.presetName
                    EqualizerAutoService.currentPresetName = root.presetName
                    root.pending = !!data.pending
                    root.preamp = Number(data.preamp) || 0
                    if (data.dim !== undefined && data.dim !== null && !isNaN(Number(data.dim)))
                        root.dimAmount = Number(data.dim)
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: eqGetLastfmKeyProc
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "get_lastfm_key"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.lastfmKey = text.trim()
            }
        }
    }

    Process {
        id: eqGetNeedsSaveProc
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "get_needs_save"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                root.needsManualSave = (t === "true" || t === "1")
            }
        }
    }

    Process {
        id: eqGetCustomProc
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "get_custom"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text)
                    const parsed = {}
                    for (const name in data) {
                        const b = data[name]
                        parsed[name] = [b.b1, b.b2, b.b3, b.b4, b.b5, b.b6, b.b7, b.b8, b.b9, b.b10].map(Number)
                    }
                    root.customPresets = parsed
                    if (Object.prototype.hasOwnProperty.call(parsed, root.presetName))
                        root.editingCustomPresetName = root.presetName
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: eqGetActivePresetProc
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "get_active_preset"]
        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim()
                root.activePreset = trimmed.length > 0 ? trimmed : "output"
            }
        }
    }

    Process {
        id: eqListPresetsProc
        command: ["bash", Directories.eqScriptPath, Directories.eqStateDir, "list_presets"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.availablePresets = JSON.parse(text)
                } catch (e) {
                    root.availablePresets = []
                }
            }
        }
    }

    component PillChip: RippleButton {
        id: chip
        property bool chipToggled: false
        buttonRadius: Appearance.rounding.full
        colBackground: ColorUtils.transparentize(root.blendedColors.colLayer1, chipToggled ? 1 : 0.35)
        colBackgroundHover: ColorUtils.mix(root.blendedColors.colLayer1, root.blendedColors.colOnLayer1, 0.92)
        colBackgroundToggled: root.blendedColors.colPrimary
        colBackgroundToggledHover: root.blendedColors.colPrimaryHover
        colRipple: ColorUtils.mix(root.blendedColors.colLayer1, root.blendedColors.colOnLayer1, 0.85)
        colRippleToggled: root.blendedColors.colPrimaryActive
        toggled: chipToggled
    }

    component TransportButton: RippleButton {
        implicitWidth: 24
        implicitHeight: 24
        property var iconName
        colBackground: ColorUtils.transparentize(root.blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: root.blendedColors.colSecondaryContainerHover
        colRipple: root.blendedColors.colSecondaryContainerActive
        contentItem: MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: root.blendedColors.colOnSecondaryContainer
            text: iconName
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    component Panel: Rectangle {
        radius: root.panelRadius
        color: root.panelColor
        border.width: 1
        border.color: root.panelBorderColor

        Behavior on color {
            ColorAnimation { duration: 420; easing.type: Easing.OutCubic }
        }
        Behavior on border.color {
            ColorAnimation { duration: 420; easing.type: Easing.OutCubic }
        }
    }

    component PanelHeader: StyledText {
        Layout.fillWidth: true
        font.pixelSize: Appearance.font.pixelSize.small
        font.bold: true
        color: root.blendedColors.colSubtext
    }

    component BandCell: RowLayout {
        id: cell
        required property int index
        spacing: root.itemSpacing

        readonly property color accent: root.bandAccentColor(cell.index)

        StyledText {
            Layout.preferredWidth: 26
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.features: { "tnum": 1 }
            color: root.blendedColors.colSubtext
            text: root.bandLabels[cell.index]
        }

        StyledSlider {
            id: bandSlider
            Layout.fillWidth: true
            Layout.fillHeight: true
            configuration: StyledSlider.Configuration.M
            from: -root.bandRange
            to: root.bandRange
            value: root.bands[cell.index] ?? 0
            highlightColor: cell.accent
            trackColor: ColorUtils.transparentize(cell.accent, 0.85)
            handleColor: cell.accent
            stopIndicatorValues: [0]
            dotColor: root.blendedColors.colOnLayer1
            dotColorHighlighted: root.blendedColors.colOnPrimary
            usePercentTooltip: false
            tooltipContent: `${Math.round(value) > 0 ? "+" : ""}${Math.round(value)} dB`
            onMoved: root.setBand(cell.index, value)

            Behavior on value {
                enabled: !bandSlider.pressed
                NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
            }
        }

        StyledText {
            Layout.preferredWidth: 28
            horizontalAlignment: Text.AlignRight
            font.pixelSize: Appearance.font.pixelSize.smallest
            font.features: { "tnum": 1 }
            color: cell.accent
            text: `${Math.round(root.bands[cell.index] ?? 0) > 0 ? "+" : ""}${Math.round(root.bands[cell.index] ?? 0)}`
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 22
        spacing: root.pageSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            MaterialShapeWrappedMaterialSymbol {
                wrappedShape: MaterialShape.Shape.Cookie6Sided
                text: "equalizer"
                fill: 1
                iconSize: Appearance.font.pixelSize.large
                padding: 9
                color: ColorUtils.transparentize(root.blendedColors.colPrimary, 0.85)
                colSymbol: root.blendedColors.colPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.bold: true
                    color: root.blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: Translation.tr("Equalizer")
                }
                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: `${Translation.tr("Preset")}: ${root.presetName}`
                }
            }

            PillChip {
                id: dimChip
                implicitWidth: 34
                implicitHeight: 34
                chipToggled: root.dimExpanded
                downAction: () => root.dimExpanded = !root.dimExpanded
                contentItem: Item {
                    anchors.fill: parent
                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.large
                        fill: root.dimExpanded ? 1 : 0
                        horizontalAlignment: Text.AlignHCenter
                        color: root.dimExpanded ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                        text: "contrast"
                    }
                }
            }

            Item {
                id: dimSliderWrap
                Layout.preferredWidth: root.dimExpanded ? 110 : 0
                Layout.preferredHeight: 34
                clip: true
                opacity: root.dimExpanded ? 1 : 0

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: root.dimExpanded ? 220 : 120; easing.type: Easing.OutCubic }
                }

                StyledSlider {
                    id: dimSlider
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    configuration: StyledSlider.Configuration.M
                    from: 0
                    to: root.dimAmountMax
                    value: root.dimAmount
                    highlightColor: root.blendedColors.colPrimary
                    trackColor: ColorUtils.transparentize(root.blendedColors.colPrimary, 0.85)
                    stopIndicatorValues: []
                    handleColor: root.blendedColors.colPrimary
                    usePercentTooltip: true
                    onMoved: root.setDim(value)

                    Behavior on value {
                        enabled: !dimSlider.pressed
                        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                    }
                }
            }

            PillChip {
                implicitHeight: 34
                Layout.preferredWidth: autoLabel.implicitWidth + 40
                visible: !Platform.isWindows || root.apoUiReady
                chipToggled: root.autoEnabled
                downAction: () => root.toggleAuto()
                contentItem: Item {
                    anchors.fill: parent
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            iconSize: Appearance.font.pixelSize.smaller
                            fill: root.autoEnabled ? 1 : 0
                            text: "auto_awesome"
                            color: root.autoEnabled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                        }
                        StyledText {
                            id: autoLabel
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            text: Translation.tr("Auto")
                            color: root.autoEnabled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                        }
                    }
                }
            }

            PillChip {
                implicitWidth: 34
                implicitHeight: 34
                visible: Platform.isWindows
                chipToggled: !root.apoBypassed
                downAction: () => root.toggleBypass()
                contentItem: Item {
                    anchors.fill: parent
                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.large
                        fill: root.apoBypassed ? 0 : 1
                        horizontalAlignment: Text.AlignHCenter
                        color: root.apoBypassed ? root.blendedColors.colOnLayer1 : root.blendedColors.colOnPrimary
                        text: root.apoBypassed ? "power_off" : "power"
                    }
                }
            }

            PillChip {
                implicitWidth: 34
                implicitHeight: 34
                visible: !Platform.isWindows || root.apoUiReady
                chipToggled: root.showLastfmKeyDialog
                downAction: () => root.showLastfmKeyDialog = !root.showLastfmKeyDialog
                contentItem: Item {
                    anchors.fill: parent
                    MaterialSymbol {
                        anchors.centerIn: parent
                        iconSize: Appearance.font.pixelSize.large
                        fill: root.lastfmKey.length > 0 ? 1 : 0
                        horizontalAlignment: Text.AlignHCenter
                        color: root.showLastfmKeyDialog ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                        text: "key"
                    }
                }
            }

            PillChip {
                implicitWidth: 34
                implicitHeight: 34
                downAction: () => root.applyPreset("Flat")
                contentItem: MaterialSymbol {
                    iconSize: Appearance.font.pixelSize.large
                    fill: 0
                    horizontalAlignment: Text.AlignHCenter
                    color: root.blendedColors.colOnLayer1
                    text: "refresh"
                }
            }

            PillChip {
                implicitWidth: 34
                implicitHeight: 34
                downAction: () => root.closeRequested()
                contentItem: MaterialSymbol {
                    iconSize: Appearance.font.pixelSize.large
                    fill: 1
                    horizontalAlignment: Text.AlignHCenter
                    color: root.blendedColors.colOnLayer1
                    text: "close"
                }
            }
        }
        Rectangle {
            Layout.fillWidth: false
            visible: root.autoEnabled && root.lastfmKey.length === 0
            implicitWidth: lastfmHintRow.implicitWidth + 16
            implicitHeight: lastfmHintRow.implicitHeight + 16
            radius: Appearance.rounding.normal
            color: ColorUtils.transparentize(root.blendedColors.colPrimary, 0.85)

            RowLayout {
                id: lastfmHintRow
                anchors.centerIn: parent
                spacing: 6

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    iconSize: Appearance.font.pixelSize.normal
                    fill: 0
                    text: "info"
                    color: root.blendedColors.colPrimary
                }
                StyledText {
                    id: lastfmHintText
                    Layout.alignment: Qt.AlignVCenter
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.blendedColors.colOnLayer1
                    text: Translation.tr("Auto needs a Last.fm API key to look up genres. Get one free and paste it in the key field above.")
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.showLastfmKeyDialog = true
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.showLastfmKeyDialog
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Appearance.rounding.normal
                color: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.35)
                border.width: lastfmKeyField.activeFocus ? 1 : 0
                border.color: root.blendedColors.colPrimary

                TextInput {
                    id: lastfmKeyField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 34
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.blendedColors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    clip: true
                    echoMode: root.lastfmKeyRevealed ? TextInput.Normal : TextInput.Password
                    text: root.lastfmKey
                    onAccepted: root.saveLastfmKey(text)
                    Keys.onEscapePressed: { root.showLastfmKeyDialog = false }

                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        visible: lastfmKeyField.text.length === 0
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.blendedColors.colSubtext
                        text: Translation.tr("Paste Last.fm API key\u2026")
                    }
                }

                MaterialSymbol {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: Appearance.font.pixelSize.normal
                    fill: root.lastfmKeyRevealed ? 1 : 0
                    text: root.lastfmKeyRevealed ? "visibility_off" : "visibility"
                    color: root.blendedColors.colSubtext

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.lastfmKeyRevealed = !root.lastfmKeyRevealed
                    }
                }
            }
            PillChip {
                implicitWidth: 32
                implicitHeight: 32
                chipToggled: true
                downAction: () => root.saveLastfmKey(lastfmKeyField.text)
                contentItem: MaterialSymbol {
                    iconSize: Appearance.font.pixelSize.normal
                    fill: 1
                    horizontalAlignment: Text.AlignHCenter
                    text: "check"
                    color: root.blendedColors.colOnPrimary
                }
            }
            PillChip {
                implicitWidth: 32
                implicitHeight: 32
                visible: root.lastfmKey.length > 0
                downAction: () => { lastfmKeyField.text = ""; root.saveLastfmKey("") }
                contentItem: MaterialSymbol {
                    iconSize: Appearance.font.pixelSize.normal
                    fill: 0
                    horizontalAlignment: Text.AlignHCenter
                    text: "delete"
                    color: root.blendedColors.colOnLayer1
                }
            }
        }
        RowLayout {
            id: bodyRow
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.apoUiReady
            spacing: root.sectionSpacing

            Panel {
                id: railPanel
                Layout.fillWidth: false
                Layout.preferredWidth: Math.round(bodyRow.width * 0.34)
                Layout.fillHeight: true

                ColumnLayout {
                    id: railPanelColumn
                    anchors.fill: parent
                    anchors.margins: root.panelPadding
                    spacing: root.sectionSpacing

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Flickable {
                            id: railFlick
                            anchors.fill: parent
                            anchors.rightMargin: 10
                            clip: true
                            contentWidth: width
                            contentHeight: railColumn.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds

                            onContentHeightChanged: {
                                if (!root.pendingSaveRowScroll) return
                                if (railFlick.contentHeight > railFlick.height) {
                                    railFlick.contentY = railFlick.contentHeight - railFlick.height
                                    root.pendingSaveRowScroll = false
                                }
                            }

                            ColumnLayout {
                                id: railColumn
                                width: railFlick.width
                                spacing: root.sectionSpacing

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: root.sectionSpacing
                                    visible: root.player !== null

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        Rectangle {
                                            id: nowPlayingArt
                                            Layout.preferredWidth: 46
                                            Layout.preferredHeight: 46
                                            color: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.5)

                                            layer.enabled: true
                                            layer.effect: OpacityMask {
                                                maskSource: MaterialShape {
                                                    shape: MaterialShape.Shape.Bun
                                                    implicitSize: nowPlayingArt.width
                                                }
                                            }

                                            StyledImage {
                                                anchors.fill: parent
                                                source: root.displayedArtFilePath
                                                sourceSize.width: nowPlayingArt.width * 2
                                                sourceSize.height: nowPlayingArt.height * 2
                                                fillMode: Image.PreserveAspectCrop
                                                cache: false
                                                antialiasing: true
                                                visible: root.displayedArtFilePath.length > 0
                                            }
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                iconSize: Appearance.font.pixelSize.huge
                                                fill: 1
                                                text: "music_note"
                                                color: root.blendedColors.colOnLayer1
                                                visible: root.displayedArtFilePath.length === 0
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            StyledText {
                                                Layout.fillWidth: true
                                                font.pixelSize: Appearance.font.pixelSize.small
                                                font.bold: true
                                                color: root.blendedColors.colOnLayer0
                                                elide: Text.ElideRight
                                                text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || Translation.tr("Untitled")
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: root.blendedColors.colSubtext
                                                elide: Text.ElideRight
                                                text: root.player?.trackArtist ?? ""
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        TransportButton {
                                            iconName: "skip_previous"
                                            downAction: () => root.player?.previous()
                                        }

                                        RippleButton {
                                            id: playPauseButton
                                            Layout.fillWidth: true
                                            implicitHeight: 32
                                            downAction: () => root.player?.togglePlaying()
                                            buttonRadius: (root.player?.isPlaying ?? false) ? Appearance.rounding.normal : Appearance.rounding.full
                                            colBackground: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimary : root.blendedColors.colSecondaryContainer
                                            colBackgroundHover: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryHover : root.blendedColors.colSecondaryContainerHover
                                            colRipple: (root.player?.isPlaying ?? false) ? root.blendedColors.colPrimaryActive : root.blendedColors.colSecondaryContainerActive
                                            contentItem: MaterialSymbol {
                                                iconSize: Appearance.font.pixelSize.large
                                                fill: 1
                                                horizontalAlignment: Text.AlignHCenter
                                                color: (root.player?.isPlaying ?? false) ? root.blendedColors.colOnPrimary : root.blendedColors.colOnSecondaryContainer
                                                text: (root.player?.isPlaying ?? false) ? "pause" : "play_arrow"
                                            }
                                        }

                                        TransportButton {
                                            iconName: "skip_next"
                                            downAction: () => root.player?.next()
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        implicitHeight: 16

                                        Loader {
                                            anchors.fill: parent
                                            active: root.player?.canSeek ?? false
                                            sourceComponent: StyledSlider {
                                                configuration: StyledSlider.Configuration.Wavy
                                                highlightColor: root.blendedColors.colPrimary
                                                trackColor: root.blendedColors.colSecondaryContainer
                                                handleColor: root.blendedColors.colPrimary
                                                value: (root.player?.length > 0) ? root.player.position / root.player.length : 0
                                                onPressedChanged: if (!pressed) root.player.position = value * root.player.length
                                            }
                                        }
                                        Loader {
                                            anchors.fill: parent
                                            active: !(root.player?.canSeek ?? false)
                                            sourceComponent: StyledProgressBar {
                                                wavy: root.player?.isPlaying ?? false
                                                animateWave: root.player?.isPlaying ?? false
                                                highlightColor: root.blendedColors.colPrimary
                                                trackColor: root.blendedColors.colSecondaryContainer
                                                value: (root.player?.length > 0) ? root.player.position / root.player.length : 0
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.features: { "tnum": 1 }
                                        color: root.blendedColors.colSubtext
                                        text: `${StringUtils.friendlyTimeForSeconds(root.player?.position)} / ${StringUtils.friendlyTimeForSeconds(root.player?.length)}`
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 2
                                    implicitHeight: 1
                                    color: ColorUtils.transparentize(root.blendedColors.colSubtext, 0.85)
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    visible: root.needsManualSave
                                    Layout.minimumHeight: implicitHeight
                                    radius: Appearance.rounding.normal
                                    color: ColorUtils.transparentize(root.blendedColors.colPrimary, 0.85)
                                    implicitHeight: warningText.implicitHeight + 16

                                    opacity: root.needsManualSave ? 1 : 0
                                    scale: root.needsManualSave ? 1 : 0.94
                                    transformOrigin: Item.Top
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on scale {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        MaterialSymbol {
                                            Layout.alignment: Qt.AlignTop
                                            iconSize: Appearance.font.pixelSize.normal
                                            fill: 0
                                            text: "info"
                                            color: root.blendedColors.colPrimary
                                        }
                                        StyledText {
                                            id: warningText
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: root.blendedColors.colOnLayer1
                                            text: root.availablePresets.length === 0
                                                ? Translation.tr("You don't have an EasyEffects preset yet. Make one below to start using this equalizer.")
                                                : Translation.tr("Pick one of your existing EasyEffects presets below, or save your current setup first (Presets tab \u2192 Save).")
                                        }
                                        PillChip {
                                            Layout.alignment: Qt.AlignVCenter
                                            implicitHeight: 26
                                            implicitWidth: choosePresetLabel.implicitWidth + 20
                                            chipToggled: true
                                            downAction: () => root.showActivePresetDialog = true
                                            contentItem: StyledText {
                                                id: choosePresetLabel
                                                horizontalAlignment: Text.AlignHCenter
                                                font.pixelSize: Appearance.font.pixelSize.smallest
                                                color: root.blendedColors.colOnPrimary
                                                text: root.availablePresets.length === 0 ? Translation.tr("Create") : Translation.tr("Choose")
                                            }
                                        }
                                    }
                                }

                                PanelHeader {
                                    text: Translation.tr("Presets")
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    columns: 2
                                    columnSpacing: root.itemSpacing
                                    rowSpacing: root.itemSpacing

                                    Repeater {
                                        model: Object.keys(root.presetValues)

                                        delegate: PillChip {
                                            id: presetBtn
                                            required property string modelData
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 0
                                            chipToggled: root.presetName === modelData
                                            downAction: () => root.applyPreset(modelData)
                                            contentItem: RowLayout {
                                                spacing: 4
                                                Item { implicitWidth: 4 }
                                                MaterialSymbol {
                                                    iconSize: Appearance.font.pixelSize.normal
                                                    fill: 0
                                                    text: root.presetIcons[presetBtn.modelData] ?? "tune"
                                                    color: presetBtn.chipToggled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    text: Translation.tr(presetBtn.modelData)
                                                    color: presetBtn.chipToggled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    PanelHeader {
                                        text: Translation.tr("Custom")
                                    }
                                    PillChip {
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        visible: Object.keys(root.customPresets).length > 0
                                        chipToggled: root.customEditMode
                                        downAction: () => root.customEditMode = !root.customEditMode
                                        contentItem: MaterialSymbol {
                                            iconSize: Appearance.font.pixelSize.normal
                                            fill: 0
                                            horizontalAlignment: Text.AlignHCenter
                                            text: root.customEditMode ? "check" : "edit"
                                            color: root.customEditMode ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                        }
                                    }
                                    PillChip {
                                        implicitWidth: 26
                                        implicitHeight: 26
                                        downAction: () => root.showSaveDialog = !root.showSaveDialog
                                        contentItem: MaterialSymbol {
                                            iconSize: Appearance.font.pixelSize.normal
                                            fill: 0
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "add"
                                            color: root.blendedColors.colOnLayer1
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: root.showSaveDialog
                                    spacing: 6

                                    opacity: root.showSaveDialog ? 1 : 0
                                    scale: root.showSaveDialog ? 1 : 0.94
                                    transformOrigin: Item.Top
                                    Behavior on opacity {
                                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on scale {
                                        NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 32
                                        radius: Appearance.rounding.normal
                                        color: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.35)
                                        border.width: newPresetNameField.activeFocus ? 1 : 0
                                        border.color: root.blendedColors.colPrimary

                                        TextInput {
                                            id: newPresetNameField
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: root.blendedColors.colOnLayer1
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            clip: true
                                            onAccepted: root.saveCustomPreset(text)
                                            Keys.onEscapePressed: { root.showSaveDialog = false }
                                        }
                                    }
                                    PillChip {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        chipToggled: true
                                        downAction: () => root.saveCustomPreset(newPresetNameField.text)
                                        contentItem: MaterialSymbol {
                                            iconSize: Appearance.font.pixelSize.normal
                                            fill: 1
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "check"
                                            color: root.blendedColors.colOnPrimary
                                        }
                                    }
                                    PillChip {
                                        implicitWidth: 32
                                        implicitHeight: 32
                                        downAction: () => { root.showSaveDialog = false; newPresetNameField.text = "" }
                                        contentItem: MaterialSymbol {
                                            iconSize: Appearance.font.pixelSize.normal
                                            fill: 0
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            color: root.blendedColors.colOnLayer1
                                        }
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    visible: Object.keys(root.customPresets).length > 0
                                    columns: 2
                                    columnSpacing: root.itemSpacing
                                    rowSpacing: root.itemSpacing

                                    Repeater {
                                        model: Object.keys(root.customPresets)

                                        delegate: PillChip {
                                            id: customBtn
                                            required property string modelData
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 0
                                            Layout.preferredHeight: 34
                                            chipToggled: root.presetName === modelData
                                            downAction: () => root.customEditMode ? root.deleteCustomPreset(modelData) : root.applyCustomPreset(modelData)

                                            opacity: 0
                                            scale: 0.7
                                            Component.onCompleted: {
                                                customBtn.opacity = 1
                                                customBtn.scale = 1
                                            }
                                            Behavior on opacity {
                                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                                            }
                                            Behavior on scale {
                                                NumberAnimation { duration: 260; easing.type: Easing.OutBack }
                                            }

                                            contentItem: RowLayout {
                                                spacing: 4
                                                Item { implicitWidth: 4 }
                                                MaterialSymbol {
                                                    iconSize: Appearance.font.pixelSize.normal
                                                    fill: 0
                                                    text: root.customEditMode ? "delete" : "tune"
                                                    color: customBtn.chipToggled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    text: customBtn.modelData
                                                    color: customBtn.chipToggled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: railScrollDragArea
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 16
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor

                            readonly property real trackHeight: railFlick.height
                            readonly property real thumbHeight: railFlick.visibleArea.heightRatio * railScrollDragArea.trackHeight
                            readonly property real maxThumbY: Math.max(0, railScrollDragArea.trackHeight - railScrollDragArea.thumbHeight)
                            readonly property real maxContentY: Math.max(0, railFlick.contentHeight - railFlick.height)

                            function scrollToPointerY(pointerY) {
                                if (railScrollDragArea.maxThumbY <= 0) return
                                const thumbTop = Math.max(0, Math.min(pointerY - railScrollDragArea.thumbHeight / 2, railScrollDragArea.maxThumbY))
                                railFlick.contentY = (thumbTop / railScrollDragArea.maxThumbY) * railScrollDragArea.maxContentY
                            }

                            onPressed: (mouse) => railScrollDragArea.scrollToPointerY(mouse.y)
                            onPositionChanged: (mouse) => {
                                if (railScrollDragArea.pressed) railScrollDragArea.scrollToPointerY(mouse.y)
                            }
                        }

                        Rectangle {
                            id: railScrollIndicator
                            visible: railFlick.contentHeight > railFlick.height
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            y: railFlick.visibleArea.yPosition * railFlick.height
                            width: 3
                            radius: 1.5
                            height: railFlick.visibleArea.heightRatio * railFlick.height
                            color: ColorUtils.transparentize(root.blendedColors.colSubtext, railScrollDragArea.pressed ? 0.35 : 0.6)
                            opacity: railScrollIndicator.revealed ? 1 : 0

                            property bool revealed: false
                            readonly property bool wantsReveal: railFlick.moving || railFlick.flicking || railScrollDragArea.containsMouse || railScrollDragArea.pressed

                            onWantsRevealChanged: {
                                if (railScrollIndicator.wantsReveal) {
                                    railScrollHideTimer.stop()
                                    railScrollIndicator.revealed = true
                                } else {
                                    railScrollHideTimer.restart()
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        Timer {
                            id: railScrollHideTimer
                            interval: 900
                            onTriggered: railScrollIndicator.revealed = false
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumHeight: implicitHeight
                        visible: Platform.isWindows && root.oemAudioApps.length > 0
                        spacing: root.itemSpacing

                        PanelHeader {
                            text: Translation.tr("Other audio apps")
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: root.itemSpacing

                            Repeater {
                                model: root.oemAudioApps

                                delegate: PillChip {
                                    id: oemChip
                                    required property var modelData
                                    implicitHeight: 28
                                    implicitWidth: oemRow.implicitWidth + 20
                                    downAction: () => oemChip.modelData.entry.execute()
                                    contentItem: RowLayout {
                                        id: oemRow
                                        spacing: 4
                                        MaterialSymbol {
                                            iconSize: Appearance.font.pixelSize.normal
                                            fill: 0
                                            text: "open_in_new"
                                            color: root.blendedColors.colOnLayer1
                                        }
                                        StyledText {
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            text: Translation.tr("Open %1").arg(oemChip.modelData.label)
                                            color: root.blendedColors.colOnLayer1
                                        }
                                    }
                                }
                            }
                        }
                    }

                    PillChip {
                        Layout.fillWidth: true
                        Layout.minimumHeight: implicitHeight
                        implicitHeight: 36
                        visible: root.pending && root.editingCustomPresetName.length > 0
                        chipToggled: false
                        downAction: () => root.saveCustomPreset(root.editingCustomPresetName)
                        contentItem: RowLayout {
                            spacing: 6
                            Item { Layout.fillWidth: true }
                            MaterialSymbol {
                                iconSize: Appearance.font.pixelSize.normal
                                fill: 0
                                text: "sync"
                                color: root.blendedColors.colOnLayer1
                            }
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: Translation.tr("Update \"%1\"").arg(root.editingCustomPresetName)
                                color: root.blendedColors.colOnLayer1
                                elide: Text.ElideRight
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    PillChip {
                        Layout.fillWidth: true
                        Layout.minimumHeight: implicitHeight
                        implicitHeight: 46
                        enabled: root.pending
                        chipToggled: true
                        colBackgroundToggled: root.pending ? root.blendedColors.colPrimary : ColorUtils.transparentize(root.blendedColors.colLayer1, 0.35)
                        colBackgroundToggledHover: root.pending ? root.blendedColors.colPrimaryHover : ColorUtils.mix(root.blendedColors.colLayer1, root.blendedColors.colOnLayer1, 0.92)
                        downAction: () => root.saveChanges()
                        contentItem: RowLayout {
                            spacing: 6
                            Item { Layout.fillWidth: true }
                            MaterialSymbol {
                                iconSize: Appearance.font.pixelSize.large
                                fill: 1
                                text: root.pending ? "save" : "check_circle"
                                color: root.pending ? root.blendedColors.colOnPrimary : root.blendedColors.colSubtext
                                Behavior on color {
                                    ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }
                            }
                            StyledText {
                                font.bold: true
                                text: root.pending ? Translation.tr("Save") : Translation.tr("Saved")
                                color: root.pending ? root.blendedColors.colOnPrimary : root.blendedColors.colSubtext
                                Behavior on color {
                                    ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

            Panel {
                id: eqPanel
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.panelPadding
                    spacing: root.sectionSpacing

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Flickable {
                            id: eqFlick
                            anchors.fill: parent
                            anchors.rightMargin: 10
                            clip: true
                            contentWidth: width
                            contentHeight: eqColumn.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: eqColumn
                                width: eqFlick.width
                                spacing: root.sectionSpacing

                                PanelHeader {
                                    text: Translation.tr("Bands")
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 84
                                    Layout.minimumHeight: 72
                                    radius: root.panelRadius
                                    color: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.35)
                                    border.width: 1
                                    border.color: root.panelBorderColor

                                    Canvas {
                                        id: eqCurveCanvas
                                        anchors.fill: parent
                                        anchors.margins: 6

                                        property var displayBands: root.bands.slice()
                                        property var animFrom: root.bands.slice()
                                        property var animTo: root.bands.slice()
                                        property real animProgress: 1

                                        readonly property string colorSignature: [
                                            root.blendedColors.colPrimary,
                                            root.blendedColors.colSecondary,
                                            root.blendedColors.colSubtext,
                                            root.blendedColors.colLayer1
                                        ].join("|")
                                        onColorSignatureChanged: eqCurveCanvas.requestPaint()

                                        onAnimProgressChanged: {
                                            if (eqCurveCanvas.animFrom.length !== eqCurveCanvas.animTo.length) return
                                            const next = []
                                            for (let i = 0; i < eqCurveCanvas.animTo.length; i++) {
                                                const a = eqCurveCanvas.animFrom[i]
                                                const b = eqCurveCanvas.animTo[i]
                                                next.push(a + (b - a) * eqCurveCanvas.animProgress)
                                            }
                                            eqCurveCanvas.displayBands = next
                                            eqCurveCanvas.requestPaint()
                                        }

                                        NumberAnimation {
                                            id: curveAnim
                                            target: eqCurveCanvas
                                            property: "animProgress"
                                            from: 0
                                            to: 1
                                            duration: 420
                                            easing.type: Easing.OutCubic
                                        }

                                        onPaint: {
                                            const ctx = getContext("2d")
                                            ctx.reset()

                                            const padX = 10
                                            const padY = 12
                                            const innerW = width - padX * 2
                                            const innerH = height - padY * 2
                                            const midY = padY + innerH / 2

                                            const n = root.bands.length
                                            if (n < 2) return

                                            ctx.strokeStyle = ColorUtils.transparentize(root.blendedColors.colSubtext, 0.92)
                                            ctx.lineWidth = 1
                                            for (let g = 0; g < n; g++) {
                                                const gx = padX + (innerW * g) / (n - 1)
                                                ctx.beginPath()
                                                ctx.moveTo(gx, padY)
                                                ctx.lineTo(gx, height - padY)
                                                ctx.stroke()
                                            }

                                            ctx.strokeStyle = ColorUtils.transparentize(root.blendedColors.colSubtext, 0.8)
                                            ctx.lineWidth = 1
                                            ctx.beginPath()
                                            ctx.moveTo(padX, midY)
                                            ctx.lineTo(width - padX, midY)
                                            ctx.stroke()

                                            const source = (eqCurveCanvas.displayBands && eqCurveCanvas.displayBands.length === n)
                                                ? eqCurveCanvas.displayBands : root.bands
                                            const pts = []
                                            for (let i = 0; i < n; i++) {
                                                const x = padX + (innerW * i) / (n - 1)
                                                const v = Math.max(-root.bandRange, Math.min(root.bandRange, source[i]))
                                                const y = midY - (v / root.bandRange) * (innerH / 2)
                                                pts.push({ x: x, y: y })
                                            }

                                            function tracePath() {
                                                ctx.moveTo(pts[0].x, pts[0].y)
                                                for (let j = 0; j < pts.length - 1; j++) {
                                                    const xc = (pts[j].x + pts[j + 1].x) / 2
                                                    const yc = (pts[j].y + pts[j + 1].y) / 2
                                                    ctx.quadraticCurveTo(pts[j].x, pts[j].y, xc, yc)
                                                }
                                                ctx.quadraticCurveTo(
                                                    pts[pts.length - 1].x, pts[pts.length - 1].y,
                                                    pts[pts.length - 1].x, pts[pts.length - 1].y
                                                )
                                            }

                                            const fillGrad = ctx.createLinearGradient(0, 0, 0, height)
                                            const midStop = Math.max(0, Math.min(1, midY / height))
                                            fillGrad.addColorStop(0, ColorUtils.transparentize(root.blendedColors.colPrimary, 0.72))
                                            fillGrad.addColorStop(midStop, ColorUtils.transparentize(root.blendedColors.colPrimary, 1))
                                            fillGrad.addColorStop(midStop, ColorUtils.transparentize(root.blendedColors.colSecondary, 1))
                                            fillGrad.addColorStop(1, ColorUtils.transparentize(root.blendedColors.colSecondary, 0.72))

                                            ctx.beginPath()
                                            tracePath()
                                            ctx.lineTo(pts[pts.length - 1].x, midY)
                                            ctx.lineTo(pts[0].x, midY)
                                            ctx.closePath()
                                            ctx.fillStyle = fillGrad
                                            ctx.fill()

                                            const lineGrad = ctx.createLinearGradient(padX, 0, width - padX, 0)
                                            lineGrad.addColorStop(0, root.blendedColors.colPrimary)
                                            lineGrad.addColorStop(1, root.blendedColors.colSecondary)

                                            ctx.save()
                                            ctx.shadowColor = ColorUtils.transparentize(root.blendedColors.colPrimary, 0.6)
                                            ctx.shadowBlur = 6
                                            ctx.strokeStyle = lineGrad
                                            ctx.lineWidth = 3
                                            ctx.lineJoin = "round"
                                            ctx.lineCap = "round"
                                            ctx.beginPath()
                                            tracePath()
                                            ctx.stroke()
                                            ctx.restore()

                                            for (let k = 0; k < pts.length; k++) {
                                                ctx.beginPath()
                                                ctx.arc(pts[k].x, pts[k].y, 5.5, 0, Math.PI * 2)
                                                ctx.fillStyle = root.blendedColors.colLayer1
                                                ctx.fill()

                                                ctx.beginPath()
                                                ctx.arc(pts[k].x, pts[k].y, 3.5, 0, Math.PI * 2)
                                                ctx.fillStyle = root.bandAccentColor(k)
                                                ctx.fill()
                                            }
                                        }

                                        Connections {
                                            target: root
                                            function onBandsChanged() {
                                                eqCurveCanvas.animFrom = eqCurveCanvas.displayBands.slice()
                                                eqCurveCanvas.animTo = root.bands.slice()
                                                curveAnim.restart()
                                            }
                                        }
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    columns: 2
                                    columnSpacing: root.itemSpacing
                                    rowSpacing: root.itemSpacing

                                    Repeater {
                                        model: root.bandLabels.length
                                        delegate: BandCell {
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: 0
                                            Layout.preferredHeight: 34
                                            Layout.minimumHeight: 34
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    implicitHeight: 1
                                    visible: !Platform.isWindows
                                    color: ColorUtils.transparentize(root.blendedColors.colSubtext, 0.85)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    visible: !Platform.isWindows
                                    spacing: root.itemSpacing

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: root.itemSpacing

                                        StyledText {
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.bold: true
                                            color: root.blendedColors.colSubtext
                                            text: Translation.tr("EasyEffects preset")
                                        }
                                        StyledText {
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            elide: Text.ElideRight
                                            font.pixelSize: Appearance.font.pixelSize.smaller
                                            color: root.blendedColors.colOnLayer1
                                            text: root.activePreset
                                        }
                                        PillChip {
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            chipToggled: root.showActivePresetDialog
                                            downAction: () => root.showActivePresetDialog = true
                                            contentItem: MaterialSymbol {
                                                iconSize: Appearance.font.pixelSize.normal
                                                fill: 0
                                                horizontalAlignment: Text.AlignHCenter
                                                text: "edit"
                                                color: root.showActivePresetDialog ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                            }
                                        }
                                        PillChip {
                                            implicitWidth: 26
                                            implicitHeight: 26
                                            visible: root.showActivePresetDialog && root.availablePresets.length > 0
                                            chipToggled: root.activePresetEditMode
                                            downAction: () => root.activePresetEditMode = !root.activePresetEditMode
                                            contentItem: MaterialSymbol {
                                                iconSize: Appearance.font.pixelSize.normal
                                                fill: root.activePresetEditMode ? 1 : 0
                                                horizontalAlignment: Text.AlignHCenter
                                                text: "delete"
                                                color: root.activePresetEditMode ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: root.showActivePresetDialog
                                        spacing: 6

                                        opacity: root.showActivePresetDialog ? 1 : 0
                                        scale: root.showActivePresetDialog ? 1 : 0.94
                                        transformOrigin: Item.Top
                                        Behavior on opacity {
                                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                        }
                                        Behavior on scale {
                                            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 32
                                            radius: Appearance.rounding.normal
                                            color: ColorUtils.transparentize(root.blendedColors.colLayer1, 0.35)
                                            border.width: activePresetField.activeFocus ? 1 : 0
                                            border.color: root.blendedColors.colPrimary

                                            TextInput {
                                                id: activePresetField
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                verticalAlignment: TextInput.AlignVCenter
                                                color: root.blendedColors.colOnLayer1
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                clip: true
                                                onAccepted: root.setActivePreset(text)
                                                Keys.onEscapePressed: { root.showActivePresetDialog = false }
                                            }
                                        }
                                        PillChip {
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            chipToggled: true
                                            downAction: () => root.setActivePreset(activePresetField.text)
                                            contentItem: MaterialSymbol {
                                                iconSize: Appearance.font.pixelSize.normal
                                                fill: 1
                                                horizontalAlignment: Text.AlignHCenter
                                                text: "check"
                                                color: root.blendedColors.colOnPrimary
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        visible: root.pendingNewPresetName.length > 0
                                        Layout.minimumHeight: implicitHeight
                                        radius: Appearance.rounding.normal
                                        color: ColorUtils.transparentize(root.blendedColors.colPrimary, 0.85)
                                        implicitHeight: confirmColumn.implicitHeight + 16

                                        opacity: root.pendingNewPresetName.length > 0 ? 1 : 0
                                        scale: root.pendingNewPresetName.length > 0 ? 1 : 0.94
                                        transformOrigin: Item.Top
                                        Behavior on opacity {
                                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                        }
                                        Behavior on scale {
                                            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                                        }

                                        ColumnLayout {
                                            id: confirmColumn
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 6

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                MaterialSymbol {
                                                    Layout.alignment: Qt.AlignTop
                                                    iconSize: Appearance.font.pixelSize.normal
                                                    fill: 0
                                                    text: "info"
                                                    color: root.blendedColors.colPrimary
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.WordWrap
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: root.blendedColors.colOnLayer1
                                                    text: Translation.tr("\"%1\" doesn't exist in EasyEffects yet. Creating it will replace whatever's currently live with a fresh preset containing just this equalizer - any unsaved changes to your other effects will be lost.").arg(root.pendingNewPresetName)
                                                }
                                            }

                                            RowLayout {
                                                Layout.alignment: Qt.AlignRight
                                                spacing: 6

                                                PillChip {
                                                    implicitWidth: 90
                                                    implicitHeight: 30
                                                    downAction: () => root.pendingNewPresetName = ""
                                                    contentItem: StyledText {
                                                        horizontalAlignment: Text.AlignHCenter
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        text: Translation.tr("Cancel")
                                                        color: root.blendedColors.colOnLayer1
                                                    }
                                                }
                                                PillChip {
                                                    implicitWidth: 90
                                                    implicitHeight: 30
                                                    chipToggled: true
                                                    downAction: () => root.createActivePreset(root.pendingNewPresetName)
                                                    contentItem: StyledText {
                                                        horizontalAlignment: Text.AlignHCenter
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        text: Translation.tr("Create")
                                                        color: root.blendedColors.colOnPrimary
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        visible: root.pendingDeletePresetName.length > 0
                                        Layout.minimumHeight: implicitHeight
                                        radius: Appearance.rounding.normal
                                        color: ColorUtils.transparentize(root.blendedColors.colPrimary, 0.85)
                                        implicitHeight: deleteConfirmColumn.implicitHeight + 16

                                        opacity: root.pendingDeletePresetName.length > 0 ? 1 : 0
                                        scale: root.pendingDeletePresetName.length > 0 ? 1 : 0.94
                                        transformOrigin: Item.Top
                                        Behavior on opacity {
                                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                        }
                                        Behavior on scale {
                                            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                                        }

                                        ColumnLayout {
                                            id: deleteConfirmColumn
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 6

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                MaterialSymbol {
                                                    Layout.alignment: Qt.AlignTop
                                                    iconSize: Appearance.font.pixelSize.normal
                                                    fill: 0
                                                    text: "warning"
                                                    color: root.blendedColors.colPrimary
                                                }
                                                StyledText {
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.WordWrap
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: root.blendedColors.colOnLayer1
                                                    text: Translation.tr("Delete the EasyEffects preset \"%1\"? This removes its file from disk, including any other effects (compressor, limiter, etc) saved in it - not just the equalizer. This can't be undone.").arg(root.pendingDeletePresetName)
                                                }
                                            }

                                            RowLayout {
                                                Layout.alignment: Qt.AlignRight
                                                spacing: 6

                                                PillChip {
                                                    implicitWidth: 90
                                                    implicitHeight: 30
                                                    downAction: () => root.pendingDeletePresetName = ""
                                                    contentItem: StyledText {
                                                        horizontalAlignment: Text.AlignHCenter
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        text: Translation.tr("Cancel")
                                                        color: root.blendedColors.colOnLayer1
                                                    }
                                                }
                                                PillChip {
                                                    implicitWidth: 90
                                                    implicitHeight: 30
                                                    chipToggled: true
                                                    downAction: () => root.deleteEasyEffectsPreset(root.pendingDeletePresetName)
                                                    contentItem: StyledText {
                                                        horizontalAlignment: Text.AlignHCenter
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        text: Translation.tr("Delete")
                                                        color: root.blendedColors.colOnPrimary
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Flow {
                                        Layout.fillWidth: true
                                        visible: root.showActivePresetDialog && root.availablePresets.length > 0
                                        spacing: 6

                                        Repeater {
                                            model: root.availablePresets

                                            delegate: PillChip {
                                                id: presetPickChip
                                                required property string modelData
                                                readonly property bool isActive: root.activePreset === presetPickChip.modelData
                                                implicitHeight: 28
                                                implicitWidth: pickRow.implicitWidth + 20
                                                chipToggled: presetPickChip.isActive
                                                opacity: root.activePresetEditMode && presetPickChip.isActive ? 0.45 : 1
                                                downAction: () => {
                                                    if (root.activePresetEditMode) {
                                                        if (!presetPickChip.isActive)
                                                            root.requestDeleteEasyEffectsPreset(presetPickChip.modelData)
                                                    } else {
                                                        root.setActivePreset(presetPickChip.modelData)
                                                    }
                                                }
                                                contentItem: RowLayout {
                                                    id: pickRow
                                                    spacing: 4
                                                    MaterialSymbol {
                                                        visible: root.activePresetEditMode
                                                        iconSize: Appearance.font.pixelSize.normal
                                                        fill: 0
                                                        text: "delete"
                                                        color: presetPickChip.chipToggled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                                    }
                                                    StyledText {
                                                        horizontalAlignment: Text.AlignHCenter
                                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                                        text: presetPickChip.modelData
                                                        color: presetPickChip.chipToggled ? root.blendedColors.colOnPrimary : root.blendedColors.colOnLayer1
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: root.showActivePresetDialog && root.availablePresets.length === 0
                                        wrapMode: Text.WordWrap
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: root.blendedColors.colSubtext
                                        text: Translation.tr("No saved EasyEffects presets found yet - type a name above and choose Create to start a fresh one, or save one from EasyEffects' own Presets tab first.")
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    implicitHeight: 1
                                    color: ColorUtils.transparentize(root.blendedColors.colSubtext, 0.85)
                                }

                                RowLayout {
                                    id: preampRow
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: implicitHeight
                                    spacing: 8

                                    StyledText {
                                        Layout.preferredWidth: 26
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.features: { "tnum": 1 }
                                        color: root.blendedColors.colSubtext
                                        text: Translation.tr("Pre")
                                    }

                                    StyledSlider {
                                        id: preampSlider
                                        Layout.fillWidth: true
                                        configuration: StyledSlider.Configuration.M
                                        from: -root.preampRange
                                        to: root.preampRange
                                        value: root.preamp
                                        highlightColor: root.blendedColors.colPrimary
                                        trackColor: ColorUtils.transparentize(root.blendedColors.colPrimary, 0.85)
                                        handleColor: root.blendedColors.colPrimary
                                        stopIndicatorValues: [0]
                                        dotColor: root.blendedColors.colOnLayer1
                                        dotColorHighlighted: root.blendedColors.colOnPrimary
                                        usePercentTooltip: false
                                        tooltipContent: `${Math.round(value) > 0 ? "+" : ""}${Math.round(value)} dB`
                                        onMoved: root.setPreamp(value)

                                        Behavior on value {
                                            enabled: !preampSlider.pressed
                                            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                                        }
                                    }

                                    StyledText {
                                        Layout.preferredWidth: 28
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        font.features: { "tnum": 1 }
                                        color: root.blendedColors.colPrimary
                                        text: `${Math.round(root.preamp) > 0 ? "+" : ""}${Math.round(root.preamp)}`
                                    }
                                }

                            }
                        }

                        MouseArea {
                            id: eqScrollDragArea
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 16
                            hoverEnabled: true
                            preventStealing: true
                            cursorShape: Qt.PointingHandCursor

                            readonly property real trackHeight: eqFlick.height
                            readonly property real thumbHeight: eqFlick.visibleArea.heightRatio * eqScrollDragArea.trackHeight
                            readonly property real maxThumbY: Math.max(0, eqScrollDragArea.trackHeight - eqScrollDragArea.thumbHeight)
                            readonly property real maxContentY: Math.max(0, eqFlick.contentHeight - eqFlick.height)

                            function scrollToPointerY(pointerY) {
                                if (eqScrollDragArea.maxThumbY <= 0) return
                                const thumbTop = Math.max(0, Math.min(pointerY - eqScrollDragArea.thumbHeight / 2, eqScrollDragArea.maxThumbY))
                                eqFlick.contentY = (thumbTop / eqScrollDragArea.maxThumbY) * eqScrollDragArea.maxContentY
                            }

                            onPressed: (mouse) => eqScrollDragArea.scrollToPointerY(mouse.y)
                            onPositionChanged: (mouse) => {
                                if (eqScrollDragArea.pressed) eqScrollDragArea.scrollToPointerY(mouse.y)
                            }
                        }

                        Rectangle {
                            id: eqScrollIndicator
                            visible: eqFlick.contentHeight > eqFlick.height
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            y: eqFlick.visibleArea.yPosition * eqFlick.height
                            width: 3
                            radius: 1.5
                            height: eqFlick.visibleArea.heightRatio * eqFlick.height
                            color: ColorUtils.transparentize(root.blendedColors.colSubtext, eqScrollDragArea.pressed ? 0.35 : 0.6)
                            opacity: eqScrollIndicator.revealed ? 1 : 0

                            property bool revealed: false
                            readonly property bool wantsReveal: eqFlick.moving || eqFlick.flicking || eqScrollDragArea.containsMouse || eqScrollDragArea.pressed

                            onWantsRevealChanged: {
                                if (eqScrollIndicator.wantsReveal) {
                                    eqScrollHideTimer.stop()
                                    eqScrollIndicator.revealed = true
                                } else {
                                    eqScrollHideTimer.restart()
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        Timer {
                            id: eqScrollHideTimer
                            interval: 900
                            onTriggered: eqScrollIndicator.revealed = false
                        }
                    }
                }
            }
        }

        Panel {
            id: apoStatusPanel
            visible: !root.apoUiReady
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(420, parent.width - 48)
                spacing: root.sectionSpacing

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: Appearance.font.pixelSize.hugeass
                    fill: 0
                    text: "equalizer"
                    color: root.blendedColors.colSubtext
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.blendedColors.colOnLayer1
                    text: {
                        if (!root.apoInstalled)
                            return Translation.tr("Equalizer APO isn't installed. Install it to get a system-wide equalizer on Windows.")
                        if (!root.apoActiveOnDevice)
                            return Translation.tr("Equalizer APO is installed, but it isn't enabled on your current output device yet. Open its Configurator, pick this device, then reopen this popup.")
                        return Translation.tr("One more step: ii needs to add a single line to Equalizer APO's config.txt.")
                    }
                }

                PillChip {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !root.apoInstalled
                    implicitHeight: 34
                    implicitWidth: getApoLabel.implicitWidth + 32
                    chipToggled: true
                    downAction: () => Qt.openUrlExternally("https://sourceforge.net/projects/equalizerapo/")
                    contentItem: StyledText {
                        id: getApoLabel
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.blendedColors.colOnPrimary
                        text: Translation.tr("Get Equalizer APO")
                    }
                }

                PillChip {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.apoInstalled && root.apoActiveOnDevice && !root.apoHooked
                    implicitHeight: 34
                    implicitWidth: enableLabel.implicitWidth + 32
                    chipToggled: true
                    downAction: () => EqualizerApoBackend.requestElevatedHook()
                    contentItem: StyledText {
                        id: enableLabel
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.blendedColors.colOnPrimary
                        text: Translation.tr("Enable")
                    }
                }
            }
        }
    }
}

