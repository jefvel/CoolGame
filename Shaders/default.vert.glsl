#ifdef GL_ES
precision highp float;
#endif

attribute vec2 pos;

uniform float time;

uniform float n;
uniform int level;
uniform vec2 origin;
uniform float totalWidth;
uniform vec2 textureOffset;

uniform vec2 offset;
uniform float scale;

uniform mat4 MVP;

uniform sampler2D heightMaps;
uniform float smoothing;

varying vec3 col;
varying vec3 _pos;

void kore() {
    vec2 uv;
    
    uv  = pos * scale + offset;
    uv -= origin;
    uv /= scale;
    
    vec2 localCoord = vec2(floor(uv.x + 0.0001), floor(uv.y + 0.0001));
    uv += textureOffset;
    uv /= totalWidth;
    
    uv += (1.0 / totalWidth) * 0.01;
    //uv.x += (1.0 / totalWidth) * 0.5;
    
    vec4 h = texture2D(heightMaps, uv);
    float localHeight = h.a;
        
    col = vec3(sin(localHeight * 20.0 + time * 3.0));
    col.r = localHeight;    
    col = h.rgb;
    
    _pos = vec3(uv, 0.0);
    
    float w = n / 5.0;
    
    vec2 a; 
    vec2 localGridCoord = (pos.xy + offset / scale);
    a.x = ((localGridCoord.x - origin.x / scale) - n / 2.0);
    a.y = ((localGridCoord.y - origin.y / scale) - n / 2.0);
         
    a = abs(a);
    a *= 2.0;
    
    a.x = smoothstep(n - w, n, a.x);
    a.y = smoothstep(n - w, n, a.y);
    a *= 2.0;
    
    a.x = max(a.x, a.y);
    a = clamp(a, 0.0, 1.0);
    
    vec2 interpHeight;
    interpHeight.x = 
        texture2D(heightMaps, uv - vec2(1.0 / totalWidth, 0.0)).a +
        texture2D(heightMaps, uv + vec2(1.0 / totalWidth, 0.0)).a;
    interpHeight.y = 
        texture2D(heightMaps, uv - vec2(0.0, 1.0 / totalWidth)).a +
        texture2D(heightMaps, uv + vec2(0.0, 1.0 / totalWidth)).a;
    interpHeight /= 2.0;
    
    vec2 ratios = vec2(
        mod(localCoord.x, 2.0), 
        mod(localCoord.y, 2.0)
    );
    
    float inbetween = max(ratios.x, 0.0);
          inbetween = max(ratios.y, inbetween);
    
    interpHeight *= ratios;
    interpHeight.x = max(interpHeight.x, interpHeight.y);
    interpHeight.x = 
        interpHeight.x * inbetween + 
        localHeight * (1.0 - inbetween);
    
    col.rg = ratios;
    col.b = a.x;
    
    float height = localHeight * (1.0 - a.x) + interpHeight.x * a.x;
    
    height = mix(localHeight, height, smoothing);

    vec4 wpos = vec4(
        (pos.x) * scale + offset.x,
        height,
        (pos.y) * scale + offset.y, 1.0);
        
    
    //wpos.y += mod(pos.x, 1.0) * 0.001;
    //wpos.y += mod(pos.y, 1.0) * 0.001;
        
    col.rgb = vec3(wpos.xyz);
    col.r = max(mod(pos.x, 1.0), mod(pos.y, 1.0));
    
    //wpos.y = localHeight;
    
    wpos.y = clamp(wpos.y, 0.0, 1.0);
    wpos.y *= 50.0;
    wpos.y = min(50.0, wpos.y);
    
    wpos = MVP * wpos;
    
    gl_Position = wpos;
}