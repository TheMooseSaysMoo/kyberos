// KyberOS blast doors. Opening: two steel doors over the window slide apart.
// Closing: they slam shut, then the sealed window fades out.
// KWin prepends the #version line and adapts in/out for legacy GL.

uniform sampler2D sampler;
uniform vec4 modulation;
uniform int textureWidth;
uniform int textureHeight;

uniform float uProgress;   // 0..1, linear
uniform float uClosing;    // 0 = opening, 1 = closing
uniform vec4 uAccent;

in vec2 texcoord0;
out vec4 fragColor;

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

void main()
{
    vec4 tex = texture(sampler, texcoord0);
    vec2 size = vec2(float(textureWidth), float(textureHeight));
    vec2 px = texcoord0 * size;
    float p = clamp(uProgress, 0.0, 1.0);

    float open;     // 1 = doors fully retracted
    float alpha;
    float doorAlpha;  // doors are solid almost at once; the window itself fades
    if (uClosing < 0.5) {
        alpha = smoothstep(0.0, 0.16, p);
        doorAlpha = smoothstep(0.0, 0.05, p);
        float t = smoothstep(0.2, 1.0, p);
        open = 1.0 - pow(1.0 - t, 3.0);               // ease out
    } else {
        float t = smoothstep(0.0, 0.6, p);
        open = 1.0 - t * t;                           // ease in: doors slam
        alpha = 1.0 - smoothstep(0.7, 1.0, p);
        doorAlpha = alpha;
    }

    float halfW = 0.5 * size.x;
    float leftEdge = halfW * (1.0 - open);            // left door covers [0, leftEdge]
    float rightEdge = halfW * (1.0 + open);           // right door covers [rightEdge, w]
    // window body only, not the drop shadow around it
    float body = smoothstep(0.3, 0.6, tex.a);

    vec4 col = tex;
    if (px.x < leftEdge || px.x > rightEdge) {
        float inner = px.x < leftEdge ? leftEdge - px.x : px.x - rightEdge;  // px from the seam
        float doorW = max(1.0, px.x < leftEdge ? leftEdge : size.x - rightEdge);
        // brushed steel, lit toward the seam
        vec3 steel = mix(vec3(0.13, 0.155, 0.19), vec3(0.22, 0.26, 0.31), 1.0 - clamp(inner / doorW, 0.0, 1.0));
        steel += (hash(floor(px.x * 0.5)) - 0.5) * 0.03;
        // horizontal ribs
        float rib = step(fract(px.y / 48.0), 0.04);
        steel = mix(steel, vec3(0.06, 0.07, 0.09), rib * 0.9);
        // panel seam every 72 px from the leading edge
        float seam = step(mod(inner, 72.0), 1.5) * step(30.0, inner);
        steel = mix(steel, vec3(0.04, 0.05, 0.06), seam);
        // hazard stripes behind the leading edge
        float stripe = step(0.5, fract((px.x + px.y) / 20.0));
        vec3 hazard = mix(vec3(0.06, 0.06, 0.05), vec3(1.0, 0.69, 0.18), stripe);
        float hz = step(6.0, inner) * step(inner, 26.0);
        steel = mix(steel, hazard, hz);
        // lit seam where the doors meet
        float glow = 1.0 - smoothstep(0.0, 5.0, inner);
        steel = mix(steel, uAccent.rgb, glow);
        // bevel highlight along the outer frame of each door
        float rim = 1.0 - smoothstep(0.0, 2.0, min(px.y, size.y - px.y));
        steel += rim * 0.12;
        fragColor = vec4(steel * body, body) * doorAlpha * modulation;
        return;
    } else if (open < 1.0) {
        // doors cast shadow onto the revealed window near their edges
        float d = min(px.x - leftEdge, rightEdge - px.x);
        col.rgb *= mix(0.35, 1.0, smoothstep(0.0, 28.0, d));
    }

    fragColor = col * alpha * modulation;
}
