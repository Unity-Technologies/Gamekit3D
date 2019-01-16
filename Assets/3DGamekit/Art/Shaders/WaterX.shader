// Upgrade NOTE: replaced '_CameraToWorld' with 'unity_CameraToWorld'

// Upgrade NOTE: replaced 'unity_World2Shadow' with 'unity_WorldToShadow'

// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/WaterX" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_ShadowColor ("Shadow Color", Color) = (0.5,0.5,0.5,1)
		_ShadowFade ("Shadow Fade", Range(0,1)) = 0.5
		[NoScaleOffset]
		_ScumTex ("Scum (RGB)", 2D) = "white" {}
		_ScumScale ("Scum Scale", Float) = 0.0325
		_ScumNoiseScale ("Scum Noise Scale", Float) = 0.0325
		_ScumFalloff ("Scum Falloff", Float) = 0.5

		_FoamTex ("Foam (RGB)", 2D) = "white" {}
		_FoamColor ("FoamColor", Color) = (1,1,1,1)
		_FoamScale ("Foam Scale", Float) = 1
		_FoamDepth ("Foam Depth", Float) = 2
		_FogDepth ("Fog Depth", Float) = 5
		_EdgeBlend ("Edge Blend", Range(0,1)) = 0.25
		_DepthBlur ("Depth Blur", Float) = 1
		_Turbulence ("Turbulence", Range(0,1)) = 1
		_WaveHeight ("Wave Height", Float) = 1
		_WaveLength ("Inv Wave Length", Float) = 200
		_WaveFrequency ("Wave Frequency", Float) = 10
		_Speed ("Speed", Float) = 1
		_Focus ("Focus", Range(-1000.0, 1000.0)) = -100.0
		_Noise ("Noise", 2D) = "white" {}
		_Ripples("Ripples", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_ExtraEmission ("Emission", Range(0,1)) = 0.0
		[HideInInspector] _ReflectionTex ("", 2D) = "white" {}
		_Bias ("F Bias", Float) = 1
		_Power ("F Power", Float) = 1
		_Scale ("F Scale", Float) = 1
		_WaterCullDistance ("Water Cull Distance", Float) = 1000
	}

	
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		ZWrite Off
		Cull Back
		LOD 200
		
		GrabPass { }
		
		
		CGPROGRAM
		
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf BlinnPhong noshadow novertexlights nolightmap vertex:vert alpha:blend

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0
		

		sampler2D _MainTex;
		sampler2D _FoamTex, _ScumTex;
		sampler2D _Noise;
		sampler2D _Ripples;
		sampler2D _GrabTexture;
		sampler2D _ReflectionTex;
		sampler2D _DirectionalShadowMask;

		half4 _GrabTexture_TexelSize;
		half4 _ReflectionTex_TexelSize;
		
		float _WaterCullDistance;
		float4 _MainTex_TexelSize;

		UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
		UNITY_DECLARE_SHADOWMAP(_DirectionalShadowMap);

		struct Input {
			float4 projPos;
			float4 grabPos;
			float3 worldPos;
			float2 localDir;
			float3 worldRefl;
			float4 screenPos;
			float3 viewDir;
			float depth;
			float4 color : COLOR;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color, _ShadowColor;
		float _FoamScale, _ShadowFade;
		fixed4 _FoamColor;
		float _FoamDepth, _FogDepth, _EdgeBlend;
		float _DepthBlur, _Focus, _Turbulence;
		float _Speed, _WaveHeight, _WaveLength, _WaveFrequency;
		float _Bias, _Power, _Scale;
		float _ExtraEmission;
		float _ScumFalloff, _ScumNoiseScale, _ScumScale;
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

		inline fixed3 Blend(fixed3 bg, fixed3 fore, fixed alpha) {
			return (bg * (1-alpha)) + (alpha*fore);
		}

		static const float3 forward = float3(0,0,1);
        
        float4 Blur(sampler2D s, float depth, float2 uv) {
            float4 color = 0;
            float2 blurSize = _DepthBlur * _GrabTexture_TexelSize.xy * depth;
            float2 ouv = uv;
            float3 origin = tex2D(s, uv);
            float k = 1.0 / 9;
            for(int y=0; y<3; y++) {
                for(int x=0; x<3; x++) {
                    float2 offset = float2(x-1, y-1);
					uv.xy = ouv + blurSize * offset;
                    float4 c = tex2D(s, uv); 
                    color += c * k;
                }
            }
            return color;
        }

		float4 Blur(sampler2D s, float4 uv) {
            float4 color = 0;
            float2 blurSize = 0.1;
            float2 ouv = uv.xy;
            float k = 1.0 / 9;
            for(int y=0; y<3; y++) {
                for(int x=0; x<3; x++) {
                    float2 offset = float2(x-1, y-1);
					uv.xy = ouv + blurSize * offset;
                    float4 c = tex2Dproj(s, uv); 
                    color += c * k;
                }
            }
            return color;
        }

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.localDir = v.vertex.xz;
			v.vertex.y += sin(_WaveFrequency*_Time[1] + length(o.localDir)*_WaveLength) *_WaveHeight;
			float4 vertex = UnityObjectToClipPos(v.vertex);
            o.projPos = ComputeScreenPos (vertex);
			COMPUTE_EYEDEPTH(o.projPos.z);
            o.grabPos = ComputeGrabScreenPos(vertex);
			o.worldPos = mul(unity_ObjectToWorld, v.vertex);
			float3 relPos = o.worldPos.xyz - _WorldSpaceCameraPos.xyz;
			o.depth = length(relPos);
		}

		void surf (Input IN, inout SurfaceOutput o) {
			
			float depthSample = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.projPos));
			float sceneZ = LinearEyeDepth (depthSample);
			float linearZ = Linear01Depth(depthSample);
			float partZ = IN.projPos.z;

			float2 screenUV = IN.screenPos.xy;
			screenUV /= IN.screenPos.w;

			float shadowmask = tex2D(_DirectionalShadowMask,screenUV).b;
			half shadow = lerp(_ShadowFade, 0, shadowmask);

			_Color = lerp(_Color, _ShadowColor, shadow);

			float zDiff = abs(sceneZ-partZ);
			float edge = InverseLerp(_FoamDepth, 0, zDiff);
			float fog = 1-InverseLerp(_FogDepth, 0, zDiff);
			float fade = InverseLerp(_EdgeBlend, 0, zDiff);

			fog *= (1-(shadow*0.15));
			
			float2 foamUV = (IN.worldPos.xz*_FoamScale) + (_Speed * IN.localDir * _Time[0]);
			fixed noise = tex2D(_Noise, (_Time[0]+foamUV)/32).r;
			fixed scaleNoise = lerp(0.999,1.001, noise);
			float2 foamUV1 = scaleNoise*foamUV + (_Speed * _SinTime[2]*IN.localDir);
			float2 foamUV2 = scaleNoise*0.7 * foamUV + (_Speed * _SinTime[2]*IN.localDir*0.6);
			fixed4 foam = (tex2D(_FoamTex, foamUV1) + tex2D(_FoamTex, foamUV2)) * lerp(_FoamColor, _ShadowColor, shadow);
			float3 rippleNormals = normalize(lerp(UnpackNormal(tex2D(_Ripples, foamUV1)), UnpackNormal(tex2D(_Ripples, foamUV2)), noise));
			float3 normal = normalize(lerp(rippleNormals, forward, 1-(_Turbulence*1.0/fog)));
			normal = lerp(normal, forward, fade);

			
			fixed3 color = Blend(_Color.rgb, foam, edge);

			fixed3 scum = tex2D(_ScumTex, IN.worldPos.xz*_ScumScale);
			fixed scumNoise = tex2D(_Noise, IN.worldPos.xz*_ScumNoiseScale).r;
			fixed scumAmount = pow(IN.color.r, scumNoise*_ScumFalloff);
			
			float4 bgUV = IN.grabPos;

			float2 offset = normal.xy * _GrabTexture_TexelSize.xy * _Focus;
			bgUV.xy = offset * bgUV.z + bgUV.xy;
			bgUV.xy /= bgUV.w;
			fixed3 bg = Blur(_GrabTexture, fog, bgUV.xy).rgb;
			float4 reflPos = UNITY_PROJ_COORD(IN.projPos);
			reflPos.xy += rippleNormals.xy;
			float3 refl = Blur(_ReflectionTex, reflPos) * (1-shadow);
			half rim = (1.0 - pow(saturate(pow(dot (normalize(IN.viewDir), normal),0.125)),4)) * (1-shadow);

			
			float distanceAlpha = 1-InverseLerp(_WaterCullDistance*0.7, _WaterCullDistance, IN.depth);
			color = Blend(color, scum, scumAmount);
			o.Albedo = Blend(bg, color, fog);
			o.Emission = (((foam*edge*_ExtraEmission) + (rim*refl) * (1-scumAmount)));
			o.Normal = normal;
			o.Specular = 0;
			o.Alpha = min(1-fade,distanceAlpha);
		}
		ENDCG
	}

	FallBack "Diffuse"
}
