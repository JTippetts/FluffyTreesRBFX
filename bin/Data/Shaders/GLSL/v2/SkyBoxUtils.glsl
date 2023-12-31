	
#ifdef URHO3D_PIXEL_SHADER
#include "noise3d.glsl"

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
    float stepRadius = 1 - cRadii.x * cRadii.x;
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
	
	// map to sky texture
	nnormal.y *= 0.84375;
	nnormal.y += 0.15625;
	return texture(sGradients0, nnormal.xy *0.5 + 0.5).rgb;
}

vec3 skycolor()
{
	vec3 viewDir = normalize(vSkyPos);
	float sunViewDot = dot(cSunDir, viewDir);
	float sunZenithDot = cSunDir.y;
	float viewZenithDot = viewDir.y;
	float sunMoonDot = dot(cSunDir, cMoonDir);
	float sunViewDot01 = (sunViewDot + 1.0) * 0.5;
	float sunZenithDot01 = (sunZenithDot + 1.0) * 0.499;
	float horizon = step(0.01, vSkyPos.y);
	
	//vec3 sunZenithColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 0)).rgb;
	//vec3 viewZenithColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 1)).rgb;
	vec3 sunZenithColor = texture(sGradients0, vec2(sunZenithDot01, 0.013671875)).rgb;
	vec3 viewZenithColor = texture(sGradients0, vec2(sunZenithDot01, 0.02734375)).rgb;
	float vzMask = pow(clamp(1.0 - viewZenithDot, 0, 1), 4);
	//vec3 sunViewColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 2)).rgb;
	vec3 sunViewColor = texture(sGradients0, vec2(sunZenithDot01, 0.041015625)).rgb;
	float svMask = pow(clamp(sunViewDot,0,1), 4);

	vec3 skyColor = sunZenithColor + vzMask * viewZenithColor + svMask * sunViewColor;
	
	float sunMask = GetSunMask(sunViewDot, cRadii.x);
	#ifdef DRAW_SUN
		vec3 sunColor = cSunColor * sunMask;// * horizon;
	#else
		vec3 sunColor = vec3(0,0,0);
	#endif
	
	// The moon
	float moonIntersect = sphIntersect(viewDir, cMoonDir, cRadii.y);
	float moonMask = moonIntersect > -1 ? 1 : 0;
	#ifdef DRAW_MOON
		vec3 moonNormal = normalize(cMoonDir - viewDir * moonIntersect);
		float moonNdotL = clamp(dot(moonNormal, -cSunDir), 0, 1);
		vec3 moonTex = moonTexture(moonNormal);
		vec3 moonColor = vec3(moonMask * moonNdotL) * moonTex * 2.0;// * horizon;
	#else
		vec3 moonColor = vec3(0,0,0);
	#endif
	
	// Eclipse
	// Eclipse darkening
	float solarEclipse01 = smoothstep(1 - cRadii.x * cRadii.x, 1.0, sunMoonDot);
	skyColor *= mix(1, 0.4, solarEclipse01);
	sunColor *= (1 - moonMask) * mix(1, 16, solarEclipse01);
	
	#ifdef DRAW_STARS
		float starnoise = snoise(vSkyPos*80.0+12);
		float starmask = step(0.95, starnoise);
		//vec3 starColor = texture(sGradients0, vec3(snoise(vSkyPos*40.0+20), 0.5, 4)).rgb * starmask * horizon * max(0, min(1, -cSunDir.y)) * (1.0 - moonMask) * (1.0 - svMask);
		vec3 starColor = texture(sGradients0, vec2(snoise(vSkyPos*40.0+20), 0.068359375)).rgb * starmask * horizon * max(0, min(1, -cSunDir.y)) * (1.0 - moonMask) * (1.0 - svMask);
	#else
		vec3 starColor = vec3(0,0,0);
	#endif

	vec3 col = skyColor + sunColor + moonColor + starColor;
	
	// Clouds
	#ifdef DRAW_CLOUDS
		//vec3 cloudColor = texture(sGradients0, vec3(sunZenithDot01, 0.5, 3)).rgb; // TODO
		vec3 cloudColor = texture(sGradients0, vec2(sunZenithDot01, 0.0546875)).rgb; // TODO
	
		float density = smoothstep(1.0 - cCloudData.x, 1.0, fbm((vSkyPos.xyz / vSkyPos.y * 2.0 + cCloudData.w * 0.05)*0.3)) * 0.3;
		col.rgb = mix(col.rgb, cloudColor * 4.0, density * max(vSkyPos.y, 0.0));

		// Cumulus Clouds
		for (int i = 0; i < 3; i++)
		{
			density = smoothstep(1.0 - cCloudData.y, 1.0, fbm(((0.7 + float(i) * 0.01) * vSkyPos.xyz / vSkyPos.y + cCloudData.w * 0.3) * 0.2));
			col.rgb = mix(col.rgb, cloudColor * density * cCloudData.z, min(density*1.5, 1.0) * max(vSkyPos.y, 0.0));
		}
	#endif
	
	#ifdef DITHERING
		// dither a bit to reduce banding
		col.rgb += snoise(vSkyPos * 1000) * 0.01;
	#endif
	
	return col;
}
#endif