// For specific code targetting the shader graph preview, use the following
// #if defined(SHADERGRAPH_PREVIEW)

// This is used by the Alien shader, creates a crystal like parallax effect
void InnerStructureParallax_float(
    in float2 uvPackedMap,
    in float3 viewDir,
    in float marchDistance,
    in float numSteps,
    in UnityTexture2D PackedMap,
    in UnityTexture2D Ramp2,
    out float3 InnerStructure)
{
    InnerStructure = float3(0, 0, 0);
    float2 UV = uvPackedMap;
    float offset = 1;
    for (float d = 0.0; d < marchDistance; d += marchDistance / numSteps)
    {
        UV.xy -= (viewDir.xy*d)/numSteps * tex2D(PackedMap, uvPackedMap).r;
        float Ldensity = tex2D(PackedMap, UV).r;
        InnerStructure += saturate(Ldensity) * tex2D(Ramp2, float2(1.0f / numSteps * offset, 0.5)).rgb;
        offset ++;
    }
}

// Helper to retrieve the intensity of the main light, which
// is not currently available as a node in URP
void GetMainLightIntensity_float(out float lightIntensity)
{
    #if defined(_ADDITIONAL_LIGHTS) || defined(_ADDITIONAL_LIGHTS_VERTEX) 
    Light mainLight = GetMainLight(); 
    lightIntensity = saturate(length(mainLight.color)*mainLight.shadowAttenuation);
    #else
    lightIntensity = 1;
    #endif
}

// This calculates the parallax effect for the eye shader
void CalculateUVOffset_float(float3 lightDir, float3 viewDir, float3 normal, float2 uv,
    float parallax,
    in Texture2D maskTexture,
    in SamplerState maskTextureSampler,
    out float2 uvOffset)
{
    float limit = (-length(viewDir.xy) / viewDir.z) * parallax;
    float2 uvDir = normalize(viewDir.xy);
    float2 maxUVOffset = uvDir * limit;

    //choose the amount of steps we need based on angle to surface.
    int maxSteps = lerp(40, 5, clamp(dot(viewDir, normal), 0, 1));
    float rayStep = 1.0 / (float)maxSteps;

    // dx and dy effectively calculate the UV size of a pixel in the texture.
    // x derivative of mask uv
    float2 dx = ddx(uv); 
    // y derivative of mask uv
    float2 dy = ddy(uv);

    float rayHeight = 1.0;
    uvOffset = 0;
    float currentHeight = 1;
    float2 stepLength = rayStep * maxUVOffset;

    int step = 0;
    //search for the occluding uv coord in the heightmap
    while (step < maxSteps && currentHeight <= rayHeight)
    {
        step++;
        currentHeight = maskTexture.SampleGrad(maskTextureSampler, uv + uvOffset, dx, dy).a;	
        rayHeight -= rayStep;
        uvOffset += stepLength;
    }
}

