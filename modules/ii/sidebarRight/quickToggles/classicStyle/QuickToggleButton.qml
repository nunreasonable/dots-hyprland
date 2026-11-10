import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    toggled: false
    buttonRadius: (altAction && toggled) ? Appearance?.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    buttonRadiusPressed: Appearance?.rounding?.small
    colBackground: SekaiTheme.active ? "transparent" : ColorUtils.transparentize(colBackgroundHover, 1)
    colBackgroundHover: SekaiTheme.active ? "transparent" : Appearance.colors.colLayer1Hover
    colBackgroundActive: SekaiTheme.active ? "transparent" : Appearance.colors.colLayer1Active
    colBackgroundToggled: SekaiTheme.active ? "transparent" : Appearance.colors.colPrimary
    colBackgroundToggledHover: SekaiTheme.active ? "transparent" : Appearance.colors.colPrimaryHover
    colBackgroundToggledActive: SekaiTheme.active ? "transparent" : Appearance.colors.colPrimaryActive

    property bool sekaiReady: false
    Component.onCompleted: sekaiReady = true
    onToggledChanged: {
        if (SekaiTheme.active && sekaiReady) {
            sekaiPop.grow = toggled
            sekaiPop.restart()
        }
    }
    SekaiPopAnimation {
        id: sekaiPop
        target: button
    }
    SekaiBlock {
        z: -1
        visible: SekaiTheme.active
        anchors.fill: parent
        pressed: button.down
        fillColor: button.toggled ? SekaiTheme.accentA : button.hovered ? SekaiTheme.fillHover : SekaiTheme.fill
    }

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        iconSize: 22
        fill: toggled ? 1 : 0
        color: SekaiTheme.active ? (toggled ? SekaiTheme.textOnAccent : SekaiTheme.text) : toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: buttonIcon

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

}
