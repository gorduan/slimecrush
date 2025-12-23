shader_type canvas_item;

// Gel ball transparency effect for slimes
// Creates a 3D gel ball look with optional colored outline for colorless variants

uniform float base_alpha : hint_range(0.0, 1.0) = 0.95;  // Overall transparency
uniform vec4 color_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);  // Outline color (alpha 0 = no outline)
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;  // Outline thickness in pixels

void fragment() {
    vec2 texture_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel_size = 1.0 / texture_size;

    // Get the original texture color
    vec4 tex_color = texture(TEXTURE, UV);

    // Track if we should draw outline instead of normal pixel
    bool draw_outline = false;
    float outline_alpha = 0.0;

    // Check if we need to draw an outline (outline_color.a > 0)
    if (outline_color.a > 0.0 && tex_color.a < 0.5) {
        // Current pixel is transparent - check if we're near an opaque pixel

        // Sample in a circle around the pixel
        for (float angle = 0.0; angle < 6.28318; angle += 0.7854) {  // 8 samples
            for (float dist = 1.0; dist <= outline_width; dist += 1.0) {
                vec2 offset = vec2(cos(angle), sin(angle)) * dist * pixel_size;
                float neighbor_alpha = texture(TEXTURE, UV + offset).a;
                if (neighbor_alpha > 0.5) {
                    // Found an opaque neighbor - we're on the outline
                    outline_alpha = max(outline_alpha, 1.0 - (dist - 1.0) / outline_width);
                }
            }
        }

        if (outline_alpha > 0.0) {
            draw_outline = true;
        }
    }

    // Set final color based on whether we're drawing outline or normal pixel
    if (draw_outline) {
        COLOR = vec4(outline_color.rgb, outline_alpha * outline_color.a);
    } else {
        // Apply color tint and base transparency
        vec3 tinted_color = tex_color.rgb * color_tint.rgb;
        COLOR = vec4(tinted_color, tex_color.a * base_alpha * color_tint.a);
    }
}
