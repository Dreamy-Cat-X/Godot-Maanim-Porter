shader_type canvas_item;

render_mode blend_mix;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int glow_type;
uniform float alpha;

vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}
vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

void fragment() {
	vec4 txColor = texture(TEXTURE, UV);
	vec4 bgColor = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = glow_type == 3 ? screen(txColor, bgColor) : multiply(txColor, bgColor);
	COLOR.a = alpha;
}
