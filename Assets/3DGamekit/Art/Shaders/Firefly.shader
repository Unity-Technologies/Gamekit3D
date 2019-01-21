 // Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/Firefly" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		[hdr]_EmissionColor ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Emission ("_Emission", 2D) = "white" {}
		_Normal ("Normal", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Specular ("Specular", Range(0,1)) = 0.0
		_Wings ("Wings (RGBA)", 2D) = "white" {}
		_WingGloss ("Wing Smoothness", Range(0,1)) = 0.5
		_WingSpecular ("Wing Specular", Range(0,1)) = 0.0
		
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf StandardSpecular 
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _Normal;
		sampler2D _Emission;

		struct Input {
			float2 uv2_MainTex;
			float3 color : COLOR;
		};


		half _Glossiness;
		half _Specular;
		fixed4 _Color, _EmissionColor;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {

			fixed4 c = tex2D (_MainTex, IN.uv2_MainTex) * _Color;
			o.Normal = UnpackNormal (tex2D (_Normal, IN.uv2_MainTex));
			o.Albedo = c.rgb;
			o.Specular = _Specular;
			o.Smoothness = _Glossiness;
			o.Emission = tex2D (_Emission, IN.uv2_MainTex).r * _EmissionColor;
			clip(1-IN.color - 0.5);
		}
		ENDCG

		Cull Off

		CGPROGRAM
		#pragma surface surf StandardSpecular  alpha:fade
		#pragma target 3.0

		//sampler2D _MainTex;
		sampler2D _Wings;

		struct Input {
			float2 uv_Wings;
			//float2 uv2_MainTex;
			float3 color : COLOR;
		};


		half _WingGloss;
		half _WingSpecular;
		fixed4 _Color;


		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {

			fixed4 wings = tex2D (_Wings, IN.uv_Wings) * _Color;
			o.Albedo = wings.rgb;
			o.Specular = _WingSpecular;
			o.Smoothness = _WingGloss;
			o.Alpha = lerp(0, wings.a, (float)IN.color);
		}
		ENDCG

       
	}
	FallBack "Diffuse"
}
