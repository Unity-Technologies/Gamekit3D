// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/MirrorWater"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
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
		[HideInInspector] _ReflectionTex ("", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
		ZWrite On
		Cull Back
		LOD 200
		
		GrabPass { }
 
		Pass {
			CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members localDIr,depth)
#pragma exclude_renderers d3d11
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			sampler2D _FoamTex;
			sampler2D _Noise;
			sampler2D _Ripples;
			sampler2D _GrabTexture;
			sampler2D _ReflectionTex;

			half4 _GrabTexture_TexelSize;
			half4 _ReflectionTex_TexelSize;

			fixed4 _Color;
			float _FoamScale;
			fixed4 _FoamColor;
			float _FoamDepth, _FogDepth, _EdgeBlend;
			float _DepthBlur, _Focus, _Turbulence;
			float _Speed, _WaveHeight, _WaveLength, _WaveFrequency;

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 refl : TEXCOORD1;
				float4 pos : SV_POSITION;
				float4 grabPos : TEXCOORD2;
				float2 localDir : TEXCOORD3;
				float depth : COLOR;
				float3 worldPos : TEXCOORD4;
			};

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
			

			v2f vert(float4 pos : POSITION, float2 uv : TEXCOORD0)
			{
				v2f o;
				o.pos = UnityObjectToClipPos (pos);
				//o.uv = TRANSFORM_TEX(uv, _MainTex);
				o.refl = ComputeScreenPos (o.pos);
				o.localDir = pos.xz;
				o.pos.y += sin(_WaveFrequency*_Time[1] + length(o.localDir)*_WaveLength) *_WaveHeight;
				o.refl.z = -UnityObjectToViewPos( pos ).z;
				o.grabPos = ComputeGrabScreenPos(o.pos);
				o.worldPos = mul(unity_ObjectToWorld, o.pos);
				o.depth = pow(InverseLerp(0, _ProjectionParams.z-100, length(o.worldPos.xyz - _WorldSpaceCameraPos.xyz)),4);
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target
			{
				float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.refl)));
				float partZ = i.refl.z;
				float zDiff = abs(sceneZ-partZ);
				float edge = InverseLerp(_FoamDepth, 0, zDiff);
				float fog = 1-InverseLerp(_FogDepth, 0, zDiff);
				float fade = InverseLerp(_EdgeBlend, 0, zDiff);
				
				float2 foamUV = (i.worldPos.xz*_FoamScale) + (_Speed * i.localDir * _Time[0]);
				fixed noise = tex2D(_Noise, (_Time[0]+foamUV)/32).r;
				fixed scaleNoise = lerp(0.995,1.005, noise);
				float2 foamUV1 = scaleNoise*foamUV + (_Speed * _SinTime[2]*i.localDir);
				float2 foamUV2 = scaleNoise*0.7 * foamUV + (_Speed * _SinTime[2]*i.localDir*0.6);
				fixed4 foam = tex2D(_FoamTex, foamUV1) + tex2D(_FoamTex, foamUV2) * _FoamColor;
				float3 rippleNormals = normalize(lerp(UnpackNormal(tex2D(_Ripples, foamUV1)), UnpackNormal(tex2D(_Ripples, foamUV2)), noise));
				float3 normal = normalize(lerp(rippleNormals, forward, 1-_Turbulence));
				normal = lerp(normal, forward, fade);

				
				fixed3 color = Blend(_Color.rgb, foam, edge);

				float4 bgUV = i.grabPos;

				float2 offset = normal.xy * _GrabTexture_TexelSize.xy * _Focus;
				bgUV.xy = offset * bgUV.z + bgUV.xy;
				bgUV.xy /= bgUV.w;
				fixed3 bg = Blur(_GrabTexture, fog, bgUV.xy).rgb;
				fixed4 refl = tex2Dproj(_ReflectionTex, UNITY_PROJ_COORD(i.refl));
				return float4(Blend(bg, color, fog), 1-fade) + refl;

			}
			ENDCG
	    }
	}
}