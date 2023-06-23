#define URHO3D_PIXEL_NEED_TEXCOORD
#define URHO3D_VERTEX_HAS_TEXCOORD1
#define URHO3D_CUSTOM_MATERIAL_UNIFORMS

#include "_Config.glsl"
#include "_Uniforms.glsl"

UNIFORM_BUFFER_BEGIN(4, Material)
    DEFAULT_MATERIAL_UNIFORMS
    UNIFORM(float cBlend)
	UNIFORM(float cScale)
UNIFORM_BUFFER_END(4, Material)

#include "_Material.glsl"

#ifdef URHO3D_VERTEX_SHADER
void main()
{
    VertexTransform vertexTransform = GetVertexTransform();
	vec3 offset = (GetNormalMatrix(cView) ) * vec3(iTexCoord1*2-1, 0);
	vec3 newpos = vertexTransform.position.xyz + offset * cScale;
	vertexTransform.position.xyz = mix(vertexTransform.position.xyz, newpos, cBlend);
    FillVertexOutputs(vertexTransform);
}
#endif

#ifdef URHO3D_PIXEL_SHADER
void main()
{
#ifdef URHO3D_DEPTH_ONLY_PASS
    DefaultPixelShader();
#else
    SurfaceData surfaceData;

    FillSurfaceCommon(surfaceData);
    FillSurfaceNormal(surfaceData);
    FillSurfaceMetallicRoughnessOcclusion(surfaceData);
    FillSurfaceReflectionColor(surfaceData);
    FillSurfaceBackground(surfaceData);
    FillSurfaceAlbedoSpecular(surfaceData);
    FillSurfaceEmission(surfaceData);

    half3 surfaceColor = GetSurfaceColor(surfaceData);
    half surfaceAlpha = GetSurfaceAlpha(surfaceData);
    gl_FragColor = GetFragmentColorAlpha(surfaceColor, surfaceAlpha, surfaceData.fogFactor);
#endif
}
#endif