import qs.modules.common
import QtQuick

Text {
    id: root
    property bool animateChange: false
    property real animationDistanceX: 0
    property real animationDistanceY: 6

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    property bool shouldUseNumberFont: /^\d+$/.test(root.text)
    property var defaultFont: shouldUseNumberFont ? Appearance.font.family.numbers : Appearance.font.family.main

    font {
        hintingPreference: Font.PreferDefaultHinting
        family: defaultFont
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        variableAxes: shouldUseNumberFont ? ({}) : Appearance.font.variableAxes.main
    }
    color: Appearance?.m3colors.m3onBackground ?? "black"
    linkColor: Appearance?.m3colors.m3primary

    component Anim: NumberAnimation {
        target: root
        duration: 300 / 2
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
    }

    onAnimateChangeChanged: {
        if (root.animateChange && !textAnimationBehavior.animation)
            textAnimationBehavior.animation = textChangeAnimation.createObject(textAnimationBehavior);
    }

    Behavior on text {
        id: textAnimationBehavior
        enabled: root.animateChange
    }

    Component {
        id: textChangeAnimation

        SequentialAnimation {
            id: textChange
            property real originalX: root.x
            property real originalY: root.y
            property bool originCaptured: false
            alwaysRunToEnd: true

            ScriptAction {
                script: {
                    if (textChange.originCaptured)
                        return;
                    textChange.originCaptured = true;
                    textChange.originalX = textChange.originalX;
                    textChange.originalY = textChange.originalY;
                }
            }
            ParallelAnimation {
                Anim {
                    property: "x"
                    to: textChange.originalX - root.animationDistanceX
                    easing.type: Easing.InSine
                }
                Anim {
                    property: "y"
                    to: textChange.originalY - root.animationDistanceY
                    easing.type: Easing.InSine
                }
                Anim {
                    property: "opacity"
                    to: 0
                    easing.type: Easing.InSine
                }
            }
            PropertyAction {} // Tie the text update to this point (we don't want it to happen during the first slide+fade)
            PropertyAction {
                target: root
                property: "x"
                value: textChange.originalX + root.animationDistanceX
            }
            PropertyAction {
                target: root
                property: "y"
                value: textChange.originalY + root.animationDistanceY
            }
            ParallelAnimation {
                Anim {
                    property: "x"
                    to: textChange.originalX
                    easing.type: Easing.OutSine
                }
                Anim {
                    property: "y"
                    to: textChange.originalY
                    easing.type: Easing.OutSine
                }
                Anim {
                    property: "opacity"
                    to: 1
                    easing.type: Easing.OutSine
                }
            }
        }
    }
}
