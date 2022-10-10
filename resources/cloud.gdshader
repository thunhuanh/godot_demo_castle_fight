shader_type canvas_item;

uniform vec2 direction = vec2(1, 0);
uniform sampler2D noise;
uniform float speed : hint_range(0.0, 1.0) = 0.1;
uniform float brightness: hint_range(0.0, 2.0) = 0.1;
uniform float alpha: hint_range(0.0, 2.0) = 0.1;
uniform float threshold : hint_range(0.0, 2.0) = 0.1;
uniform float fluffiness : hint_range(0.0, 2.0) = 0.1;

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}


void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Mixing two time-shifted textures to create fluffiness
	vec4 noise1 = texture(noise, mod(UV + TIME * 2.5 * speed / 10.0, 0.0));
	vec4 noise2 = texture(noise, mod(UV + TIME * (2.5 + fluffiness * 3.0) * speed / 10.0, 0.0));
	vec4 combinedNoise = noise1 + noise2;
	
	// Creating smooth transitions using smoothstep
	combinedNoise.a = combinedNoise.r;
	COLOR.rgb = smoothstep(threshold - 0.3, threshold + 0.3, combinedNoise).rgb * brightness;
	COLOR.a = smoothstep(threshold - 0.3, threshold + 0.3, combinedNoise).a * alpha;

//	vec4 base = texture(SCREEN_TEXTURE, uv, 0.0);
	// noise texture
//	vec4 blend = texture(noise, UV + ( direction * speed * TIME));
//	COLOR = overlay(base, blend);
}
