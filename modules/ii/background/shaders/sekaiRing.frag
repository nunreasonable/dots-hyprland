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

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 px = (uv - 0.5) * vec2(pxWidth, pxHeight);
    float p = clamp(progress, 0.0, 1.0);
    float band = 0.06 * pxHeight;
    float reach = 0.5 * length(vec2(pxWidth, pxHeight)) + band + 30.0;
    float d = length(px) - reach * p;
    vec3 colour = blockEdge(d, texture(fromImage, uv).rgb, texture(toImage, uv).rgb, band, sekaiAccent.rgb);
    float inner = d + band + 6.0;
    if (inner < 0.0 && inner > -band * 0.45)
        colour = blockEdge(inner + band * 0.45, colour, texture(toImage, uv).rgb, band * 0.45 - 6.0, sekaiRing.rgb);
    fragColor = vec4(colour, 1.0) * qt_Opacity;
}
