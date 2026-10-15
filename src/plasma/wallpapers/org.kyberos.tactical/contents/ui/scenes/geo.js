// Geometry helpers shared by the KyberOS wallpaper scenes.
.pragma library

// deterministic pseudo-random sequence (Park-Miller) so layouts are stable
function rng(seed) {
    var s = seed % 2147483647
    if (s <= 0) s += 2147483646
    return function () {
        s = (s * 16807) % 2147483647
        return (s - 1) / 2147483646
    }
}

// points of an ellipse centred on (cx, cy), rotated by rot radians
function ellipse(cx, cy, rx, ry, rot, steps) {
    var pts = []
    var n = steps || 64
    var c = Math.cos(rot || 0), s = Math.sin(rot || 0)
    for (var i = 0; i <= n; ++i) {
        var a = i / n * Math.PI * 2
        var x = rx * Math.cos(a), y = ry * Math.sin(a)
        pts.push(Qt.point(cx + x * c - y * s, cy + x * s + y * c))
    }
    return pts
}

// radial tick marks around a circle
function ticks(cx, cy, r, count, longEvery, shortLen, longLen) {
    var out = []
    for (var i = 0; i < count; ++i) {
        var a = i / count * Math.PI * 2
        var l = (i % longEvery === 0) ? longLen : shortLen
        out.push([Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)),
                  Qt.point(cx + (r + l) * Math.cos(a), cy + (r + l) * Math.sin(a))])
    }
    return out
}

// arc segments (gapped ring) from a0 to a1 split into n pieces
function segments(cx, cy, r, n, gapFrac, a0) {
    var out = []
    var span = Math.PI * 2 / n
    for (var i = 0; i < n; ++i) {
        var start = (a0 || 0) + i * span + span * gapFrac / 2
        var end = start + span * (1 - gapFrac)
        var seg = []
        for (var k = 0; k <= 12; ++k) {
            var a = start + (end - start) * k / 12
            seg.push(Qt.point(cx + r * Math.cos(a), cy + r * Math.sin(a)))
        }
        out.push(seg)
    }
    return out
}

function scale(points, sx, sy, ox, oy) {
    return points.map(function (p) { return Qt.point(ox + p[0] * sx, oy + p[1] * sy) })
}
