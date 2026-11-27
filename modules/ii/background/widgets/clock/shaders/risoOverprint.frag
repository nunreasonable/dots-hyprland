#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 inkA;
    vec4 inkB;
    vec4 overprint;
};
layout(binding = 1) uniform sampler2D layerA;
layout(binding = 2) uniform sampler2D layerB;

void main() {
    float a = texture(layerA, qt_TexCoord0).a;
    float b = texture(layerB, qt_TexCoord0).a;
    vec3 colour = inkA.rgb * a * (1.0 - b) + inkB.rgb * b * (1.0 - a) + overprint.rgb * a * b;
    float alpha = a + b - a * b;
    fragColor = vec4(colour, alpha) * qt_Opacity;
}
