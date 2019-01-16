// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Skybox/Simple"
{
    Properties
    {
        _AmbientSky ("Ambient Sky", Color) = (0,0,1,1)
        _TopSkyFalloff("Sky Falloff", Float) = 8.5
        [Space]
        _AmbientHorizon ("Ambient Horizon", Color) = (1,0,1,1)
        [Space]
        _AmbientGround ("Ambient Ground", Color) = (0,1,0,1)
        _BottomSkyFalloff("Ground Falloff", Float) = 3.0

        _SkyIntensity("Sky Intensity", Float) = 1.0

        _SunIntensity("Sun Intensity", float) = 2.0

        _SunFalloff("Sun Falloff", float) = 550
        _SunSize("Sun Size", float) = 1

    }

    CGINCLUDE

    #include "UnityCG.cginc"
	#include "Lighting.cginc"

    struct appdata
    {
        float4 position : POSITION;
        float3 texcoord : TEXCOORD0;
    };
    
    struct v2f
    {
        float4 position : SV_POSITION;
        float3 texcoord : TEXCOORD0;
    };
    
    half4 _AmbientSky, _AmbientGround, _AmbientHorizon;
    half _TopSkyFalloff;    
    half _BottomSkyFalloff;

    half _SkyIntensity;

    half3 _SunColor, _SunDirection;
    half _SunIntensity;

    half _SunFalloff;
    half _SunSize;
    
    v2f vert(appdata v)
    {
        v2f o;
        o.position = UnityObjectToClipPos(v.position);
        o.texcoord = v.texcoord;
        return o;
    }
    
    half4 frag(v2f i) : COLOR
    {
        float3 v = normalize(i.texcoord);

        float p = v.y;
        float p1 = 1 - pow(min(1, 1 - p), _TopSkyFalloff);
        float p3 = 1 - pow(min(1, 1 + p), _BottomSkyFalloff);
        float p2 = 1 - p1 - p3;

        half3 c_sky = _AmbientSky * p1 + _AmbientHorizon * p2 + _AmbientGround * p3;
        half3 c_sun = _SunColor * min(pow(max(0, dot(v, _SunDirection)), _SunFalloff) * _SunSize, 1);

        return half4(c_sky * _SkyIntensity + c_sun * _SunIntensity, 0);
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Background" "Queue"="Background" }
        Pass
        {
            ZWrite Off
            Cull Off
            Fog { Mode Off }
            CGPROGRAM
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    } 
}