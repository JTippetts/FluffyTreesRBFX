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
	UNIFORM(mat3 cMoonTransform)
UNIFORM_BUFFER_END(4, Material)

#include "_Samplers.glsl"
#include "_VertexLayout.glsl"

#include "_VertexTransform.glsl"
#include "_GammaCorrection.glsl"

#include "noise3d.glsl"

VERTEX_OUTPUT_HIGHP(vec3 vViewDir)
VERTEX_OUTPUT_HIGHP(vec3 vPos)
uniform sampler2DArray sGradients0;
uniform sampler2D sMoonDiff1;

#ifdef URHO3D_VERTEX_SHADER
void main()
{
    mat4 modelMatrix = GetModelMatrix();
    vec4 worldPos = vec4(iPos.xyz, 0.0) * modelMatrix;
    worldPos.xyz += cCameraPos;
    worldPos.w = 1.0;
	vPos = normalize(iPos.xyz);
    gl_Position = worldPos * cViewProj;
    gl_Position.z = gl_Position.w;
    vViewDir = normalize(iPos.xyz);
}
#endif

#ifdef URHO3D_PIXEL_SHADER

const mat3 fbmm = mat3(0.0, 1.60,  1.20, -1.6, 0.72, -0.96, -1.2, -0.96, 1.28);
	float fbm(vec3 p)
	{
		float f = 0.0;
		f += snoise(p) / 2; p = fbmm * p * 1.0;
		f += snoise(p) / 4; p = fbmm * p * 1.1;
		f += snoise(p) / 6; p = fbmm * p * 1.2;
		f += snoise(p) / 12; p = fbmm * p * 1.3;
		f += snoise(p) / 24;
		return f;
	}

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

vec3 moonTexture(vec3 normal)
{
	vec3 nnormal = normal * cMoonTransform;
	vec2 tc;
	tc = nnormal.xy * 0.5 + 0.5;
	
	// Equirectangular projection
	//tc.y = nnormal.y;
   // tc.x = normalize(nnormal).x * 0.5;

   // float s = sign(nnormal.z) * 0.5;

    //tc.s = 0.75 - s * (0.5 - tc.s);
    //tc.t = 0.5 + 0.5 * tc.t;
	return texture(sMoonDiff1, tc).rgb;
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
    vec3 sunColor = cSunColor * sunMask * step(0.01, vPos.y);
	
	// The moon
	float moonIntersect = sphIntersect(viewDir, cMoonDir, cMoonRadius);
	float moonMask = moonIntersect > -1 ? 1 : 0;
	vec3 moonNormal = normalize(cMoonDir - viewDir * moonIntersect);
	float moonNdotL = clamp(dot(moonNormal, -cSunDir), 0, 1);
	vec3 moonTex = moonTexture(moonNormal);
	vec3 moonColor = vec3(moonMask * moonNdotL) * moonTex * step(0.01, vPos.y);
	//vec3 moonColor = moonTex*moonMask*0.5;
	
	vec3 stars = (mix(0, step(0.95, snoise(vPos*40.0)), step(0.01, vPos.y)).xxx * max(0, min(1, -cSunDir.y))) * (1.0 - moonMask) * (1.0 - svMask);

	vec3 col = skyColor + sunColor + moonColor + stars;
	
	vec3 cloudColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 3)).rgb; // TODO
	float cirrus = 1.5;
	float cumulus = 1.5;
	float cumulusbright = 1.0;
	float cloudtime = 1.0;
	
	float density = smoothstep(1.0 - cirrus, 1.0, fbm((vPos.xyz / vPos.y * 2.0 + cloudtime * 0.05)*0.3)) * 0.3;
	col.rgb = mix(col.rgb, cloudColor * 4.0, density * max(vPos.y, 0.0));

	// Cumulus Clouds
	for (int i = 0; i < 3; i++)
	{
		density = smoothstep(1.0 - cumulus, 1.0, fbm(((0.7 + float(i) * 0.01) * vPos.xyz / vPos.y + cloudtime * 0.3) * 0.3));
		//density = smoothstep(1.0 - cumulus, 1.0, fbm((0.7 + float(i) * 0.01) * pos.xyz / pos.y + cloudtime * 0.3));
		col.rgb = mix(col.rgb, cloudColor * density * cumulusbright, min(density*1.5, 1.0) * max(vPos.y, 0.0));
	}
	
	// dither a bit
	col.rgb += snoise(vPos * 1000) * 0.01;

    gl_FragColor=GammaToLightSpaceAlpha(vec4(col,1));
}
#endif
