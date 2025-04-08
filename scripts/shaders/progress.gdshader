// CC0 License: https://godotshaders.com/shader/dynamic-progress-bar-with-waves-and-particles/
// Modified to rotate fill/particles only, keeping mask static.

shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.5;
uniform vec4 background_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform sampler2D color_gradient : source_color;
uniform sampler2D mask_texture : hint_default_white, filter_nearest;

// Rotation control for fill/particles
// 0: 0 degrees, 1: 90 degrees CW, 2: 180 degrees CW, 3: 270 degrees CW
uniform int rotation_mode : hint_range(0, 3) = 0;

// Wave effect parameters
uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(0.0, 10.0) = 3.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.5;

// Particle effect parameters
uniform float particle_speed : hint_range(0.01, 0.5) = 0.05;
uniform float particle_lifetime : hint_range(1.0, 10.0) = 3.0;
uniform float particle_softness : hint_range(0.001, 1.0) = 0.01;
uniform float particle_spacing : hint_range(0.01, 1.0) = 0.1;
uniform vec2 particle_offset = vec2(0.0, 0.0); // Offset applied within the rotated space
uniform vec2 particle_start_scale = vec2(0.02, 0.02);
uniform vec2 particle_end_scale = vec2(0.01, 0.01);
uniform float particle_scale_randomness : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D particle_alpha_gradient : source_color;
uniform int particle_amount : hint_range(0, 50) = 20;
uniform vec2 image_dimension = vec2(128, 128);


// Pseudo-random function
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Function to rotate UV coordinates (implicitly rotates around 0.5, 0.5)
vec2 rotate_uv(vec2 uv, int mode) {
    vec2 rotated_uv = uv;
    if (mode == 1) { // 90 degrees CW
        rotated_uv = vec2(1.0 - uv.y, uv.x);
    } else if (mode == 2) { // 180 degrees CW
        rotated_uv = vec2(1.0 - uv.x, 1.0 - uv.y);
    } else if (mode == 3) { // 270 degrees CW
        rotated_uv = vec2(uv.y, 1.0 - uv.x);
    }
    // mode == 0 is default (no rotation)
    return rotated_uv;
}


// Function to generate a single particle (returns alpha 0.0 to 1.0)
// Takes the fragment's coordinate in the *rotated* space.
float particle(vec2 frag_rotated_uv, float particle_id, float time, float current_progress, vec2 pixelSize) {
    float random_offset = rand(vec2(particle_id, 0.0));
    float spawn_time = particle_id * particle_spacing;
    float life = mod(time - spawn_time, particle_lifetime) / particle_lifetime;

    if (life < 0.0 || life >= 1.0) return 0.0;

    // Particle position is calculated in the rotated space
    // horizontal_pos is along the rotated X axis (direction of progress)
    // vertical_pos is along the rotated Y axis
    float vertical_pos = rand(vec2(particle_id, 1.0));
    float horizontal_pos = current_progress + life * particle_speed; // Spawn near the progress line and move forward (in rotated space)

    // Apply offset in the rotated space
    vec2 particle_pos_rotated = vec2(horizontal_pos, vertical_pos) + particle_offset;


    // Calculate scale with randomness
    float scale_random = rand(vec2(particle_id, 2.0)) * particle_scale_randomness;
    vec2 start_scale = particle_start_scale * (1.0 - scale_random);
    vec2 end_scale = particle_end_scale * (1.0 - scale_random);
    vec2 current_scale = mix(start_scale, end_scale, life);

    // Calculate distance in the rotated space
    vec2 scaled_uv = (frag_rotated_uv - particle_pos_rotated) / current_scale;
    float dist = length(scaled_uv * pixelSize); // Using pixelSize might cause non-uniform scaling if image_dimension is not square.

    float alpha = texture(particle_alpha_gradient, vec2(life, 0.5)).a;

    // Return particle alpha, apply boundary check in rotated space
    return smoothstep(1.0 + particle_softness, 1.0, dist) * alpha * step(particle_pos_rotated.x, 1.01) * step(-0.01, particle_pos_rotated.x); // Allow slightly outside 0-1 for spawning edge cases
}

void fragment() {
    // Get original UV coordinate for this fragment
    vec2 uv = UV;

    // Calculate the coordinate system for the fill/particles by rotating UV
    vec2 rotated_uv = rotate_uv(uv, rotation_mode);

    // Sample the mask texture using the ORIGINAL UV
    float mask = texture(mask_texture, uv).r;

    // --- Calculations in Rotated Space ---

    // Calculate wave offset based on the *rotated* vertical axis (rotated_uv.y)
    float wave_offset = wave_amplitude * sin(wave_frequency * rotated_uv.y + TIME * wave_speed);

    // Apply wave offset to progress
    float current_progress = progress; // Use non-waved progress for particle spawning base
    float wave_progress = progress + wave_offset;

    // Sample the color from the gradient texture (independent of rotation)
    vec4 gradient_color = texture(color_gradient, vec2(progress, 0.5));

    // --- Determine Fragment Color based on Rotated Space ---

    // Start with the background color
    vec4 calculated_color = background_color;

    // Apply the progress bar fill based on the *rotated* horizontal axis (rotated_uv.x)
    if (rotated_uv.x < wave_progress) {
        calculated_color = gradient_color;
    }

    // --- Calculate and Add Particles in Rotated Space ---
    float particle_total_alpha = 0.0;
    vec2 normPixelSize = normalize(image_dimension); // Normalize based on assumed aspect ratio for particle shape
    for (float i = 0.0; i < float(particle_amount); i++) {
        // Pass the fragment's ROTATED UV to the particle function
        particle_total_alpha += particle(rotated_uv, i, TIME, current_progress, normPixelSize);
    }
    particle_total_alpha = clamp(particle_total_alpha, 0.0, 1.0);

    // Mix particles on top of the current color (background or fill) using the gradient color
    calculated_color = mix(calculated_color, gradient_color, particle_total_alpha);


    // --- Final Output ---

    // Apply the STATIC mask to the final calculated color's alpha channel
    // This ensures the final shape is determined by the mask texture
    calculated_color.a *= mask;

    COLOR = calculated_color;
}