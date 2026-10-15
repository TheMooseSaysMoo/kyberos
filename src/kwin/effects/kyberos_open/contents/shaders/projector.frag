// KyberOS holoprojector: while the window flies out of its dock icon it is a
// hologram (crystal tint, scanlines, flicker, row jitter, a beam glowing up
// from the bottom edge) that settles into the real image as it lands.

uniform sampler2D sampler;
uniform vec4 modulation;
uniform int textureWidth;
uniform int textureHeight;

uniform float uProgress;   // 0..1, linear
uniform vec4 uAccent;

in vec2 texcoord0;
out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main()
{
    float p = clamp(uProgress, 0.0, 1.0);
    float holo = 1.0 - smoothstep(0.5, 1.0, p);      // hologram look fades out late
    vec2 size = vec2(float(textureWidth), float(textureHeight));
    vec2 uv = texcoord0;

    // projection instability: rows slip sideways early on
    float row = floor(uv.y * size.y / 3.0);
    uv.x += (hash(vec2(row, floor(p * 30.0))) - 0.5) * 0.025 * holo * holo;

    vec4 tex = texture(sampler, uv);                  // premultiplied
    float luma = dot(tex.rgb, vec3(0.3, 0.59, 0.11));
    vec3 tint = luma * uAccent.rgb * 2.3 + uAccent.rgb * 0.14 * tex.a;
    float scan = 0.7 + 0.3 * step(0.5, fract(uv.y * size.y / 3.0));
    float flicker = 0.85 + 0.15 * hash(vec2(floor(p * 48.0), 3.0));
    vec3 rgb = mix(tex.rgb, tint * scan * flicker, holo);

    // beam light climbing from the bottom edge (where it leaves the dock)
    rgb += uAccent.rgb * pow(uv.y, 3.0) * 0.9 * holo * tex.a;

    // lit outline while it is still a projection
    vec2 edgePx = min(texcoord0, 1.0 - texcoord0) * size;
    float rim = 1.0 - smoothstep(1.0, 3.0, min(edgePx.x, edgePx.y));
    rgb += mix(uAccent.rgb, vec3(1.0), 0.3) * rim * holo * tex.a;

    float alpha = mix(0.35, 1.0, smoothstep(0.0, 0.75, p));
    fragColor = vec4(rgb, tex.a) * alpha * modulation;
}
