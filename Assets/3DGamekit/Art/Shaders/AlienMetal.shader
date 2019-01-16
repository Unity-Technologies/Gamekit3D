// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/AlienMetal" {
	Properties {
		[HDR] _EmissiveColor ("EmissiveColor", Color) = (1,1,1,1)
		_Albedo ("Albedo (RGB) EdgeMask (A)", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_RimPower("Rim Power", Range(0.1,7.0)) = 3.0
		_EffectAmount("Effect Amount", Range(0.0 ,1.0)) = 0.2
		_EmissiveTex ("Emisssive (RGB)", 2D) = "black" {}
		_MetallicSmooth ("Metallic (RGB) Smooth(A)", 2D) = "white" {}
		_Ramp("Ramp", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _Albedo;
		sampler2D _Ramp;
		sampler2D _NormalMap;
		sampler2D _EmissiveTex;
		sampler2D _MetallicSmooth;

		struct Input {
			float2 uv_Albedo;
			float3 viewDir;
		};

		fixed4 _Color;
		float4 _EmissiveColor;
		float _RimPower;
		float _EffectAmount;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandard o) {

			o.Normal = UnpackNormal (tex2D (_NormalMap, IN.uv_Albedo));

			half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));

			fixed4 a = tex2D (_Albedo, IN.uv_Albedo);
			fixed4 g = tex2D (_MetallicSmooth, IN.uv_Albedo);
			//fixed4 col = a + tex2D(_Ramp, float2(pow(rim, _RimPower), 0.5)) * a.a * _EffectAmount;
			float rimPow = lerp(0.1, 1.0, dot(normalize(IN.viewDir), o.Normal));
			fixed4 col = a + tex2D(_Ramp, float2(pow(rim, rimPow*_RimPower), 0.5)) * a.a * _EffectAmount;

			o.Albedo = col.rgb;
			o.Metallic =  g.r;
			o.Smoothness = g.a;
			o.Emission = tex2D (_EmissiveTex, IN.uv_Albedo) * _EmissiveColor;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
