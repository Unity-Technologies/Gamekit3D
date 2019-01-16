 // Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/StandardAlphaFade" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_AmbientColor ("Ambient Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Normal ("Normal ", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_NormalSacle ("Normal Scale", Float) = 0.5
		_MovementSpeed ("Movement Speed", Float) = 0.75
		_InvFade ("Soft Particles Factor", Range(0.01, 10.0)) = 1.0
		[Toggle] _Cutout ("Use Clip", Float) = 1
	}
	SubShader {
		Tags { "Queue"="Transparent" "RenderType"="Transparent" "IgnoreProjector"="True"}
		LOD 200
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows alpha:fade vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		#pragma multi_compile __ _CUTOUT_ON

		#include "UnityCG.cginc"



		sampler2D _MainTex;
		sampler2D _Normal;
		sampler2D _RenderTexure;

		struct Input {
			float2 uv_MainTex;
			float2 uv_Normal;
			float4 projectedPosition : TEXCOORD3;
			float4 color : COLOR;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color, _AmbientColor;
		half _NormalSacle;
		float _InvFade;
		half _MovementSpeed;


		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			float4 clipPosition = UnityObjectToClipPos(v.vertex);
			o.projectedPosition = ComputeScreenPos  (clipPosition);
   			COMPUTE_EYEDEPTH(o.projectedPosition.z);
		}

		sampler2D_float _CameraDepthTexture;

		void surf (Input IN, inout SurfaceOutputStandard o) {


			float sceneDepth = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.projectedPosition)));
			float projZ = IN.projectedPosition.z;
			float fade = saturate (_InvFade * (sceneDepth-projZ));
	
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb * IN.color;
			float2 normalUVs = IN.uv_Normal;
			normalUVs.x += _Time * _MovementSpeed;
			normalUVs.y -= _Time * _MovementSpeed;
			o.Normal = UnpackScaleNormal (tex2D (_Normal, normalUVs), _NormalSacle);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a * fade * IN.color.a;
			o.Emission = _AmbientColor;
			#if _CUTOUT_ON
			clip(c.a - (1-IN.color.a));
			#endif

		}
		ENDCG
	}
	FallBack "Diffuse"
}
