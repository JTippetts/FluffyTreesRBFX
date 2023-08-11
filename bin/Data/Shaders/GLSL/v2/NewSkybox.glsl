#ifndef UNLIT
    #define UNLIT
#endif
#define URHO3D_CUSTOM_MATERIAL_UNIFORMS
#define URHO3D_PIXEL_NEED_EYE_VECTOR

#define DRAW_SUN
#define DRAW_MOON
#define DRAW_STARS
#define DRAW_CLOUDS
#define DITHERING

#include "_Config.glsl"
#include "_Uniforms.glsl"

UNIFORM_BUFFER_BEGIN(4, Material)
    DEFAULT_MATERIAL_UNIFORMS
	UNIFORM(vec3 cSunDir)
	UNIFORM(vec3 cMoonDir)
	UNIFORM(vec3 cSunColor)
	UNIFORM(vec2 cRadii) 
	// Sun=x Moon=y
	UNIFORM(mat3 cMoonTransform)
	UNIFORM(vec4 cCloudData)
	//x = Cirrus (high cloud) density
	//y = Cumulus (low cloud) density
	//z = Cumulus brightness
	//w = Cloud animation time
UNIFORM_BUFFER_END(4, Material)

//#include "_Samplers.glsl"
#include "_VertexLayout.glsl"
#include "_VertexTransform.glsl"
#include "_GammaCorrection.glsl"


VERTEX_OUTPUT_HIGHP(vec3 vViewDir) 
VERTEX_OUTPUT_HIGHP(vec3 vSkyPos)
SAMPLER(1, sampler2D sGradients0)
//uniform sampler2D sGradients0; 
//uniform sampler2D sMoonDiff1;

#include "SkyBoxUtils.glsl"

#ifdef URHO3D_VERTEX_SHADER
void main()
{
    mat4 modelMatrix = GetModelMatrix();
	vSkyPos = normalize(iPos.xyz);
	
	vec4 worldPos = vec4(iPos.xyz, 0.0) * modelMatrix;
    worldPos.xyz += cCameraPos;
    worldPos.w = 1.0;
    gl_Position = worldPos * cViewProj;
    gl_Position.z = gl_Position.w;
}
#endif

#ifdef URHO3D_PIXEL_SHADER
void main()
{
	vec3 sky = skycolor();

    gl_FragColor=GammaToLightSpaceAlpha(vec4(sky,1));
}
#endif
