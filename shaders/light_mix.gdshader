shader_type canvas_item;
// Fundal cu o sursă de lumină reglabilă (felinar, bec): imaginea = varianta stinsă + contribuția luminii.
// Contribuția = (aprins − stins), înmulțită cu intensitatea; când intensitatea scade, lumina devine
// mai portocalie-roșiatică, ca un filament/arc care se răcește. Așa pâlpâitul arată ca o lumină reală,
// nu ca o imagine care se estompează.
uniform sampler2D off_tex : filter_nearest;
uniform float intensity : hint_range(0.0, 1.2) = 1.0;
uniform vec3 cool_tint = vec3(1.0, 0.55, 0.3);   // culoarea luminii la intensitate mică

void fragment() {
	vec3 on = texture(TEXTURE, UV).rgb;
	vec3 off = texture(off_tex, UV).rgb;
	vec3 light = max(on - off, vec3(0.0));
	float i = clamp(intensity, 0.0, 1.2);
	vec3 tint = mix(cool_tint, vec3(1.0), smoothstep(0.15, 0.9, i));
	COLOR = vec4(off + light * i * tint, 1.0);
}
