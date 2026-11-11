#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float seed;
    float pxWidth;
    float pxHeight;
    vec4 sekaiOutline;
    vec4 sekaiRing;
    vec4 sekaiAccent;
};
layout(binding = 1) uniform sampler2D fromImage;
layout(binding = 2) uniform sampler2D toImage;

vec3 blockEdge(float d, vec3 before, vec3 after, float ringWidth, vec3 ringColour) {
    if (d > 0.0)
        return before;
    if (d > -3.0)
        return sekaiOutline.rgb;
    if (d > -3.0 - ringWidth)
        return ringColour;
    if (d > -6.0 - ringWidth)
        return sekaiOutline.rgb;
    return after;
}

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float outBack(float t) {
    float c = 2.2;
    float u = t - 1.0;
    return 1.0 + (c + 1.0) * u * u * u + c * u * u;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 px = uv * vec2(pxWidth, pxHeight);
    float cell = max(48.0, floor(pxHeight / 9.0));
    vec2 index = floor(px / cell);
    vec2 local = px - (index + 0.5) * cell;
    vec2 cells = ceil(vec2(pxWidth, pxHeight) / cell);
    float order = (index.x + index.y) / max(1.0, cells.x + cells.y - 2.0);
    float delay = 0.45 * order + 0.05 * rand(index + seed);
    float q = clamp((progress - delay) / 0.5, 0.0, 1.0);
    float halfSize = outBack(q) * (cell * 0.5 + 10.0);
    float corner = min(cell * 0.22, halfSize) * (1.0 - smoothstep(0.85, 1.0, q));
    vec2 box = abs(local) - (halfSize - corner);
    float d = length(max(box, 0.0)) + min(max(box.x, box.y), 0.0) - corner;
    if (q <= 0.0)
        d = 1.0;
    vec3 colour = blockEdge(d, texture(fromImage, uv).rgb, texture(toImage, uv).rgb, 4.0, sekaiRing.rgb);
    fragColor = vec4(colour, 1.0) * qt_Opacity;
}
