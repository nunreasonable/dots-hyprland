pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris

Scope {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property string title: StringUtils.cleanMusicTitle(player?.trackTitle ?? "") || ""
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string album: player?.trackAlbum ?? ""
    readonly property string artUrl: player?.trackArtUrl ?? ""
    readonly property bool playing: player?.isPlaying ?? false

    readonly property real sizeFactor: Math.max(0.6, Math.min(2, Config.options.media.nowPlaying.size / 100))
    readonly property int pillHeight: Math.round(64 * sizeFactor)
    readonly property int discSize: Math.round(52 * sizeFactor)
    readonly property int discMargin: Math.round((pillHeight - discSize) / 2)
    readonly property int minPillWidth: Math.round(300 * sizeFactor)
    readonly property int maxPillWidth: Math.round(540 * sizeFactor)
    readonly property int edgeGap: 12
    readonly property int openAnimDuration: Config.options.media.nowPlaying.openDuration
    readonly property int closeAnimDuration: Config.options.media.nowPlaying.closeDuration
    readonly property int popAnimDuration: Math.max(150, Math.round(openAnimDuration * 0.4))
    readonly property int flyDuration: Config.options.media.nowPlaying.flyDuration
    readonly property int barFadeDuration: 250
    property int sizeAnimDuration: openAnimDuration

    property string phase: "hidden"
    readonly property bool flying: phase === "flyIn" || phase === "flyBack"
    property bool shown: false
    property bool revealed: false
    property bool expanded: false
    property bool positioning: false
    property bool hovered: false
    property bool dragging: false
    property bool touched: false
    property bool startupDone: false
    property string lastKey: ""
    property var targetScreen: null
    property var flySource: null
    property real discAngle: 0

    signal flyInRequested()
    signal flyBackRequested()

    function trackKey() {
        return `${root.title}|${root.artist}|${root.album}`;
    }

    function pickScreen() {
        const saved = Persistent.states.nowPlaying.screen;
        const savedScreen = Quickshell.screens.find(s => s.name === saved);
        if (savedScreen) return savedScreen;
        const focused = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name);
        return focused ?? Quickshell.screens[0];
    }

    function holdFor(ms) {
        holdTimer.interval = ms;
        holdTimer.restart();
    }

    function coveredByFullscreen(screen) {
        const monitor = Hyprland.monitorFor(screen);
        if (!monitor) return false;
        return HyprlandData.windowList.some(win => win.monitor == monitor.id
            && win.workspace?.id === monitor.activeWorkspace?.id && (win.fullscreen ?? 0) > 0 && !win.minimized);
    }

    function show() {
        if (root.phase === "hidden") {
            const screen = root.pickScreen();
            if (!root.positioning && root.coveredByFullscreen(screen)) return;
            root.targetScreen = screen;
            GlobalStates.nowPlayingSourceRequested();
            root.flySource = Config.options.media.nowPlaying.flyFromBar ? (GlobalStates.nowPlayingSources[root.targetScreen?.name] ?? null) : null;
            GlobalStates.nowPlayingShown = true;
            root.phase = "starting";
            root.shown = true;
            return;
        }
        unrevealTimer.stop();
        finishTimer.stop();
        if (root.phase === "flyBack" || root.phase === "finishing") {
            GlobalStates.nowPlayingShown = true;
            root.phase = "flyIn";
            root.flyInRequested();
        } else if (root.phase === "open" || root.phase === "closing") {
            root.expand();
            root.holdFor(root.positioning ? 10000 : root.openAnimDuration + Config.options.media.nowPlaying.duration);
        }
    }

    function begin() {
        if (root.flySource) {
            root.phase = "flyIn";
            root.flyInRequested();
        } else {
            root.land();
        }
    }

    function land() {
        root.phase = "open";
        root.revealed = true;
        widenTimer.restart();
    }

    function expand() {
        unrevealTimer.stop();
        root.phase = "open";
        root.revealed = true;
        root.sizeAnimDuration = root.openAnimDuration;
        root.expanded = true;
    }

    function collapse() {
        holdTimer.stop();
        widenTimer.stop();
        root.phase = "closing";
        root.sizeAnimDuration = root.closeAnimDuration;
        root.expanded = false;
        unrevealTimer.restart();
    }

    function flyBackLanded() {
        root.phase = "finishing";
        GlobalStates.nowPlayingShown = false;
        finishTimer.interval = root.barFadeDuration;
        finishTimer.restart();
    }

    function finish() {
        root.phase = "hidden";
        root.shown = false;
        root.revealed = false;
        root.expanded = false;
        root.positioning = false;
        root.hovered = false;
        root.dragging = false;
        root.touched = false;
        GlobalStates.nowPlayingShown = false;
    }

    Timer {
        id: startupTimer
        interval: 5000
        running: true
        onTriggered: {
            root.lastKey = root.trackKey();
            root.startupDone = true;
        }
    }

    Timer {
        id: trackDebounce
        interval: 200
        onTriggered: {
            const key = root.trackKey();
            if (!root.startupDone || root.title.length === 0 || key === root.lastKey) return;
            root.lastKey = key;
            if (!Config.options.media.nowPlaying.enable) return;
            root.show();
        }
    }

    Connections {
        target: GlobalStates
        function onNowPlayingPositionRequested() {
            root.positioning = true;
            root.show();
        }
    }

    Connections {
        target: MprisController
        function onTrackChanged(reverse) {
            trackDebounce.restart();
        }
    }

    Timer {
        id: widenTimer
        interval: root.popAnimDuration
        onTriggered: {
            root.expand();
            root.holdFor(root.positioning ? 10000 : root.openAnimDuration + Config.options.media.nowPlaying.duration);
        }
    }

    Timer {
        id: holdTimer
        onTriggered: {
            if (root.hovered || root.dragging) return;
            root.collapse();
        }
    }

    Timer {
        id: unrevealTimer
        interval: root.closeAnimDuration
        onTriggered: {
            root.revealed = false;
            if (root.flySource) {
                root.phase = "flyBack";
                root.flyBackRequested();
            } else {
                root.phase = "finishing";
                finishTimer.interval = root.popAnimDuration;
                finishTimer.restart();
            }
        }
    }

    Timer {
        id: finishTimer
        onTriggered: root.finish()
    }

    onHoveredChanged: {
        if (root.hovered) root.touched = true;
        if (root.phase !== "open" && root.phase !== "closing") return;
        if (root.hovered) {
            holdTimer.stop();
            widenTimer.stop();
            root.expand();
        } else if (!root.dragging) {
            root.holdFor(root.positioning ? 10000 : 1000);
        }
    }

    component Disc: Item {
        id: discRoot
        property string artUrl: ""
        property real angle: 0
        property int sourceSize: 104

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#161616"
        }

        Item {
            id: discArt
            anchors.fill: parent
            rotation: discRoot.angle

            layer.enabled: true
            layer.smooth: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: discArt.width
                    height: discArt.height
                    radius: width / 2
                }
            }

            StyledImage {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: discRoot.artUrl
                sourceSize.width: discRoot.sourceSize
                sourceSize.height: discRoot.sourceSize
                visible: discRoot.artUrl !== ""
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: "music_note"
                iconSize: Math.round(discRoot.width * 0.46)
                color: "#e0e0e0"
                visible: discRoot.artUrl === ""
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(0, 0, 0, 0.45)
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.round(discRoot.width * 0.35)
            height: width
            radius: width / 2
            color: Qt.rgba(0, 0, 0, 0.35)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.max(3, Math.round(discRoot.width * 0.115))
            height: width
            radius: width / 2
            color: Appearance.colors.colLayer0
        }
    }

    Loader {
        active: root.shown
        sourceComponent: PanelWindow {
            id: pillWindow
            screen: root.targetScreen
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:nowPlaying"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            color: "transparent"

            readonly property bool fullArea: root.positioning || root.dragging || root.touched
            readonly property int areaPadding: Appearance.sizes.elevationMargin * 3
            readonly property rect area: {
                const screenWidth = root.targetScreen?.width ?? 1920;
                const screenHeight = root.targetScreen?.height ?? 1080;
                if (pillWindow.fullArea)
                    return Qt.rect(0, 0, screenWidth, screenHeight);
                let left = pill.x;
                let top = pill.y;
                let right = pill.x + root.maxPillWidth;
                let bottom = pill.y + root.pillHeight;
                const source = root.flySource;
                if (source) {
                    left = Math.min(left, source.x);
                    top = Math.min(top, source.y);
                    right = Math.max(right, source.x + source.size);
                    bottom = Math.max(bottom, source.y + source.size);
                }
                left = Math.max(0, Math.floor(left - pillWindow.areaPadding));
                top = Math.max(0, Math.floor(top - pillWindow.areaPadding));
                right = Math.min(screenWidth, Math.ceil(right + pillWindow.areaPadding));
                bottom = Math.min(screenHeight, Math.ceil(bottom + pillWindow.areaPadding));
                return Qt.rect(left, top, Math.max(1, right - left), Math.max(1, bottom - top));
            }

            anchors {
                top: true
                left: true
            }
            margins {
                top: pillWindow.area.y
                left: pillWindow.area.x
            }
            implicitWidth: pillWindow.area.width
            implicitHeight: pillWindow.area.height

            mask: Region {
                item: pill
            }

            NumberAnimation {
                target: root
                property: "discAngle"
                from: 0
                to: 360
                duration: 4000
                loops: Animation.Infinite
                running: true
                paused: running && !root.playing
            }

            Timer {
                id: beginTimer
                interval: 50
                onTriggered: root.begin()
            }

            Item {
                id: stage
                x: -pillWindow.area.x
                y: -pillWindow.area.y
                width: root.targetScreen?.width ?? pillWindow.width
                height: root.targetScreen?.height ?? pillWindow.height

                Item {
                    id: pill
                    readonly property real targetWidth: Math.round(Math.min(root.maxPillWidth, Math.max(root.minPillWidth, textColumn.implicitWidth + root.pillHeight + 30 * root.sizeFactor)))
                    readonly property real areaWidth: root.targetScreen?.width ?? pillWindow.width
                    readonly property real areaHeight: root.targetScreen?.height ?? pillWindow.height
                    property bool placed: false

                    width: root.expanded ? targetWidth : root.pillHeight
                    height: root.pillHeight

                    function clampInside() {
                        const maxX = pill.areaWidth - targetWidth - root.edgeGap;
                        if (pill.x > maxX) pill.x = Math.max(root.edgeGap, maxX);
                        pill.y = Math.max(0, Math.min(pill.y, pill.areaHeight - pill.height));
                    }

                    function place() {
                        const state = Persistent.states.nowPlaying;
                        if (state.x >= 0 && state.y >= 0) {
                            pill.x = state.x;
                            pill.y = state.y;
                        } else {
                            const barHeight = Appearance.sizes.barHeight;
                            const atBottom = Config.options.bar.bottom && !Config.options.bar.vertical;
                            pill.x = Math.round((pill.areaWidth - targetWidth) / 2);
                            pill.y = atBottom ? pill.areaHeight - barHeight - root.pillHeight - root.edgeGap : barHeight + root.edgeGap;
                        }
                        pill.clampInside();
                        pill.placed = true;
                    }

                    onTargetWidthChanged: if (pill.placed) pill.clampInside()
                    Component.onCompleted: {
                        pill.place();
                        beginTimer.start();
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: root.sizeAnimDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
                        }
                    }

                    HoverHandler {
                        onHoveredChanged: root.hovered = hovered
                    }

                    DragHandler {
                        id: dragHandler
                        target: pill
                        enabled: (root.phase === "open" || root.phase === "closing") && pillWindow.fullArea
                        xAxis.minimum: 0
                        xAxis.maximum: pill.areaWidth - pill.width
                        yAxis.minimum: 0
                        yAxis.maximum: pill.areaHeight - pill.height
                        onActiveChanged: {
                            root.dragging = active;
                            if (active) {
                                holdTimer.stop();
                                return;
                            }
                            Persistent.states.nowPlaying.x = Math.round(pill.x);
                            Persistent.states.nowPlaying.y = Math.round(pill.y);
                            Persistent.states.nowPlaying.screen = root.targetScreen?.name ?? "";
                            if (!root.hovered) root.holdFor(root.positioning ? 10000 : 1000);
                        }
                    }

                    TapHandler {
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onPressedChanged: if (pressed) root.touched = true
                        onTapped: (eventPoint, button) => {
                            if (button === Qt.LeftButton) GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
                            else if (button === Qt.MiddleButton) root.player?.togglePlaying();
                            else root.collapse();
                        }
                    }

                    Item {
                        id: pillBody
                        anchors.fill: parent
                        opacity: root.revealed ? 1 : 0
                        transform: Scale {
                            origin.x: root.pillHeight / 2
                            origin.y: root.pillHeight / 2
                            xScale: root.revealed ? 1 : 0.5
                            yScale: xScale
                            Behavior on xScale {
                                NumberAnimation {
                                    duration: root.popAnimDuration + 100
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                                }
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: root.popAnimDuration
                                easing.type: Easing.OutCubic
                            }
                        }

                        StyledRectangularShadow {
                            target: pillBackground
                        }

                        Rectangle {
                            id: pillBackground
                            anchors.fill: parent
                            radius: height / 2
                            color: Appearance.colors.colLayer0
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border
                            clip: true

                            ColumnLayout {
                                id: textColumn
                                anchors {
                                    left: parent.left
                                    leftMargin: root.discMargin + root.discSize + Math.round(12 * root.sizeFactor)
                                    right: parent.right
                                    rightMargin: Math.round(24 * root.sizeFactor)
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: Math.round(-2 * root.sizeFactor)
                                opacity: root.expanded ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: root.expanded ? 450 : 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.positioning ? Translation.tr("Drag to move") : Translation.tr("Now Playing")
                                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.sizeFactor)
                                    font.weight: Font.Medium
                                    color: Appearance.colors.colPrimary
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: root.title || Translation.tr("No media")
                                    font.pixelSize: Math.round(Appearance.font.pixelSize.large * root.sizeFactor)
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer0
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                    text: [root.artist, root.album].filter(s => s.length > 0).join(" · ")
                                    font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.sizeFactor)
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                }
                            }
                        }
                    }

                    Disc {
                        id: pillDisc
                        x: root.discMargin
                        y: root.discMargin
                        width: root.discSize
                        height: root.discSize
                        artUrl: root.artUrl
                        angle: root.discAngle
                        sourceSize: root.discSize * 2
                        opacity: root.flySource ? ((root.phase === "open" || root.phase === "closing") ? 1 : 0) : (root.revealed ? 1 : 0)
                        scale: root.flySource || root.revealed ? 1 : 0.5

                        Behavior on opacity {
                            enabled: !root.flySource
                            NumberAnimation {
                                duration: root.popAnimDuration
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            enabled: !root.flySource
                            NumberAnimation {
                                duration: root.popAnimDuration + 100
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
                            }
                        }
                    }
                }

                Disc {
                    id: flyer
                    visible: root.flying || root.phase === "finishing"
                    opacity: root.phase === "finishing" ? 0 : 1
                    artUrl: root.artUrl
                    angle: root.discAngle
                    sourceSize: root.discSize * 2

                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.barFadeDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            ParallelAnimation {
                id: flight
                property bool back: false
                property real toX: 0
                property real toY: 0
                property real toSize: 0

                onFinished: {
                    if (flight.back) root.flyBackLanded();
                    else root.land();
                }

                NumberAnimation {
                    target: flyer
                    property: "x"
                    to: flight.toX
                    duration: root.flyDuration
                    easing.type: flight.back ? Easing.InCubic : Easing.OutCubic
                }
                NumberAnimation {
                    target: flyer
                    property: "y"
                    to: flight.toY
                    duration: root.flyDuration
                    easing.type: flight.back ? Easing.OutCubic : Easing.InCubic
                }
                NumberAnimation {
                    target: flyer
                    properties: "width,height"
                    to: flight.toSize
                    duration: root.flyDuration
                    easing.type: Easing.InOutCubic
                }
            }

            function fly(back) {
                const src = root.flySource;
                if (!src) return;
                const wasRunning = flight.running;
                flight.stop();
                if (!wasRunning) {
                    if (back) {
                        flyer.x = pill.x + root.discMargin;
                        flyer.y = pill.y + root.discMargin;
                        flyer.width = root.discSize;
                        flyer.height = root.discSize;
                    } else {
                        flyer.x = src.x;
                        flyer.y = src.y;
                        flyer.width = src.size;
                        flyer.height = src.size;
                    }
                }
                flight.back = back;
                flight.toX = back ? src.x : pill.x + root.discMargin;
                flight.toY = back ? src.y : pill.y + root.discMargin;
                flight.toSize = back ? src.size : root.discSize;
                flight.start();
            }

            Connections {
                target: root
                function onFlyInRequested() {
                    pillWindow.fly(false);
                }
                function onFlyBackRequested() {
                    pillWindow.fly(true);
                }
            }
        }
    }

    IpcHandler {
        target: "nowPlaying"

        function trigger(): void {
            root.show();
        }

        function position(): void {
            root.positioning = true;
            root.show();
        }

        function resetPosition(): void {
            Persistent.states.nowPlaying.x = -1;
            Persistent.states.nowPlaying.y = -1;
            Persistent.states.nowPlaying.screen = "";
        }
    }
}
