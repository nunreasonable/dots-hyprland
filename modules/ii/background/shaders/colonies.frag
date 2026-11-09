#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float seed;
    float mapWidth;
    float mapHeight;
};
layout(binding = 1) uniform sampler2D fromImage;
layout(binding = 2) uniform sampler2D toImage;
layout(binding = 3) uniform sampler2D arrivalMap;

const float PI = 3.14159265;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 glowTone(vec3 c) {
    float l = max(max(c.r, c.g), c.b);
    vec3 vivid = c / max(l, 0.05);
    return mix(vivid, vec3(1.0), 0.35);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 cellData = texture(arrivalMap, uv);
    float arrival = (cellData.r + cellData.g / 255.0) * 1.14 - 0.12;
    vec2 cell = floor(uv * vec2(mapWidth, mapHeight));

    float p = clamp(progress, 0.0, 1.0);
    float linear = p < 0.5 ? sqrt(p * 0.5) : 1.0 - sqrt((1.0 - p) * 0.5);
    float front = mix(-0.12, 1.02, linear);
    float energy = sin(PI * linear);
    float settle = 1.0 + 0.02 * (1.0 - linear);

    vec3 before = texture(fromImage, uv).rgb;
    vec3 after = texture(toImage, 0.5 + (uv - 0.5) / settle).rgb;
    float age = front - arrival;
    float flicker = rand(cell + seed * 0.37);

    vec3 colour;
    if (age < 0.0) {
        colour = before + glowTone(after) * 0.12 * energy * exp(age / 0.012);
        if (flicker > 0.993 && age > -0.035)
            colour = mix(colour, glowTone(after), 0.7 * energy * (1.0 + age / 0.035));
    } else {
        float fresh = 1.0 - clamp(age / 0.055, 0.0, 1.0);
        colour = mix(after, glowTone(after), fresh * fresh * (0.45 + 0.35 * flicker) * energy);
    }
    fragColor = vec4(clamp(colour, 0.0, 1.0), 1.0) * qt_Opacity;
}
