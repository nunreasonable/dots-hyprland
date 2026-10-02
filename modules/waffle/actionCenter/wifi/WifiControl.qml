import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

Item {
    id: root

    Component.onCompleted: {
        Network.setWifiListVisible(true);
        Network.rescanWifi();
    }
    Component.onDestruction: Network.setWifiListVisible(false)

    WPanelPageColumn {
        anchors.fill: parent

        BodyRectangle {
            implicitHeight: 400
            implicitWidth: 50

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                ColumnLayout {
                    implicitHeight: headerRow.implicitHeight
                    Layout.fillWidth: true
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        HeaderRow {
                            id: headerRow
                            Layout.fillWidth: true
                            title: Translation.tr("Wi-Fi")
                        }
                        WSwitch {
                            id: toggleSwitch
                            Layout.rightMargin: 12
                            checked: Network.wifiStatus !== "disabled"
                            onCheckedChanged: {
                                Network.enableWifi(checked);
                                Network.rescanWifi();
                            }
                        }
                    }
                    FadeLoader {
                        Layout.leftMargin: -4
                        Layout.rightMargin: -4
                        Layout.fillWidth: true
                        shown: Network.wifiScanning
                        visible: true
                        sourceComponent: WIndeterminateProgressBar {}
                    }
                }

                RowLayout {
                    visible: Network.wifiNeedsLocationPermission
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    spacing: 8

                    FluentIcon {
                        icon: "wifi-warning"
                        Layout.alignment: Qt.AlignTop
                    }
                    WText {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: Translation.tr("Location is off, so Windows is hiding Wi-Fi networks.")
                    }
                    WTextButton {
                        text: Translation.tr("Open Settings")
                        onClicked: Network.openWifiLocationSettings()
                    }
                }

                StyledListView {
                    id: listView
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    animateAppearance: false

                    contentHeight: contentLayout.implicitHeight
                    contentWidth: width
                    clip: true
                    spacing: 4

                    model: ScriptModel {
                        values: Network.friendlyWifiNetworks
                    }
                    delegate: WWifiNetworkItem {
                        required property WifiAccessPoint modelData
                        wifiNetwork: modelData
                        width: ListView.view.width
                    }
                }
            }
        }

        WPanelSeparator {}

        FooterRectangle {
            WTextButton {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                }
                text: Translation.tr("More Internet settings")
                onClicked: {
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "sidebarLeft", "toggle"]);
                    if (Platform.isWindows) {
                        WindowsNative.network?.openWifiSettings();
                    } else {
                        Quickshell.execDetached(["bash", "-c", Config.options.apps.network]);
                    }
                }
            }
            WBorderlessButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 12
                enabled: !Network.wifiScanning

                onClicked: {
                    Network.rescanWifi();
                }

                contentItem: FluentIcon {
                    icon: "arrow-counterclockwise"
                }
            }
        }
    }
}
