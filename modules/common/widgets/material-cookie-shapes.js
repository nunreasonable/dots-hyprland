.pragma library

.import "shapes/geometry/offset.js" as Offset
.import "shapes/shapes/corner-rounding.js" as CornerRounding
.import "shapes/shapes/rounded-polygon.js" as RoundedPolygon
.import "shapes/material-shapes.js" as MaterialShapes

var stars = {}

function star(sides) {
    const cached = stars[sides];
    if (cached !== undefined)
        return cached;
    const rounding = new CornerRounding.CornerRounding((sides < 17 ? 1.5 : 1.1) / Math.max(sides, 1));
    const polygon = RoundedPolygon.RoundedPolygon.star(sides, 1, 0.8, rounding)
        .transformed((x, y) => MaterialShapes.rotate30.map(new Offset.Offset(x, y)))
        .normalized();
    stars[sides] = polygon;
    return polygon;
}
