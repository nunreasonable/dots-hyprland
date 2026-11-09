#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float seed;
    float aspectX;
};

const int MAX_COLONIES = 8;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float ragged(vec2 p) {
    return 0.55 * valueNoise(p) + 0.3 * valueNoise(p * 2.3 + 17.0) + 0.15 * valueNoise(p * 5.1 + 41.0);
}

void main() {
    float aspect = max(aspectX, 0.1);
    vec2 p = vec2(qt_TexCoord0.x * aspect, qt_TexCoord0.y);

    float columns = clamp(floor(aspect * 1.7 + 0.5), 2.0, 4.0);
    float rows = 2.0;
    vec2 block = vec2(aspect / columns, 1.0 / rows);
    float pace = 0.55 / (0.85 * length(block));
    int colonies = int(columns * rows);
    float first = floor(rand(vec2(seed, 0.5)) * columns * rows);
    float arrival = 10.0;
    for (int i = 0; i < MAX_COLONIES; i++) {
        if (i >= colonies)
            break;
        float fi = float(i);
        vec2 slot = vec2(mod(fi, columns), floor(fi / columns));
        vec2 jitter = vec2(rand(vec2(fi + 0.31, seed)), rand(vec2(seed + 7.7, fi + 2.9))) * 0.7 + 0.15;
        vec2 origin = (slot + jitter) * block;
        float delay = fi == first ? 0.0 : rand(vec2(fi * 3.1, seed + 1.3)) * 0.35;
        arrival = min(arrival, delay + length(p - origin) * pace);
    }
    arrival += (ragged(p * 7.0 + seed) - 0.5) * 0.2;

    float encoded = clamp((arrival + 0.12) / 1.14, 0.0, 1.0) * 255.0;
    fragColor = vec4(floor(encoded) / 255.0, fract(encoded), 0.0, 1.0);
}
