#ifdef GL_ES
precision highp float;
#endif

//uniform vec3 color;
varying vec3 col;

varying vec3 _pos;

uniform sampler2D heightMaps;

uniform float totalWidth;
uniform float time;

void main() {
    vec4 color = vec4(0.0, col.y, 0.0, 1.0);
    color.r += sin(color.r * 10.1 + time);
    color.g += cos(color.g * 20.2 + time * 2.0);
    color.b += sin(color.b * 40.3 - time * 4.0);
    color.rgb = vec3(col.yyy);
    color.a = gl_FragCoord.z;
    
    gl_FragColor = texture2D(heightMaps, _pos.xy);//color;

    gl_FragColor = color;
    
       
    if(gl_FragCoord.x < totalWidth && gl_FragCoord.y < totalWidth ) {
        gl_FragColor.rgb = texture2D(heightMaps, gl_FragCoord.xy / totalWidth).xxx;
    }
    
}