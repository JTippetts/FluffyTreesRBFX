#define SIMPLEX_NOISE_FUNCTION

#include "noise3D.glsl"

#ifdef SCATTERING

//#ifdef URHO3D_VERTEX_SHADER
	vec3 CalculateSunPos(float timeofday)
	{
		return vec3(0.0, sin(timeofday * 0.2617993875), cos(timeofday * 0.2617993875));
	}
//#endif

//#ifdef URHO3D_PIXEL_SHADER
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
	
	vec4 CalculateScattering(float Br, float Bm, float g, vec3 pos, vec3 fsun, inout vec3 extinction)
	{
		const vec3 nitrogen = vec3(0.650, 0.570, 0.475);
		vec3 Kr = Br / pow(nitrogen, vec3(4.0));
		vec3 Km = Bm / pow(nitrogen, vec3(0.84));
		vec4 color=vec4(0,0,0,1);
	
		g=mix(1, g, smoothstep(-0.01, 0, pos.y));
		pos.y = max(0, pos.y);
		// Atmosphere Scattering
		float mu = dot(normalize(pos), normalize(fsun));
		float rayleigh = 3.0 / (8.0 * 3.14) * (1.0 + mu * mu);
		vec3 mie = (Kr + Km * (1.0 - g * g) / (2.0 + g * g) / pow(1.0 + g * g - 2.0 * g * mu, 1.5)) / (Br + Bm);

		vec3 day_extinction = exp(-exp(-((pos.y + fsun.y * 4.0) * (exp(-pos.y * 16.0) + 0.1) / 80.0) / Br) * (exp(-pos.y * 16.0) + 0.1) * Kr / Br) * exp(-pos.y * exp(-pos.y * 8.0 ) * 4.0) * exp(-pos.y * 2.0) * 4.0;
		vec3 night_extinction = vec3(1.0 - exp(fsun.y)) * 0.2;
		float stars=mix(0, step(0.95, snoise(pos*40.0)), step(0.01, pos.y));
	
		extinction = mix(day_extinction, night_extinction, -fsun.y * 0.2 + 0.5);
		color.rgb = rayleigh * mie * extinction + stars.xxx * max(0, min(1, -fsun.y));
	
		return color;
	} 
	
	vec4 CalculateSkyAndClouds(float Br, float Bm, float g, float cirrus, float cumulus, float cumulusbright, float cloudtime, vec3 pos, vec3 fsun)
	{
		vec3 extinction;
		vec4 color=CalculateScattering(Br, Bm, g, pos, fsun, extinction);
	
		// Cirrus Clouds
		//float density = smoothstep(1.0 - cirrus, 1.0, fbm((pos.xyz / pos.y * 2.0 + cloudtime * 0.05)) * 0.5) * 0.3;
		float density = smoothstep(1.0 - cirrus, 1.0, fbm((pos.xyz / pos.y * 2.0 + cloudtime * 0.05)*0.3)) * 0.3;
		color.rgb = mix(color.rgb, extinction * 4.0, density * max(pos.y, 0.0));

		// Cumulus Clouds
		for (int i = 0; i < 3; i++)
		{
			density = smoothstep(1.0 - cumulus, 1.0, fbm(((0.7 + float(i) * 0.01) * pos.xyz / pos.y + cloudtime * 0.3) * 0.3));
			//density = smoothstep(1.0 - cumulus, 1.0, fbm((0.7 + float(i) * 0.01) * pos.xyz / pos.y + cloudtime * 0.3));
			color.rgb = mix(color.rgb, extinction * density * cumulusbright, min(density*1.5, 1.0) * max(pos.y, 0.0));
		}

		// Dithering Noise
		color.rgb += snoise(pos * 1000) * 0.01;
		color.a=1;
		#ifdef EXTINCTION
			color.rgb = extinction;
		#endif
		return color;
	}
//#endif

#endif