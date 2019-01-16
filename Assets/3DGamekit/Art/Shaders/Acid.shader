Shader "Custom/Acid" {
	Properties {
		_Color1 ("Color1", Color) = (1,1,1,1)
		_Color2 ("Color2", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Ramp ("Ramp (RGB)", 2D) = "white" {}
		_Normal ("Normal", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Noise ("Noise)", 2D) = "white" {}

		_Edge ("Edge Size", Float) = 1.0
		_Fog ("Fog", Float) = 1.0
		_Fade ("Edge Fade", Float) = 1.0
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		LOD 200

		GrabPass { }

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard noshadow nolightmap vertex:vert alpha:blend

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex, _Normal, _Ramp, _Noise;

		UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

		struct Input {
			float2 uv_MainTex;
			float2 uv_Normal;

			float4 projPos;
			float4 grabPos;
			float3 worldPos;
			float2 localDir;
			float3 worldRefl;
			float4 screenPos;
			float3 viewDir;
			float depth;

		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color1, _Color2;
		half _Edge, _Fade, _Fog;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		inline float InverseLerp(float a, float b, float value)
        {
            return saturate((value - a) / (b - a));
        }


		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);

			o.localDir = v.vertex.xz;
			float4 vertex = UnityObjectToClipPos(v.vertex);
            o.projPos = ComputeScreenPos (vertex);
			COMPUTE_EYEDEPTH(o.projPos.z);
            o.grabPos = ComputeGrabScreenPos(vertex);
			float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
			float3 relPos = worldPos.xyz - _WorldSpaceCameraPos.xyz;
			o.depth = length(relPos);
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color

			float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.projPos)));
			float partZ = IN.projPos.z;
			float zDiff = abs(sceneZ-partZ);
			float edge = InverseLerp(_Edge, 0, zDiff);
			float fog = 1-InverseLerp(_Fog, 0, zDiff);
			float fade = InverseLerp(_Fade, 0, zDiff);

			float2 UV2 = IN.uv_Normal;
			UV2.x += _Time*0.2;
			UV2.y += _Time*0.1;
			UV2 *= 0.5;
			
			
			float3 normal = UnpackScaleNormal(tex2D (_Normal, UV2), 1);

			float2 UV = IN.uv_MainTex;
			UV.y += _Time*0.2;
			UV += normal*0.2;

			float2 UV3 = IN.uv_MainTex;
			UV3.y += _Time*1;
			UV3 += normal;

			float noiseTex = tex2D(_Noise, UV3*0.2);
			float blend = tex2D(_MainTex, UV).r;
			
			//fixed4 c = lerp(_Color1, _Color2, pow(blend, 2));
			fixed4 c = tex2D(_Ramp, float2(blend, 0));
			c = lerp(c, _Color2, edge);
			float FogEdge = smoothstep(noiseTex, noiseTex + 1, fog);
			//fixed4 fogc = tex2D(_Ramp, float2(fog, 0));
			fixed4 fogc = lerp(_Color2, _Color1, fog * FogEdge);
			c += fogc;
			fixed4 emission = lerp(0, _Color2, pow(blend, 2));
			fixed roughness = lerp(1, 0, blend);

			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Normal = normal;
			o.Smoothness = roughness * _Glossiness;
			//o.Alpha = c.a;
			//o.Emission = emission.rgb;
			//o.Alpha = zDiff;

			float distanceAlpha = 1-InverseLerp(0.5*0.7, 0.5, IN.depth);

 			o.Alpha = 1-fade;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
