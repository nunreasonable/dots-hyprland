import QtQuick
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property string title: ""
    property color borderColor: StyleTheme.palette.text ?? Appearance.colors.colOutline
    property color background: Appearance.colors.colLayer0
    property color titleColor: StyleTheme.palette.accent ?? Appearance.colors.colPrimary
    property real titleLeftInset: 16
    property real titlePadding: 6
    property int steps: 5
    property int stepDuration: 90
    property bool animated: true

    readonly property bool _animationsOn: root.animated && Appearance.animationsEnabled
                                          && StyleTheme.motion.profile !== "none"
    property int _step: root._animationsOn ? 0 : root.steps

    onVisibleChanged: {
        if (root.visible && root._animationsOn) {
            root._step = 0;
            revealTimer.restart();
        }
    }
    Component.onCompleted: {
        if (root._animationsOn)
            revealTimer.restart();
    }

    Timer {
        id: revealTimer
        interval: root.stepDuration
        repeat: true
        running: false
        onTriggered: {
            root._step += 1;
            if (root._step >= root.steps)
                revealTimer.running = false;
        }
    }

    Item {
        id: clipArea
        anchors.fill: parent
        clip: true

        Rectangle {
            width: parent.width
            height: parent.height * Math.min(1, root._step / Math.max(1, root.steps))
            color: "transparent"
            radius: 0
            border.width: 1
            border.color: root.borderColor
            antialiasing: false
        }
    }

    Rectangle {
        id: titlePatch
        visible: root.title.length > 0 && root._step >= root.steps
        x: root.titleLeftInset
        y: -titleText.implicitHeight / 2
        width: titleText.implicitWidth + root.titlePadding * 2
        height: titleText.implicitHeight
        color: root.background

        StyledText {
            id: titleText
            anchors.centerIn: parent
            text: root.title
            color: root.titleColor
            font.pixelSize: 11
        }
    }
}
