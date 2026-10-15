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

        fragmentShader: Qt.resolvedUrl(`shaders/${root.shader}.frag.qsb`)
    }
}
