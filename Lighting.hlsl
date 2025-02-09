void ToonShading_float(in float3 Normal, in float ToonRampSmoothness, in float3 ClipSpacePos, in float3 WorldPos,
                       in float3 ToonRampTinting, in float ToonRampOffset, in float ToonRampOffsetPoint,
                       in float Ambient, out float3 ToonRampOutput, out float3 Direction)
{
#ifdef SHADERGRAPH_PREVIEW
    ToonRampOutput = float3(0.5, 0.5, 0);
    Direction = float3(0.5, 0.5, 0);
#else

    // Grab shadow coordinates
#if SHADOWS_SCREEN
    half4 shadowCoord = ComputeScreenPos(ClipSpacePos);
#else
    half4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
#endif 

    // Get main light
#if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
    Light light = GetMainLight(shadowCoord);
#else
    Light light = GetMainLight();
#endif

    // Toon shading step function for hard cutoff
    half d = dot(Normal, light.direction);
    half toonRamp = step(ToonRampOffset, d); // Hard shading instead of smoothstep

    // Rim lighting effect for a toon edge glow
    float rim = 1.0 - saturate(dot(Normal, normalize(WorldPos)));
    rim = smoothstep(0.5, 1.0, rim) * 0.5;

    // Handle additional lights
    float3 extraLights = float3(0, 0, 0);
    int pixelLightCount = GetAdditionalLightsCount();
    for (int j = 0; j < pixelLightCount; ++j)
    {
        Light aLight = GetAdditionalLight(j, WorldPos);
        float3 attenuatedLightColor = aLight.color * (aLight.distanceAttenuation * aLight.shadowAttenuation);
        half d = dot(Normal, aLight.direction);
        half toonRampExtra = step(ToonRampOffsetPoint, d);
        extraLights += (attenuatedLightColor * toonRampExtra);
    }

    // Apply main light and shadows
    toonRamp *= light.shadowAttenuation;

    // Final color output with strong contrast
    ToonRampOutput = light.color * (toonRamp + ToonRampTinting) + Ambient + rim;
    ToonRampOutput += extraLights;

    // Set direction for rim light effect
    Direction = normalize(light.direction);

#endif
}
