#define URHO3D_PIXEL_NEED_TEXCOORD
#define URHO3D_CUSTOM_MATERIAL_UNIFORMS


#define URHO3D_MATERIAL_ALBEDO URHO3D_TEXTURE_ALBEDO
#define URHO3D_MATERIAL_NORMAL URHO3D_TEXTURE_NORMAL
#define URHO3D_MATERIAL_PROPERTIES URHO3D_TEXTURE_PROPERTIES
#define URHO3D_MATERIAL_EMISSION URHO3D_TEXTURE_EMISSION

#include "_Config.glsl"
#include "_Uniforms.glsl"

UNIFORM_BUFFER_BEGIN(4, Material)
    DEFAULT_MATERIAL_UNIFORMS
	UNIFORM(vec4 cHeightMapData)
	// x: HeightMap width y: Heightmap height z: Height map xz spacing w: Heightmap y spacing
	UNIFORM(vec2 cRadius)
	// x: Outside radius y: Inside radius
	UNIFORM(vec4 cCoverageFactor)
	// Dot with coverage map texture
	UNIFORM(vec3 cCoverageParams)
	// x: Speckling/Sparsity  y: HeightVariance  z: Cell Size
	UNIFORM(vec2 cCoverageFade)
	UNIFORM(vec3 cActualCameraPos)
	UNIFORM(float cSeed)
	// x: Low y: High
	
	//UNIFORM(float cSpeckleFactor)
	//UNIFORM(float cHeightVariance)
UNIFORM_BUFFER_END(4, Material)

SAMPLER(1, sampler2D sHeightMap)
SAMPLER(2, sampler2D sCoverageMap)

VERTEX_OUTPUT_HIGHP(vec2 vHeightMapCoords)
VERTEX_OUTPUT_HIGHP(float vScaleValue)

#include "_Material.glsl"
#include "_DefaultSamplers.glsl"

#ifdef URHO3D_VERTEX_SHADER
mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec4 FAST_32_hash( vec2 gridcell )
{
	//    gridcell is assumed to be an integer coordinate
	const vec2 OFFSET = vec2( 26.0, 161.0 )+cSeed.xx;;
	const float DOMAIN = 71.0;
	const float SOMELARGEFLOAT = 951.135664;
	vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0.xx );
	P = P - floor(P * ( 1.0 / DOMAIN )) * DOMAIN;    //    truncate the domain
	P += OFFSET.xyxy;                                //    offset to interesting part of the noise
	P *= P;                                          //    calculate and return the hash
	return fract( P.xzxz * P.yyww * ( 1.0 / SOMELARGEFLOAT.x ).xxxx );
}

void main()
{
    VertexTransform vertexTransform = GetVertexTransform();
	mat4 modelMatrix = GetModelMatrix();
	
	vec2 trans=vec2(modelMatrix[0][3], modelMatrix[2][3]);
	vec2 cell=floor(trans * 1/cCoverageParams.z);
	
	vec4 hash=FAST_32_hash(cell);
	
	// Randomized rotation within cell
	mat4 rot=rotationMatrix(vec3(0,1,0), hash.x*6.283);
	
	// Randomized xz offset within cell
	rot[0][3]=sin(hash.w*6.28)*0.5*cCoverageParams.z;
	rot[2][3]=cos(hash.w*6.28)*0.5*cCoverageParams.z;
	
	vertexTransform.position = iPos * rot * modelMatrix;
	
	#ifndef URHO3D_SHADOW_PASS
		vertexTransform.normal = iNormal * GetNormalMatrix(rot*modelMatrix);
	#endif
	
	vec2 d=vertexTransform.position.xz - cActualCameraPos.xz;
	float dist=length(d)+(hash.w*16-8);
	dist=(dist-cRadius.y)/(cRadius.x-cRadius.y);
	dist=clamp(dist,0.0,1.0);
	
	vec2 t=vertexTransform.position.xz / cHeightMapData.z;
	vec2 htuv=vec2((t.x/cHeightMapData.x)+0.5, 1.0-((t.y/cHeightMapData.y)+0.5));
	vec4 htt=textureLod(sHeightMap2, htuv, 0.0);
	float ht=(htt.r*255.0 + htt.g) * cHeightMapData.w;
	
	float covscale=smoothstep(cCoverageFade.x, cCoverageFade.y, dot(textureLod(sCoverageMap3, htuv, 0.0), cCoverageFactor));
	//float covscale=step(0.4, dot(textureLod(sCoverageMap3, htuv, 0.0), cCoverageFactor));
	float y=vertexTransform.position.y*dist*covscale*(1+cCoverageParams.y*hash.y)*step(cCoverageParams.x, hash.z) + ht - 0.25;

	vertexTransform.position.y=y;
	vScaleValue=dist*covscale;
	
	#ifndef URHO3D_SHADOW_PASS
	ApplyShadowNormalOffset(vertexTransform.position, vertexTransform.normal);
	#endif
	
    Vertex_SetAll(vertexTransform, cNormalScale, cUOffset, cVOffset, cLMOffset);
}
#endif

#ifdef URHO3D_PIXEL_SHADER
void main()
{
	if(vScaleValue<=0.0001) discard;
#ifdef URHO3D_DEPTH_ONLY_PASS
    Pixel_DepthOnly(sAlbedo, vTexCoord);
#else
    SurfaceData surfaceData;

    Surface_SetCommon(surfaceData);
    Surface_SetAmbient(surfaceData, sEmission, vTexCoord2);
    Surface_SetNormal(surfaceData, vNormal, sNormal, vTexCoord, vTangent, vBitangentXY);
    Surface_SetPhysicalProperties(surfaceData, cRoughness, cMetallic, cDielectricReflectance, sProperties, vTexCoord);
    Surface_SetLegacyProperties(surfaceData, cMatSpecColor.a, sEmission, vTexCoord);
    Surface_SetCubeReflection(surfaceData, sReflection0, sReflection1, vReflectionVec, vWorldPos);
    Surface_SetPlanarReflection(surfaceData, sReflection0, cReflectionPlaneX, cReflectionPlaneY);
    Surface_SetBackground(surfaceData, sEmission, sDepthBuffer);
    Surface_SetBaseAlbedo(surfaceData, cMatDiffColor, cAlphaCutoff, vColor, sAlbedo, vTexCoord, URHO3D_MATERIAL_ALBEDO);
    Surface_SetBaseSpecular(surfaceData, cMatSpecColor, cMatEnvMapColor, sProperties, vTexCoord);
    Surface_SetAlbedoSpecular(surfaceData);
    Surface_SetEmission(surfaceData, cMatEmissiveColor, sEmission, vTexCoord, URHO3D_MATERIAL_EMISSION);
    Surface_ApplySoftFadeOut(surfaceData, vWorldDepth, cFadeOffsetScale);

    half3 surfaceColor = GetSurfaceColor(surfaceData);
    gl_FragColor = GetFragmentColorAlpha(surfaceColor, surfaceData.albedo.a, surfaceData.fogFactor);
#endif
}
#endif