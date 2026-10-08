import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.modules.common
import qs.modules.common.widgets.shapes
import "shapes/material-shapes.js" as MaterialShapes
import "material-cookie-shapes.js" as MaterialCookieShapes

Item {
    id: root
    property int sides: 12  
    property int implicitSize: 100
    property alias color: shapeCanvas.color

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    MaterialShapeCanvas {
        id: shapeCanvas
        anchors.fill: parent
        roundedPolygon: switch(sides) {
            case 0: return MaterialShapes.getCircle();
            case 1: return MaterialShapes.getCircle();
            case 4: return MaterialShapes.getCookie4Sided();
            case 6: return MaterialShapes.getCookie6Sided();
            case 7: return MaterialShapes.getCookie7Sided();
            case 9: return MaterialShapes.getCookie9Sided();
            case 12: return MaterialShapes.getCookie12Sided();
            default: return MaterialCookieShapes.star(sides);
        }
    }
}
