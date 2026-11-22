import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    property real innerInset: 0
    property real outerInset: 0
    readonly property real baseTopInset: DockStyle.mTop(innerInset, outerInset)
    readonly property real baseBottomInset: DockStyle.mBottom(innerInset, outerInset)
    readonly property real baseLeftInset: DockStyle.mLeft(innerInset, outerInset)
    readonly property real baseRightInset: DockStyle.mRight(innerInset, outerInset)
    readonly property real naturalWidth: DockStyle.vertical
        ? implicitBackgroundWidth + baseLeftInset + baseRightInset
        : implicitBackgroundHeight
    readonly property real crossExtra: DockStyle.vertical
        ? Math.max(0, width - implicitBackgroundWidth - baseLeftInset - baseRightInset)
        : Math.max(0, height - implicitBackgroundHeight - baseTopInset - baseBottomInset)

    Layout.fillHeight: !DockStyle.vertical
    Layout.fillWidth: DockStyle.vertical
    Layout.topMargin: DockStyle.mTop(DockStyle.buttonInnerMargin, 0)
    Layout.leftMargin: DockStyle.mLeft(DockStyle.buttonInnerMargin, 0)
    topInset: baseTopInset + (DockStyle.vertical ? 0 : crossExtra / 2)
    bottomInset: baseBottomInset + (DockStyle.vertical ? 0 : crossExtra / 2)
    leftInset: baseLeftInset + (DockStyle.vertical ? crossExtra / 2 : 0)
    rightInset: baseRightInset + (DockStyle.vertical ? crossExtra / 2 : 0)
    implicitWidth: naturalWidth
    buttonRadius: SekaiTheme.active ? Appearance.rounding.full : Appearance.rounding.normal
    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.88)

    background.implicitHeight: DockStyle.buttonBase
    background.implicitWidth: DockStyle.buttonBase
}
