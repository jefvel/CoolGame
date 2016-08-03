#ifdef GL_ES
precision highp float;
#endif

attribute vec2 pos;
uniform float time;

void kore() {
    vec4 pos = vec4(pos.xy, 0.5, 1.0);
    gl_Position = pos;
}