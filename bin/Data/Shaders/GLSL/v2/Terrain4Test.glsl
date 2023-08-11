#define URHO3D_CUSTOM_MATERIAL_UNIFORMS
#define URHO3D_VERTEX_NEED_TANGENT
#define URHO3D_PIXEL_NEED_TANGENT


#include "_Config.glsl"
#include "_Uniforms.glsl"

UNIFORM_BUFFER_BEGIN(4, Material)
    DEFAULT_MATERIAL_UNIFORMS
	
UNIFORM_BUFFER_END(4, Material)

#include "_Material.glsl"

#ifdef URHO3D_VERTEX_SHADER
void main()
{
    VertexTransform vertexTransform = GetVertexTransform();
    Vertex_SetAll(vertexTransform, cNormalScale, cUOffset, cVOffset, cLMOffset);	
}
#endif

#ifdef URHO3D_PIXEL_SHADER

void main()
{
    SurfaceData surfaceData;
	
	Surface_SetCommon(surfaceData);
	Surface_SetAmbient(surfaceData, sEmission, vTexCoord2);
	Surface_SetPhysicalProperties(surfaceData, cRoughness, cMetallic, cDielectricReflectance, sProperties, vTexCoord);
	Surface_SetLegacyProperties(surfaceData, cMatSpecColor.a, sEmission, vTexCoord);
	Surface_SetBaseSpecular(surfaceData, cMatSpecColor, cMatEnvMapColor, sProperties, vTexCoord);
	Surface_SetAlbedoSpecular(surfaceData);

	vec3 normal = normalize(vNormal);
	
	vec3 bt = normalize(vec3(vBitangentXY.xy, 0));
	gl_FragColor = vec4(bt,1);
}
#endif
