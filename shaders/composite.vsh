#version 150 compatibility

// #moj_import <light.glsl>
#include "/lib/settings.h"

in vec2 vaUV0;
// in ivec2 UV2;

// uniform sampler2D Sampler2;

out vec2 uv;
// out vec2 lightLevel;
// out vec4 vertexColor;

void main() {
	// vertexColor = Color * lightmap(Sampler2, UV2);
	// lightLevel = UV2;
	gl_Position = ftransform();
	uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}