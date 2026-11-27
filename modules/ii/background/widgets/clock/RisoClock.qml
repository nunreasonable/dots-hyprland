import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property bool showDate: true
    property int horizontalAlignment: Text.AlignLeft
    readonly property real align: {
        if (root.horizontalAlignment === Text.AlignRight)
            return 1;
        if (root.horizontalAlignment === Text.AlignHCenter)
            return 0.5;
        return 0;
    }
    property real fontSize: Config.options.background.widgets.clock.digital.font.size * 2
    readonly property var style: StyleTheme.entry("riso")
    readonly property string hours: DateTime.time.split(":")[0].padStart(2, "0")
    readonly property string minutes: (DateTime.time.split(":")[1] ?? "").split(" ")[0].padStart(2, "0")
    readonly property real inset: metrics.ascent + digits.tightBoundingRect.y
    readonly property real drop: root.fontSize * 0.55
    readonly property real clockWidth: minutesText.x + minutesText.contentWidth
    readonly property real clockHeight: root.drop + digits.tightBoundingRect.height
    readonly property bool failed: effect.status === ShaderEffect.Error

    implicitWidth: Math.max(root.clockWidth, date.visible ? date.implicitWidth : 0)
    implicitHeight: root.clockHeight + (date.visible ? date.implicitHeight + root.fontSize * 0.06 : 0)

    FontMetrics {
        id: metrics
        font: hoursText.font
    }

    TextMetrics {
        id: digits
        font: hoursText.font
        text: "0123456789"
    }

    Item {
        x: (root.width - root.clockWidth) * root.align
        width: root.clockWidth
        height: root.clockHeight

        Item {
            id: hoursLayer
            width: root.clockWidth
            height: root.clockHeight

            Text {
                id: hoursText
                y: -root.inset
                text: root.hours
                color: root.style.inkA
                font {
                    family: "Bricolage Grotesque"
                    pixelSize: root.fontSize
                    variableAxes: ({
                            "wght": 800,
                            "wdth": 75,
                            "opsz": 96
                        })
                }
            }
        }

        Item {
            id: minutesLayer
            width: root.clockWidth
            height: root.clockHeight

            Text {
                id: minutesText
                x: hoursText.contentWidth * 0.55
                y: root.drop - root.inset
                text: root.minutes
                color: root.style.inkB
                font: hoursText.font
            }
        }

        ShaderEffectSource {
            id: hoursSource
            sourceItem: hoursLayer
            hideSource: !root.failed
            visible: false
        }

        ShaderEffectSource {
            id: minutesSource
            sourceItem: minutesLayer
            hideSource: !root.failed
            visible: false
        }

        ShaderEffect {
            id: effect
            width: root.clockWidth
            height: root.clockHeight
            visible: !root.failed
            property var layerA: hoursSource
            property var layerB: minutesSource
            property color inkA: root.style.inkA
            property color inkB: root.style.inkB
            property color overprint: root.style.overprint
            fragmentShader: Qt.resolvedUrl("shaders/risoOverprint.frag.qsb")
        }
    }

    StyledText {
        id: date
        visible: root.showDate
        x: (root.width - date.implicitWidth) * root.align
        y: root.clockHeight + root.fontSize * 0.06
        text: DateTime.longDate
        color: root.style.text
        font.pixelSize: Math.round(root.fontSize * 0.12)
    }
}
