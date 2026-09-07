 // Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/Translucency" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_RimColor("Rim Color", Color) = (0.26,0.19,0.16,0.0)
		_SpecCol("Spec Color", Color) = (0.26,0.19,0.16,0.0)
		_NormalMap("Normal Map", 2D) = "bump" {}
		_RimPower("Rim Power", Range(0.1,7.0)) = 3.0
		_RimPower2("Rim Power2", Range(0.1,7.0)) = 3.0
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		[HDR] _EmissiveColor ("EmissiveColor", Color) = (1,1,1,1)
		_EmissiveTex ("Emisssive (RGB)", 2D) = "white" {}
		_SpecGloss ("Spec (RGB) Gloss(A)", 2D) = "white" {}
		_Ramp("Ramp", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Specular ("Specular", Range(0,1)) = 0.0
		_MaxDiff ("Max Diff", Range(0,1)) = 0.3
		[Toggle] _VertexAnimate ("Vertex Animation?", Float) = 0
	}
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf StandardSpecular vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 4.0

		#pragma multi_compile __ _VERTEXANIMATE_ON

		sampler2D _MainTex;
		sampler2D _EmissiveTex;
		sampler2D _SpecGloss;
		sampler2D _NormalMap;
		sampler2D _NormalMap2;
		sampler2D _Ramp;

		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
			float3 viewDir;
			float eyeDepth;
		};

		half _Glossiness;
		half _Specular;
		float _MaxDiff;
		fixed4 _Color;
		float4 _RimColor;
		float _RimPower2;
		float4 _SpecCol;
		half3  _EmissiveColor;
		float _RimPower;
		sampler2D_float _CameraDepthTexture;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v, out Input o)
		{
			#ifdef _VERTEXANIMATE_ON
			v.vertex.xyz += v.normal * (sin(_Time[3]+v.vertex.y*5) * 0.0125) * v.color.r;
			v.vertex.x +=  (sin(_Time[3]*5) * 0.0125) * v.color.g;
			#endif
			UNITY_INITIALIZE_OUTPUT(Input, o);
			COMPUTE_EYEDEPTH(o.eyeDepth);
		}

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) 
		{
			float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
			float depth = LinearEyeDepth(rawZ);
			float diff = depth - IN.eyeDepth;
			float ratio = 0.0f;
			if(rawZ > 0.0f)
				ratio = 1.0f - smoothstep(0.0, _MaxDiff, diff);


			//o.Albedo = tex2D(_Ramp, float2(ratio, 0.5)) * tex2D(_MainTex, IN.uv_MainTex); // c.rgb;
			
			// Metallic and smoothness come from slider variables
			o.Normal = UnpackNormal (tex2D (_NormalMap, IN.uv_MainTex));
			fixed4 specGloss= tex2D(_SpecGloss, IN.uv_MainTex);
			fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);

			half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
			o.Specular = _Specular * tex2D(_Ramp, float2(pow(rim, _RimPower), 0.5));


			o.Smoothness = specGloss.a * _Glossiness;

			//half rim = saturate(dot(normalize(IN.viewDir), o.Normal));
			o.Albedo = lerp(albedo, albedo*_Color, ratio*pow(rim, _RimPower2));
			o.Emission = tex2D(_EmissiveTex, IN.uv_MainTex) * _EmissiveColor;

			//half rim = 1.0 - saturate(dot(normalize(IN.viewDir), o.Normal));
			//o.Emission = _RimColor.rgb * pow(rim, _RimPower);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
