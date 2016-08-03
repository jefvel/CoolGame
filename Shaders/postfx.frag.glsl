#ifdef GL_ES
precision highp float;
#endif

//uniform vec3 color;
varying vec3 col;
uniform float time;

uniform sampler2D buff;

uniform vec2 screenSize;

void main() {
    vec2 uv = gl_FragCoord.xy / screenSize.xy;
    vec4 color =  texture2D(buff, uv);
    float depth = color.a;
    vec2 offset = screenSize / gl_FragCoord.xy - 0.5 * 2.0;
    vec2 d = vec2(1.0) / screenSize;
    
    // color.r = texture2D(buff, uv + offset * 0.0011).r;
    // color.g = texture2D(buff, uv + offset * 0.0003).g;
   /*
    float t = mod(time, 1.0);
   
    color.rgb -= vec3(
        sin(t + (gl_FragCoord.x * 100.0) + 100.0) * 
        cos(t + (gl_FragCoord.y * 10.0) + 100.0)) * 0.1;
    */
    //color.rgb = vec3(depth / 2.0);
    
    color.a = 1.0;
    gl_FragColor = color;
}