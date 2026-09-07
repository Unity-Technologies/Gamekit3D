Shader "Hidden/Universal/GaussianBlur"
{
    HLSLINCLUDE
    
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        // The Blit.hlsl file provides the vertex shader (Vert),
        // the input structure (Attributes), and the output structure (Varyings)
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        float _BlurSize;

        // Horizontal blur fragment shader
        float4 HorizontalBlur(Varyings input) : SV_Target
        {
            float texelSize = _BlitTexture_TexelSize.x * _BlurSize;
            
            // Gaussian weights for a 9-tap filter
            float weights[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };
            
            float4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord) * weights[0];
            
            for (int i = 1; i < 5; i++)
            {
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, float2(input.texcoord.x + texelSize * i, input.texcoord.y)) * weights[i];
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, float2(input.texcoord.x - texelSize * i, input.texcoord.y)) * weights[i];
            }
            
            return color;
        }
    
        // Vertical blur fragment shader
        float4 VerticalBlur(Varyings input) : SV_Target
        {
            float texelSize = _BlitTexture_TexelSize.y * _BlurSize;
            
            // Gaussian weights for a 9-tap filter
            float weights[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };
            
            float4 color = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.texcoord) * weights[0];
            
            for (int i = 1; i < 5; i++)
            {
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, float2(input.texcoord.x, input.texcoord.y + texelSize * i)) * weights[i];
                color += SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, float2(input.texcoord.x, input.texcoord.y - texelSize * i)) * weights[i];
            }
            
            return color;
        }
        
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite Off Cull Off
        Pass
        {
            Name "BlurPassHorizontal"

            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment HorizontalBlur
            
            ENDHLSL
        }
        
        Pass
        {
            Name "BlurPassVertical"

            HLSLPROGRAM
            
            #pragma vertex Vert
            #pragma fragment VerticalBlur
            
            ENDHLSL
        }
    }
}