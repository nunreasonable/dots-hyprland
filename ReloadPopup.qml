import QtQuick
import Quickshell

Scope {
	id: root
	property bool failed;
	property string errorString;

	// Connect to the Quickshell global to listen for the reload signals.
	Connections {
		target: Quickshell

		function onReloadCompleted() {
			root.failed = false;
			root.showPopup();
		}

		function onReloadFailed(error: string) {
			// Close any existing popup before making a new one.
			popupLoader.active = false;

			root.failed = true;
			root.errorString = error;
			root.showPopup();
		}
	}

	function showPopup() {
		popupLoader.source = "ReloadPopupWindow.qml";
		if (popupLoader.item) {
			popupLoader.item.failed = root.failed;
			popupLoader.item.errorString = root.errorString;
		} else {
			popupLoader.loading = true;
		}
	}

	// Keep the popup in a loader because it isn't needed most of the time
	LazyLoader {
		id: popupLoader
		onItemChanged: {
			if (!item) return;
			item.failed = root.failed;
			item.errorString = root.errorString;
			item.start();
		}
	}

	Connections {
		target: popupLoader.item
		function onDismissed() {
			popupLoader.active = false;
		}
	}
}
