#ifdef GL_ES
precision highp float;
#endif

uniform vec3 color;
varying vec3 col;


void main() {
    vec4 color = vec4(color, 1.0);
    color *= 0.9;
    color.a = 1.0;
    color.rgb = col;
	gl_FragColor = color;
}