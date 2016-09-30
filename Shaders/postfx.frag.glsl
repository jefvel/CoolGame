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
    
    vec2 d = uv;
    d *= 1.0 - d;
    float vig = d.x * d.y * 15.0;
    vig = pow(abs(vig), 0.20);
    vig = clamp(vig, 0.0, 1.0);
    vig = 1.0 - vig;

    vec4 aberrationColor = color;
    aberrationColor.r = texture2D(buff, uv + d.x * (0.0011 + vig * 0.02)).r;
    aberrationColor.g = texture2D(buff, uv + d.y * (0.0003 + vig * 0.02)).g;
    
    color = mix(color, aberrationColor, vig);
    
    /*
    float t = mod(time, 1.0);
    color.rgb -= vec3(
        sin(t + (gl_FragCoord.x * 100.0) + 100.0) * 
        cos(t + (gl_FragCoord.y * 10.0) + 100.0)) * 0.1;
    */
    //color.rgb = vec3(depth / 2.0);
    
    //color *= max(0.6, mod(gl_FragCoord.x, 1.0) * mod(gl_FragCoord.y, 1.0));
    float sky = 1.0 - color.a;
    color.a = 1.0;
    vec3 skyColor = mix(vec3(201,233,246), vec3(80,200,198), pow(uv.y, 2.1));
    skyColor /= 255.0;
    
    color = mix(color, aberrationColor, vig);
    color.a = 1.0;
    color.rgb = mix(color.rgb, skyColor, sky); 
    color.a = 1.0;
    
    gl_FragColor = color;
}