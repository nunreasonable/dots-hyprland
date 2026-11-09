import QtQuick

Item {
    id: root

    required property Item source
    required property string shader
    property real progress: 0
    property int duration: 1000
    readonly property bool failed: effect.status === ShaderEffect.Error

    signal snapshotTaken

    ShaderEffectSource {
        id: fromTexture
        anchors.fill: parent
        visible: false
        sourceItem: root.source
        live: false
        onScheduledUpdateCompleted: root.snapshotTaken()
        Component.onCompleted: scheduleUpdate()
    }

    ShaderEffectSource {
        id: toTexture
        anchors.fill: parent
        visible: false
        sourceItem: root.source
        live: true
        hideSource: true
    }

    Loader {
        id: mapLoader
        active: root.shader === "colonies"
        sourceComponent: Item {
            readonly property alias texture: mapSource
            readonly property int mapWidth: 240
            readonly property int mapHeight: Math.max(1, Math.round(240 * root.height / Math.max(1, root.width)))

            ShaderEffect {
                id: mapEffect
                width: parent.mapWidth
                height: parent.mapHeight
                property real seed: effect.seed
                property real aspectX: effect.aspectX
                fragmentShader: Qt.resolvedUrl("shaders/coloniesMap.frag.qsb")
            }

            ShaderEffectSource {
                id: mapSource
                width: mapEffect.width
                height: mapEffect.height
                sourceItem: mapEffect
                hideSource: true
                smooth: false
                visible: false
            }
        }
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent

        property var fromImage: fromTexture
        property var toImage: toTexture
        property var source1: fromTexture
        property var source2: toTexture
        property real progress: root.progress
        property real time: root.progress * root.duration / 1000
        property real aspectX: width / Math.max(1, height)
        property real aspectY: 1.0
        property vector2d aspectRatio: Qt.vector2d(aspectX, aspectY)
        property vector2d origin: Qt.vector2d(0.5, 0.5)
        property real seed: Math.random() * 1000
        property var arrivalMap: mapLoader.item ? mapLoader.item.texture : null
        property real mapWidth: mapLoader.item ? mapLoader.item.mapWidth : 1
        property real mapHeight: mapLoader.item ? mapLoader.item.mapHeight : 1

        fragmentShader: Qt.resolvedUrl(`shaders/${root.shader}.frag.qsb`)
    }
}
