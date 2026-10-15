// KyberOS hologram: the window projects in from the bottom with scanlines,
// row jitter and an accent tint that settles into the real image.

uniform sampler2D sampler;
uniform vec4 modulation;
uniform int textureWidth;
uniform int textureHeight;

uniform float uProgress;
uniform float uClosing;
uniform vec4 uAccent;

in vec2 texcoord0;
out vec4 fragColor;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void main()
{
    float p = clamp(uProgress, 0.0, 1.0);
    float k = uClosing < 0.5 ? p : 1.0 - p;          // 0 = absent, 1 = solid
    vec2 size = vec2(float(textureWidth), float(textureHeight));
    vec2 uv = texcoord0;

    // jitter rows while the projection stabilises
    float row = floor(uv.y * size.y / 3.0);
    float jitter = (hash(vec2(row, floor(p * 24.0))) - 0.5) * 0.03 * (1.0 - k);
    uv.x += jitter;

    vec4 tex = texture(sampler, uv);

    // reveal sweeps up from the bottom with a bright leading line
    float edge = 1.0 - k * 1.15;
    float shown = smoothstep(edge, edge + 0.04, uv.y);
    float line = (1.0 - smoothstep(0.0, 0.012, abs(uv.y - edge))) * (1.0 - k);

    // scanlines + flicker fade out as the image settles
    float scan = 0.75 + 0.25 * step(0.5, fract(uv.y * size.y / 3.0));
    float flicker = 0.85 + 0.15 * hash(vec2(floor(p * 40.0), 7.0));
    vec3 tint = mix(tex.rgb, dot(tex.rgb, vec3(0.3, 0.59, 0.11)) * uAccent.rgb * 1.6, (1.0 - k) * 0.8);
    vec3 rgb = mix(tint * scan * flicker, tex.rgb, k * k);

    float a = tex.a * shown * mix(0.6, 1.0, k);
    vec4 col = vec4(rgb * shown * mix(0.6, 1.0, k), a);
    col.rgb += uAccent.rgb * line * tex.a;
    fragColor = col * modulation;
}
