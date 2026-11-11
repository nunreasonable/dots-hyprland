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

const float PI = 3.14159265;

float starDistance(vec2 p, float outer) {
    float sector = 2.0 * PI / 5.0;
    float a = atan(p.y, p.x);
    a = mod(a, sector) - sector * 0.5;
    a = abs(a);
    vec2 q = length(p) * vec2(cos(a), sin(a));
    vec2 tip = vec2(outer, 0.0);
    vec2 valley = 0.5 * outer * vec2(cos(sector * 0.5), sin(sector * 0.5));
    vec2 edge = normalize(valley - tip);
    vec2 normal = vec2(edge.y, -edge.x);
    if (dot(-tip, normal) > 0.0)
        normal = -normal;
    return dot(q - tip, normal);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 px = (uv - 0.5) * vec2(pxWidth, pxHeight);
    float p = clamp(progress, 0.0, 1.0);
    float turn = (seed - floor(seed)) * 2.0 * PI + p * 1.2;
    vec2 r = mat2(cos(turn), -sin(turn), sin(turn), cos(turn)) * px;
    float reach = (0.5 * length(vec2(pxWidth, pxHeight)) + 24.0) / 0.42;
    float d = starDistance(r, reach * p);
    vec3 colour = blockEdge(d, texture(fromImage, uv).rgb, texture(toImage, uv).rgb, 6.0, sekaiAccent.rgb);
    fragColor = vec4(colour, 1.0) * qt_Opacity;
}
