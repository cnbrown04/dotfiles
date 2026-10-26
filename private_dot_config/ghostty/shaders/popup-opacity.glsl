// Popup opacity for Ghostty.
//
// Ghostty has one window-wide opacity, so popups can't be more opaque than the
// terminal on their own. Popups (Neovim floats, tmux popups) paint a reserved
// marker background, #1a1a1b; Ghostty draws that solid, and this shader turns
// it into #1a1a1a at POPUP_ALPHA. Text over the marker keeps its own color;
// its anti-aliased edges are un-blended from the marker so they don't keep a
// dark opaque rim.
//
// Colors arrive in linear space (alpha-blending = linear-corrected), and the
// output is premultiplied alpha.

const float POPUP_ALPHA = 0.75;
const vec3 MARKER_SRGB = vec3(26.0, 26.0, 27.0) / 255.0;
const vec3 TINT_SRGB = vec3(26.0, 26.0, 26.0) / 255.0;
const int RADIUS = 2; // px searched around text edges for marker / glyph color

vec3 to_linear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(0.04045, c));
}

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

bool is_marker(vec4 c, vec3 marker) {
    return c.a > 0.99 && all(lessThan(abs(c.rgb - marker), vec3(0.0002)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 px = 1.0 / iResolution.xy;
    vec2 uv = fragCoord * px;
    vec4 c = texture(iChannel0, uv);
    vec3 marker = to_linear(MARKER_SRGB);
    vec4 tint = vec4(to_linear(TINT_SRGB) * POPUP_ALPHA, POPUP_ALPHA);

    if (is_marker(c, marker)) {
        fragColor = tint;
        return;
    }
    if (c.a < 0.99) {
        fragColor = c;
        return;
    }

    // Opaque non-marker pixel: is it a text edge over the marker? Look for
    // marker pixels nearby, and take the brightest-contrast neighbor as the
    // glyph's full color.
    bool near_marker = false;
    vec3 fg = c.rgb;
    float best = abs(luma(c.rgb) - luma(marker));
    for (int y = -RADIUS; y <= RADIUS; y++) {
        for (int x = -RADIUS; x <= RADIUS; x++) {
            vec4 n = texture(iChannel0, uv + vec2(x, y) * px);
            if (is_marker(n, marker)) {
                near_marker = true;
            } else if (n.a > 0.99) {
                float d = abs(luma(n.rgb) - luma(marker));
                if (d > best) {
                    best = d;
                    fg = n.rgb;
                }
            }
        }
    }
    if (!near_marker) {
        fragColor = c;
        return;
    }

    // c = mix(marker, fg, t)  ->  recover coverage t, then re-blend over tint.
    float denom = luma(fg) - luma(marker);
    float t = abs(denom) < 1e-4 ? 1.0 : clamp((luma(c.rgb) - luma(marker)) / denom, 0.0, 1.0);
    fragColor = vec4(fg * t, t) + tint * (1.0 - t);
}
