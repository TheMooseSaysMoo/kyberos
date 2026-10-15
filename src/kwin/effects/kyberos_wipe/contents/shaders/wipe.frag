// KyberOS wipe: uEdge is the wipe edge in this window's texture u.
// uDir = 1 wipes left-to-right, -1 right-to-left.
// uMode 0 = incoming window (shown behind the edge), 1 = outgoing (shown ahead of it).

uniform sampler2D sampler;
uniform vec4 modulation;
uniform int textureWidth;

uniform float uEdge;
uniform float uDir;
uniform float uMode;
uniform vec4 uAccent;

in vec2 texcoord0;
out vec4 fragColor;

void main()
{
    vec4 tex = texture(sampler, texcoord0);
    // signed distance past the edge, in pixels: > 0 means already swept
    float d = (uEdge - texcoord0.x) * uDir * float(textureWidth);
    float swept = step(0.0, d);
    float keep = uMode < 0.5 ? swept : 1.0 - swept;
    vec4 col = tex * keep;
    // bright edge line plus a short trailing glow
    float line = 1.0 - smoothstep(0.0, 3.0, abs(d));
    float trail = (1.0 - smoothstep(0.0, 60.0, d)) * swept * 0.35;
    col.rgb += uAccent.rgb * (line + trail * (1.0 - uMode)) * tex.a;
    fragColor = col * modulation;
}
