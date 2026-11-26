import QtQuick

QtObject {
    property string key: "ii"
    property string displayName: key
    property string reportName: displayName
    property string icon: "palette"
    property string hint: ""
    property bool selectable: true
    property string layout: "ii"
    property string settingsLayout: "end4pc"
    property bool island: false
    property bool dark: true
    property bool light: true
    property var preset: ({})

    component SurfaceTokens: QtObject {
        property bool frame: false
        property bool barStrip: true
        property int borderWidth: 0
        property var borderColor
        property int ringWidth: 0
        property var ringColor
        property var fill
        property var fillHover
        property var radiusOuter
        property var radiusInner
        property var gap
    }

    component ElevationTokens: QtObject {
        property string kind: "soft"
        property int x: 0
        property int y: 0
        property var color
    }

    component TypeTokens: QtObject {
        property string ui: ""
        property string display: ""
        property string numbers: ""
        property var uiAxes
        property var displayAxes
        property var numbersAxes
    }

    component MotionTokens: QtObject {
        property string profile: "expressive"
        property var wallpaperTransitions
    }

    component TextureTokens: QtObject {
        property string source: ""
        property real opacity: 1
    }

    component PaletteTokens: QtObject {
        property var accent
        property var onAccent
        property var text
        property var scheme
    }

    property SurfaceTokens surface: SurfaceTokens {}
    property ElevationTokens elevation: ElevationTokens {}
    property TypeTokens type: TypeTokens {}
    property MotionTokens motion: MotionTokens {}
    property TextureTokens texture: TextureTokens {}
    property PaletteTokens palette: PaletteTokens {}
}
