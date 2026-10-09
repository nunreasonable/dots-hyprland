import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property real iconSize: 32
    property color iconColor: Appearance.colors.colOnPrimaryContainer
    readonly property bool imageReady: avatarImage.status === Image.Ready
    readonly property string picturePath: Platform.isWindows ? Directories.userAvatarPathWindows : Directories.userAvatarPathAccountsService
    readonly property list<string> fallbackPaths: Platform.isWindows ? [] : [Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]

    implicitWidth: 48
    implicitHeight: 48
    radius: width / 2
    color: root.imageReady ? Appearance.colors.colLayer1 : Appearance.colors.colPrimaryContainer

    StyledImage {
        id: avatarImage
        anchors.fill: parent
        anchors.margins: root.border.width
        source: root.picturePath
        fallbacks: root.fallbackPaths
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
        layer.enabled: visible
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: avatarImage.width
                height: avatarImage.height
                radius: Math.max(0, root.radius - root.border.width)
            }
        }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: "account_circle"
        iconSize: root.iconSize
        color: root.iconColor
        visible: !root.imageReady
    }
}
