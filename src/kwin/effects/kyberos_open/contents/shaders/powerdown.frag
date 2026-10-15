// KyberOS power-down: the window collapses into a bright horizontal line,
// the line shrinks to a point, and the point fades. Every phase eases out.

uniform sampler2D sampler;
uniform vec4 modulation;
uniform int textureWidth;
uniform int textureHeight;

uniform float uProgress;   // 0..1, linear
uniform vec4 uAccent;

in vec2 texcoord0;
out vec4 fragColor;

void main()
{
    float p = clamp(uProgress, 0.0, 1.0);
    vec2 size = vec2(float(textureWidth), float(textureHeight));
    vec2 uv = texcoord0;
    vec2 d = abs(uv - 0.5);

    // phase A (0..0.55): vertical squash; phase B (0.45..1): line shrinks + fades
    float a = clamp(p / 0.55, 0.0, 1.0);
    a = 1.0 - pow(1.0 - a, 3.0);
    float b = clamp((p - 0.45) / 0.55, 0.0, 1.0);
    b = 1.0 - pow(1.0 - b, 2.0);

    float px = 1.0 / size.y;
    float halfH = max(0.5 * (1.0 - a), 1.5 * px);    // never thinner than ~3 px
    float halfW = 0.5 * (1.0 - b) + 2.0 / size.x;    // ends as a small dot

    vec4 col = vec4(0.0);
    if (d.y < halfH && d.x < halfW) {
        // squashed image, flaring toward white-hot as it collapses
        float sy = max(1.0 - a, 1e-3);
        vec4 tex = texture(sampler, vec2(uv.x, 0.5 + (uv.y - 0.5) / sy));
        vec3 glow = mix(uAccent.rgb, vec3(1.0), 0.55);
        col = vec4(mix(tex.rgb, glow * tex.a, a * a), tex.a);
        // once it is a line, it is pure light
        float line = smoothstep(0.75, 1.0, a);
        col = mix(col, vec4(glow, 1.0), line);
    }
    // soft halo around the line during phase B
    float halo = exp(-d.y / (6.0 * px)) * step(d.x, halfW) * smoothstep(0.6, 1.0, a) * 0.5;
    col += vec4(uAccent.rgb, 1.0) * halo;

    float fade = 1.0 - smoothstep(0.7, 1.0, p);
    fragColor = col * fade * modulation;
}
