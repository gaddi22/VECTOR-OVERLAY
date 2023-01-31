#version 150 compatibility

#include "/lib/settings.h"

uniform sampler2D colortex0; // albedo
uniform sampler2D colortex3; // normals, entity mask
uniform sampler2D depthtex0;
in vec2 uv;

uniform float far;
uniform float near;

const float edge_kernel[9] = float[](-1.0, -1.0, -1.0, -1.0, 8.0, -1.0, -1.0, -1.0, -1.0);

// Choc version
float linearizeDepth(float dist) {
    return (2.0 * near) / (far + near - dist * (far - near));
}

bool equals(float input1, float input2, float epsilon) {
	return abs(input1 - input2) < epsilon;
}

/* RENDERTARGETS:0 */
void main() {
	
	vec3 color = vec3(0.0);
	for(int y = 0; y < 3; y++) {
		for(int x = 0; x < 3; x++) {
			vec2 offset = pixelSize * vec2(x - 1, y - 1) * 1.0;
			color += texture2D(colortex0, uv + offset).rgb * edge_kernel[y * 3 + x];
		}
	}
	color /= 4.5;

	float depth = 0.0;
	for(int y = 0; y < 3; y++) {
		for(int x = 0; x < 3; x++) {
			vec2 offset = pixelSize * vec2(float(x) - 1.0, float(y) - 1.0) * 1.0;
			float rawDepth = texture2D(depthtex0, uv + offset).r;
			depth += linearizeDepth(rawDepth) * edge_kernel[y * 3 + x];
		}
	}
	depth *= 0.8;

	vec3 normal = vec3(0.0);
	for(int y = 0; y < 3; y++) {
		for(int x = 0; x < 3; x++) {
			vec2 offset = pixelSize * vec2(x - 1, y - 1) * 1.0;
			normal += texture2D(colortex3, uv + offset).rgb * edge_kernel[y * 3 + x];
		}
	}

	// Human eye sensitivity
	float grey = dot(color, vec3(0.21, 0.72, 0.07));
	float normalGrey = dot(abs(normal), vec3(1.0));

	float sobelLine = grey > LINE_THRESHOLD_CONTRAST ? 1.0 : 0.0;
	float depthLine = depth > LINE_THRESHOLD_DEPTH ? 1.0 : 0.0;
	float normalLine = normalGrey > LINE_THRESHOLD_NORMAL ? 1.0 : 0.0;
	float line = max(depthLine, sobelLine);
	line = max(line, normalLine);

	#ifdef MONOCHROME
	color = normalize(USER_COLOR) * line;
	#else
	color = normalize(color) * line;
	#endif

	#ifdef ENTITY_RADAR
		float entityMask = texture2D(colortex3, uv).a;

		#ifdef RADAR_FILLED
		bool doRadarColor = entityMask > 0.01;
		#else
		bool doRadarColor = line > 0.01;
		#endif
		
		if(doRadarColor) {
			color = equals(entityMask, 0.1, 0.01) ? ENTITY_COLOR_HOSTILE : color;
			color = equals(entityMask, 0.2, 0.01) ? ENTITY_COLOR_FRIENDLY : color;
			color = equals(entityMask, 0.3, 0.01) ? ENTITY_COLOR_PLAYER : color;
		}
	#endif

	gl_FragData[0] = vec4(color, 1.0);
}