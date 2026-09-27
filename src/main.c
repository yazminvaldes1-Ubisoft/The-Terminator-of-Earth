#version 330 core
in vec3 vWorldDirection;
out vec4 fragColor;

uniform sampler2D uSkyTexture;

const float PI = 3.141592653589793;

void main() {
    vec3 dir = normalize(vWorldDirection);
    float yaw = atan(dir.z, dir.x);
    float pitch = acos(clamp(dir.y, -1.0, 1.0));

    vec2 uv = vec2((yaw / (2.0 * PI)) + 0.5, pitch / PI);
    vec3 color = texture(uSkyTexture, uv).rgb;
    fragColor = vec4(color, 1.0);
}
