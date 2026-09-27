#version 330 core
layout(location = 0) in vec3 aPos;

uniform mat4 uInvViewProj;

out vec3 vWorldDirection;

void main() {
    vec4 clip = vec4(aPos.xy, 1.0, 1.0);
    vec4 world = uInvViewProj * clip;
    vWorldDirection = normalize(world.xyz / world.w);
    gl_Position = clip;
}
