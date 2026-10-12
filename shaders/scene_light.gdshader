shader_type canvas_item;
// Lumina scenei peste personaje și obiecte (straturile pixel-art), ca să se potrivească cu fundalul:
//  - ambient: culoarea și intensitatea luminii generale a locului (ex. cald și slab seara, albastru noaptea);
//  - două surse punctuale (bec, felinar, fereastră...) care luminează mai tare partea apropiată de ele;
//  - partea de jos e puțin mai întunecată (umbra de contact cu podeaua).
// Lumina se calculează pe fiecare pixel al grilei de 640x360, deci arta rămâne curată.
uniform vec3 ambient = vec3(1.0);
uniform vec2 light1_pos = vec2(0.0);
uniform vec3 light1_color = vec3(1.0);
uniform float light1_radius = 300.0;
uniform float light1_strength = 0.0;
uniform vec2 light2_pos = vec2(0.0);
uniform vec3 light2_color = vec3(1.0);
uniform float light2_radius = 300.0;
uniform float light2_strength = 0.0;
uniform float saturation = 1.0;
uniform float ground_shade = 0.22;
// cât din obiect e sub apă, de jos în sus (0 = nimic); folosit la pietrele din băltoacă
uniform float water_level = 0.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float falloff(vec2 p, vec2 lp, float r) {
	float k = clamp(1.0 - distance(p, lp) / r, 0.0, 1.0);
	return k * k;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec3 light = ambient
		+ light1_color * light1_strength * falloff(world_pos, light1_pos, light1_radius)
		+ light2_color * light2_strength * falloff(world_pos, light2_pos, light2_radius);
	vec3 rgb = c.rgb * light;
	float g = dot(rgb, vec3(0.299, 0.587, 0.114));
	rgb = mix(vec3(g), rgb, saturation);
	float a = c.a;
	if (water_level > 0.0) {
		float line = 1.0 - water_level;
		if (UV.y > line) { a = 0.0; }
		else if (UV.y > line - 0.06) { rgb = mix(rgb, vec3(0.75, 0.8, 0.95), 0.5); }
	}
	COLOR = vec4(rgb, a) * vec4(COLOR.rgb, 1.0);
}
