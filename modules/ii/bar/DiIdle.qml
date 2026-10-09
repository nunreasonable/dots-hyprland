import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: diIdleRoot
    required property Item di
    anchors.fill: parent

    readonly property bool systemIconsElsewhere: BarLayouts.leftLayout.includes("systemIcons") || BarLayouts.rightLayout.includes("systemIcons")

    Rectangle {
        id: avatarRect
        width: diIdleRoot.di.pillHeight - 8
        height: diIdleRoot.di.pillHeight - 8
        anchors {
            left: parent.left
            leftMargin: 4
            verticalCenter: parent.verticalCenter
        }
        radius: width / 2
        color: Appearance.colors.colPrimaryContainer

        MaterialSymbol {
            anchors.centerIn: parent
            visible: avatarImage.status !== Image.Ready
            text: "person"
            iconSize: 16
            color: Appearance.colors.colOnPrimaryContainer
        }

        StyledImage {
            id: avatarImage
            anchors.fill: parent
            source: Platform.isWindows ? Directories.userAvatarPathWindows : Directories.userAvatarPathAccountsService
            fallbacks: Platform.isWindows ? [] : [Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]
            sourceSize.width: avatarImage.width * 2
            sourceSize.height: avatarImage.height * 2
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            layer.enabled: visible
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: avatarRect.width
                    height: avatarRect.height
                    radius: avatarRect.radius
                }
            }
        }
    }

    RowLayout {
        id: rightSideRow
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        spacing: 8

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Revealer {
                reveal: !diIdleRoot.systemIconsElsewhere && (Audio.source?.audio?.muted ?? false)
                MaterialSymbol {
                    text: "mic_off"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                }
            }

            Revealer {
                reveal: !diIdleRoot.systemIconsElsewhere && (Audio.sink?.audio?.muted ?? false)
                MaterialSymbol {
                    text: "volume_off"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer0
                }
            }

            Revealer {
                reveal: !diIdleRoot.systemIconsElsewhere && !Network.ethernet && (Network.wifiStatus === "disconnected" || Network.wifiStatus === "disabled")
                MaterialSymbol {
                    text: "wifi_off"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colError
                }
            }

            Revealer {
                reveal: (Notifications.unread ?? 0) > 0
                Item {
                    implicitWidth: notifRow.implicitWidth
                    implicitHeight: notifRow.implicitHeight

                    RowLayout {
                        id: notifRow
                        spacing: 2
                        MaterialSymbol {
                            text: "notifications"
                            iconSize: Appearance.font.pixelSize.normal
                            color: Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            text: `${Notifications.unread}`
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.features: {
                                "tnum": 1
                            }
                            color: Appearance.colors.colOnLayer0
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
                    }
                }
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: Config.options.bar.dynamicIsland.leftWidget === "clockWidget" ? weatherComponent : clockComponent

            Component {
                id: clockComponent
                StyledText {
                    text: DateTime.time
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.features: {
                        "tnum": 1
                    }
                    color: Appearance.colors.colOnLayer0
                }
            }

            Component {
                id: weatherComponent
                RowLayout {
                    spacing: 4

                    MaterialSymbol {
                        fill: 0
                        text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colOnLayer0
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.features: {
                            "tnum": 1
                        }
                        color: Appearance.colors.colOnLayer0
                        text: Weather.data?.temp ?? "--°"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        readonly property real computedIdleWidth: avatarRect.width + 4 + 10 + rightSideRow.implicitWidth + 10

        onComputedIdleWidthChanged: diIdleRoot.di.idleTextContentWidth = rightSideRow.computedIdleWidth
        Component.onCompleted: diIdleRoot.di.idleTextContentWidth = rightSideRow.computedIdleWidth
    }
}
