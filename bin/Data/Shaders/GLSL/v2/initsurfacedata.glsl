// Initialize surfaceData

#ifdef URHO3D_PIXEL_SHADER
#ifndef URHO3D_DEPTH_ONLY_PASS
void InitSurfaceData(inout SurfaceData sd)
{
	sd.fogFactor = 0;
	sd.roughness = 1;
	sd.oneMinusReflectivity = 1.0;
	sd.occlusion = 1;
	sd.albedo = vec4(0,0,0,0);
	sd.specular = half3(0,0,0);
	
	#ifdef URHO3D_REFLECTION_MAPPING
    /// Reflection tint in gamma space for non-PBR renderer. In PBR renderer it's identical to specular color.
    sd.reflectionTint=half3(0,0,0);
	#endif
 
	#ifdef URHO3D_SURFACE_NEED_AMBIENT
    /// Ambient lighting for surface, including global ambient, vertex lights and lightmaps.
    sd.ambientLighting=half3(0,0,0);
	#endif

	#ifdef URHO3D_PIXEL_NEED_EYE_VECTOR
    /// Vector from surface to eye in world space.
    sd.eyeVec=half3(0,0,0);
	#endif

	#ifdef URHO3D_PIXEL_NEED_SCREEN_POSITION
    /// UV of depth or color background buffer corresponding to this fragment.
    sd.screenPos=vec2(0,0);
	#endif

	#ifdef URHO3D_SURFACE_NEED_NORMAL
    /// Normal in world space, with normal mapping applied.
    sd.normal=half3(0,0,0);
    /// Normal in tangent space. If there's no normal map, it's always equal to (0, 0, 1).
    sd.normalInTangentSpace=vec3(0,0,1);
	#endif

	#ifdef URHO3D_SURFACE_NEED_AMBIENT
    /// Emission color.
    sd.emission=half3(0,0,0);
	#endif

	#ifdef URHO3D_SURFACE_NEED_REFLECTION_COLOR
    /// Reflection color(s).
	for(int c = 0; c<URHO3D_NUM_REFLECTIONS; ++c)
	{
		sd.reflectionColor[c] = half4(0,0,0,0);
	}
	#endif

	#ifdef URHO3D_SURFACE_NEED_BACKGROUND_COLOR
    /// Color of background object.
    sd.backgroundColor=half3(0,0,0);
	#endif

	#ifdef URHO3D_SURFACE_NEED_BACKGROUND_DEPTH
    /// Depth of background object.
    sd.backgroundDepth=0;
	#endif
	//return sd;
}
#endif
#endif