shader_type canvas_item;

uniform float speed = 1.0;

void fragment() {
    vec2 new_UV = mod(UV - vec2(TIME * speed,0), 1);
    COLOR = texture(TEXTURE, new_UV);
}