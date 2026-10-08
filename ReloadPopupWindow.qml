import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland

PanelWindow {
	id: popup
	property bool failed
	property string errorString
	signal dismissed()

	function start() {
		anim.start();
	}

	exclusiveZone: 0
	anchors.top: true
	margins.top: 0

	implicitWidth: rect.width + shadow.radius * 2
	implicitHeight: rect.height + shadow.radius * 2

	WlrLayershell.namespace: "quickshell:reloadPopup"

	// color blending is a bit odd as detailed in the type reference.
	color: "transparent"

	Rectangle {
		id: rect
		anchors.centerIn: parent
		color: popup.failed ?  "#ffe99195" : "#ffD1E8D5"

		implicitHeight: layout.implicitHeight + 30
		implicitWidth: layout.implicitWidth + 30
		radius: 12
		property real progress: 1

		// Fills the whole area of the rectangle, making any clicks go to it,
		// which dismiss the popup.
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			onPressed: {
				popup.dismissed()
			}

			// makes the mouse area track mouse hovering, so the hide animation
			// can be paused when hovering.
			hoverEnabled: true
		}

		ColumnLayout {
			id: layout
			spacing: 10
			anchors {
				top: parent.top
				topMargin: 10
				horizontalCenter: parent.horizontalCenter
			}

			Text {
				renderType: Text.NativeRendering
				font.family: "Google Sans Flex"
				font.pointSize: 14
				text: popup.failed ? "Quickshell: Reload failed" : "Quickshell reloaded"
				color: popup.failed ? "#ff93000A" : "#ff0C1F13"
			}

			Text {
				renderType: Text.NativeRendering
				font.family: "JetBrains Mono NF"
				font.pointSize: 11
				text: popup.errorString
				color: popup.failed ? "#ff93000A" : "#ff0C1F13"
				// When visible is false, it also takes up no space.
				visible: popup.errorString != ""
			}
		}

		// A progress bar on the bottom of the screen, showing how long until the
		// popup is removed.
		Rectangle {
			z: 2
			id: bar
			color: popup.failed ? "#ff93000A" : "#ff0C1F13"
			anchors.bottom: parent.bottom
			anchors.left: parent.left
			anchors.margins: 10
			height: 5
			radius: 9999
			width: (rect.width - bar.anchors.margins * 2) * rect.progress

			PropertyAnimation {
				id: anim
				target: rect
				property: "progress"
				from: 1
				to: 0
				duration: popup.failed ? 10000 : 1000
				onFinished: popup.dismissed()

				// Pause the animation when the mouse is hovering over the popup,
				// so it stays onscreen while reading. This updates reactively
				// when the mouse moves on and off the popup.
				paused: mouseArea.containsMouse
			}
		}
		// Its bg
		Rectangle {
			z: 1
			id: bar_bg
			color: popup.failed ? "#30af1b25" : "#4027643e"
			anchors.bottom: parent.bottom
			anchors.left: parent.left
			anchors.margins: 10
			height: 5
			radius: 9999
			width: rect.width - bar.anchors.margins * 2
		}
	}

	DropShadow {
		id: shadow
        anchors.fill: rect
        horizontalOffset: 0
        verticalOffset: 2
        radius: 6
        samples: radius * 2 + 1 // Ideally should be 2 * radius + 1, see qt docs
        color: "#44000000"
        source: rect
    }
}
