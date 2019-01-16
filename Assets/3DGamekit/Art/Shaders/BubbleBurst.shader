Shader "Custom/BubbleBurst" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_Color2 ("Emissive Color", Color) = (0,0,0,0)
		_Gradient ("Vertical Gradient", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Position ("pos", Vector) = (0,0,0,0)
	}
	SubShader {
		Tags { "Queue"="AlphaTest" "RenderType"="TransparentCutout" "IgnoreProjector"="True"}
		LOD 200

		Cull off

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _Gradient;

		struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float4 texcoord : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

		struct Input {
			float2 uv_Gradient;
			float lifetime;
			float3 worldPos;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color, _Color2;
		fixed4 _Position;

		inline float InverseLerp(float a, float b, float value)
        {
            return saturate((value - a) / (b - a));
        }

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void vert (inout appdata_t v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);

			o.lifetime = v.texcoord.z;
			float gradient = tex2Dlod(_Gradient, float4(v.texcoord.x, v.texcoord.y - InverseLerp(1, 0.9, v.texcoord.z), 0, 0)).r;
			float4 data = tex2Dlod(_Gradient, float4(v.texcoord.xy, 0,0));

			v.vertex.xz += v.normal.xz * data.g * 0.02 * (InverseLerp(0.3, 0.32, v.texcoord.z));
			v.vertex.xyz += v.normal * gradient * 0.45;
			v.vertex.y += v.normal * gradient * 0.25;
			
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color

			float gradient = tex2D (_Gradient, IN.uv_Gradient - InverseLerp(1, 0.9, IN.lifetime)).r;
			float noiseTex = tex2D (_Gradient, IN.uv_Gradient).b;
			o.Albedo = _Color;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = 0.5;
			o.Emission = _Color2;

			clip(1-gradient - gradient-noiseTex);
		}
		ENDCG
	}
	FallBack "Diffuse"
}
