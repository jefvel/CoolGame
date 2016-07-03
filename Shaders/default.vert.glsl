#ifdef GL_ES
precision highp float;
#endif

attribute vec2 pos;

uniform vec2 origin;
uniform float totalWidth;
uniform vec2 textureOffset;

uniform vec2 offset;
uniform float scale;

uniform mat4 MVP;

uniform sampler2D heightMaps;

varying vec3 col;

void kore() {
    vec2 uv = pos * scale + offset;// + textureOffset * scale;
    uv -= origin;
    uv += textureOffset * scale; 
    uv /= totalWidth * scale;
    
    vec4 h = texture2D(heightMaps, uv);
    col = vec3(h.a);
    vec4 p = vec4(
        (pos.x) * scale + offset.x,
        h.a,
        (pos.y) * scale + offset.y, 1.0);
    
    
    //p.y = (cos(p.x * 2.0) + sin(p.z * 2.0));
    
    p = MVP * p;
    //col = h.rgb;
	gl_Position = p;
}