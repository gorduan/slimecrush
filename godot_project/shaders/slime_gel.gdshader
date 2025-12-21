shader_type canvas_item;

// Gel ball transparency effect for slimes
// Creates a 3D gel ball look: opaque in center, more transparent at edges
// Simply applies color tint - gel effect disabled due to atlas UV issues

uniform float base_alpha : hint_range(0.0, 1.0) = 0.95;  // Overall transparency
uniform vec4 color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    // Get the original texture color
    vec4 tex_color = texture(TEXTURE, UV);

    // Apply color tint and base transparency
    vec3 tinted_color = tex_color.rgb * color_tint.rgb;
    COLOR = vec4(tinted_color, tex_color.a * base_alpha * color_tint.a);
}
