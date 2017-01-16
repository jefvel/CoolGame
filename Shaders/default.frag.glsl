#version 100

#ifdef GL_ES
precision mediump float;
#endif
//uniform vec3 color;
varying vec3 col;

varying vec3 _pos;

uniform sampler2D heightMaps;

uniform float totalWidth;
uniform float time;



void main() {
    float height = col.y;
    vec4 color = vec4(0.0, col.y, 0.0, 1.0);
    color.r += sin(color.r * 10.1 + time);
    color.g += cos(color.g * 20.2 + time * 2.0);
    color.b += sin(color.b * 40.3 - time * 4.0);
    color.rgb = vec3(col.yyy);
    color.a = gl_FragCoord.z;
    
    gl_FragColor = texture2D(heightMaps, _pos.xy);

    
    vec3 col = vec3(167,205,44);
    col /= 255.0;
    vec3 col2 = vec3(186,218,95);
    col2 /= 255.0;
    vec3 col3 = vec3(206,232,145);
    col3 /= 255.0;

    float steps = 0.01;
    float os = 0.0 * min(1.0, mod(time * 0.5, 1.0));

    float segment = (height + os * 3.0) / steps;

    segment = floor(mod(segment, 3.0));

    color.rgb = vec3(0.0);
    color.rgb += max(0.0, 1.0 - (segment)) * col2;
    color.rgb += max(0.0, 1.0 - abs(1.0 - segment) * 100.0) * col3;
    color.rgb += max(0.0, 1.0 - abs(2.0 - segment) * 100.0) * col;

    //color.rgb *= col;//vec3(1.0 / 255.0, 142.0 / 255.0, 14.0 / 255.0);
    //color.rgb = mix(col, col2, height * 2.0);
    gl_FragColor = color;
}