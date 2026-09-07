// Upgrade NOTE: upgraded instancing buffer 'Props' to new syntax.

Shader "Custom/Vegetable_CNSSS" {

	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_InternalColor ("Internal Color", Color) = (1,1,1,1)
		_EmissionColor ("Emission Color", Color) = (1,1,1,1)
		[Space]
		_MainTex ("Albedo (RGB) Emission (A)", 2D) = "white" {}
		_BumpMap ("Normals", 2D) = "bump" {}
		_Mask ("Transmission (R) Metallic (G) Smoothness (B) Occlusion (A)", 2D) = "white" {}
		[Space]
		[Toggle] _Occlusion ("Occlusion?", Float) = 1
		[Toggle] _Emission ("Emission?", Float) = 1
		[Space]
 		_SSS ("SSS Intensity", Range(0,1)) = 1
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		[Space]
		[Toggle] _Wind ("Wind?", Float) = 1
		_WindDir ("Wind", Vector) = (1,0,0,0)
		_BendScale ("Bend Scale", Range(0,1)) = 1
		_SwayFreq ("Sway Freq", Range(0,20)) = 1
		[Space]
		[Toggle] _Pulsing ("Pulsing?", Float) = 1
		_PulseAmp ("Pulsing Amp", Range(0,1)) = 0.1
		_PulseFreq ("Pulsing Freq", Range(0,30)) = 0.1
		[Space]
		[Toggle] _Flutter ("Flutter?", Float) = 1
		_FlutterAmp ("Flutter Amp", Range(0,1)) = 0.1
		_FlutterFreq ("Flutter Freq", Range(0,30)) = 0.1
		[Space]
		_Scale ("Scale", Float) = 1
	}

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		
		#pragma surface surf Standard fullforwardshadows addshadow vertex:vert
		
		#pragma target 3.0
		#pragma multi_compile __ _WIND_ON 
		#pragma multi_compile __ _PULSING_ON
		#pragma multi_compile  __ _FLUTTER_ON
		#pragma multi_compile  __ _OCCLUSION_ON
		#pragma multi_compile  __ _EMISSION_ON

		sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _Mask;

		struct Input {
			float2 uv_MainTex;
			float2 uv_BumpMap;
            float3 viewDir;
			float3 lightDir;
        };

		half _Glossiness;
		half _Metallic;
		fixed4 _InternalColor;
		half _SSS;
		half3 _WindDir;

		float _Phong;
		float _EdgeLength;

		

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			UNITY_DEFINE_INSTANCED_PROP(fixed4, _Color)
#define _Color_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed4, _EmissionColor)
#define _EmissionColor_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed, _BendScale)
#define _BendScale_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed, _SwayFreq)
#define _SwayFreq_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed, _PulseAmp)
#define _PulseAmp_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed, _PulseFreq)
#define _PulseFreq_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed, _FlutterAmp)
#define _FlutterAmp_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed, _FlutterFreq)
#define _FlutterFreq_arr Props
			UNITY_DEFINE_INSTANCED_PROP(fixed, _Scale)
#define _Scale_arr Props
		UNITY_INSTANCING_BUFFER_END(Props)

		float4 CubicSmooth(float4 x) {
  			return x * x *(3.0 - 2.0 * x);
		}

		float4 TriangleWave(float4 x) {
  			return abs(frac(x + 0.5) * 2.0 - 1.0);
		}

		float4 SineApproximation(float4 x) {
  			return CubicSmooth(TriangleWave(x));
		}

		void vert (inout appdata_full v, out Input o) {
			UNITY_INITIALIZE_OUTPUT(Input,o);
			#ifdef _PULSING_ON
			//red color is pulse control
			v.vertex.xyz += v.normal * saturate(SineApproximation(_Time[1]-(v.vertex.y*UNITY_ACCESS_INSTANCED_PROP(_PulseFreq_arr, _PulseFreq))) * UNITY_ACCESS_INSTANCED_PROP(_PulseAmp_arr, _PulseAmp) * v.color.r);
			#endif
			#ifdef _FLUTTER_ON
			//blue color is flutter control
			v.vertex.xz += v.vertex.xz*SineApproximation(_Time[3]*v.vertex.y*UNITY_ACCESS_INSTANCED_PROP(_FlutterFreq_arr, _FlutterFreq)) * UNITY_ACCESS_INSTANCED_PROP(_FlutterAmp_arr, _FlutterAmp) * v.color.b;
			#endif
			#ifdef _WIND_ON
			float3 vPos = v.vertex;
			float fLength = length(vPos);
			float fBF = vPos.y * UNITY_ACCESS_INSTANCED_PROP(_BendScale_arr, _BendScale) * ((SineApproximation(_Time[3]*UNITY_ACCESS_INSTANCED_PROP(_SwayFreq_arr, _SwayFreq))+0.5)*0.5);
			// Smooth bending factor and increase its nearby height limit.
			fBF += 1.0;
			fBF *= fBF;
			fBF = fBF * fBF - fBF;
			// Displace position
			float3 vNewPos = vPos;
			//Green vertex color is sway control
			vNewPos.xy += _WindDir.xz * fBF * v.color.g;
			// Rescale
			vPos.xyz = normalize(vNewPos.xyz) * fLength;
			v.vertex.xyz = vPos;
			#endif
			v.vertex.xyz *= UNITY_ACCESS_INSTANCED_PROP(_Scale_arr, _Scale);
		}

		float3 SubsurfaceShadingSimple(float3 diffColor, float3 normal, float3 viewDir, float3 thickness, float3 lightDir, float3 lightColor)
        {
            half3 vLTLight = lightDir + normal * 1;
            half  fLTDot = pow(saturate(dot(viewDir, -vLTLight)), 3.5) * 1.5;
            half3 fLT = 1 * (fLTDot + 1.2) * (thickness);
            return diffColor * ((lightColor * fLT) * 0.4);
        }
     
		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = lerp(tex2D (_MainTex, IN.uv_MainTex), UNITY_ACCESS_INSTANCED_PROP(_Color_arr, _Color), 0.1);		
			fixed4 mask = tex2D(_Mask, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_BumpMap));
			o.Metallic = mask.g * _Metallic;
			o.Smoothness = mask.b * _Glossiness;
			#ifdef _OCCLUSION_ON
			o.Occlusion = mask.a;
			#endif
			#ifdef _EMISSION_ON
			o.Emission = (UNITY_ACCESS_INSTANCED_PROP(_EmissionColor_arr, _EmissionColor) * c.a);
			#endif
			o.Emission += SubsurfaceShadingSimple(_InternalColor, o.Normal, IN.viewDir, mask.r*_SSS, IN.lightDir, _LightColor0);
			o.Alpha = 1;
		}
		ENDCG
	}
	FallBack "Standard"
}
