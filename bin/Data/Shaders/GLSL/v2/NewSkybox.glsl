#ifndef UNLIT
    #define UNLIT
#endif
#define URHO3D_CUSTOM_MATERIAL_UNIFORMS
#define URHO3D_PIXEL_NEED_EYE_VECTOR

#include "_Config.glsl"
#include "_Uniforms.glsl"

UNIFORM_BUFFER_BEGIN(4, Material)
    DEFAULT_MATERIAL_UNIFORMS
    UNIFORM(vec3 cSunDir)
	UNIFORM(vec3 cMoonDir)
	UNIFORM(vec3 cSunColor)
	UNIFORM(float cSunRadius)
	UNIFORM(float cMoonRadius)
UNIFORM_BUFFER_END(4, Material)

#include "_Samplers.glsl"
#include "_VertexLayout.glsl"

#include "_VertexTransform.glsl"
#include "_GammaCorrection.glsl"

VERTEX_OUTPUT_HIGHP(vec3 vViewDir)
uniform sampler2DArray sGradients0;

#ifdef URHO3D_VERTEX_SHADER
void main()
{
    mat4 modelMatrix = GetModelMatrix();
    vec4 worldPos = vec4(iPos.xyz, 0.0) * modelMatrix;
    worldPos.xyz += cCameraPos;
    worldPos.w = 1.0;
    gl_Position = worldPos * cViewProj;
    gl_Position.z = gl_Position.w;
    vViewDir = normalize(iPos.xyz);
}
#endif

#ifdef URHO3D_PIXEL_SHADER

float GetSunMask(float sunViewDot, float sunRadius)
{
    float stepRadius = 1 - sunRadius * sunRadius;
    return step(stepRadius, sunViewDot);
}

// From Inigo Quilez, https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
float sphIntersect(vec3 rayDir, vec3 spherePos, float radius)
{
    vec3 oc = -spherePos;
    float b = dot(oc, rayDir);
    float c = dot(oc, oc) - radius * radius;
    float h = b * b - c;
    if(h < 0.0) return -1.0;
    h = sqrt(h);
    return -b - h;
}

void main()
{
	vec3 viewDir = normalize(vViewDir);
	float sunViewDot = dot(cSunDir, viewDir);
	float sunZenithDot = cSunDir.y;
	float viewZenithDot = viewDir.y;
	float sunMoonDot = dot(cSunDir, cMoonDir);
	float sunViewDot01 = (sunViewDot + 1.0) * 0.5;
	float sunZenithDot01 = (sunZenithDot + 1.0) * 0.499;
	
	vec3 sunZenithColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 0)).rgb;
	vec3 viewZenithColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 1)).rgb;
	float vzMask = pow(clamp(1.0 - viewZenithDot, 0, 1), 4);
	vec3 sunViewColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 2)).rgb;
	float svMask = pow(clamp(sunViewDot,0,1), 4);

	vec3 skyColor = sunZenithColor + vzMask * viewZenithColor + svMask * sunViewColor;
	
	float sunMask = GetSunMask(sunViewDot, cSunRadius);
    vec3 sunColor = cSunColor * sunMask;
	
	// The moon
	float moonIntersect = sphIntersect(viewDir, cMoonDir, cMoonRadius);
	float moonMask = moonIntersect > -1 ? 1 : 0;
	vec3 moonNormal = normalize(cMoonDir - viewDir * moonIntersect);
	float moonNdotL = clamp(dot(moonNormal, -cSunDir), 0, 1);
	vec3 moonColor = vec3(moonMask * moonNdotL);

	vec3 col = skyColor + sunColor + moonColor;

    gl_FragColor=GammaToLightSpaceAlpha(vec4(col,1));
}
#endif
