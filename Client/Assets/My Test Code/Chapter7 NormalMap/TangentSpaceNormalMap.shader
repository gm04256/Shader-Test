// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/TangentSpaceNormalMap" 
{
	Properties 
	{
		_DiffuseColor ("Diffuse Color", Color) = (1,1,1,1)
		_SpecularColor ("Specular Color", Color) = (1,1,1,1)

		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_NormalTex ("Normal Map", 2D) = "white" {}
	
		_Gloss("Gloss", float) = 1
	}
	SubShader 
	{
		Pass
		{
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct a2v {
				float4 vertex: POSITION;
				float3 normal: NORMAL;
				float4 tangent: TANGENT;
				float4 texcoord: TEXCOORD;
			};

			struct v2f
			{
				float4 position: SV_POSITION;

				float3 tangentLightDir: TEXCOORD0;
				float3 tangentViewDir: TEXCOORD1;

				float4 uv: TEXCOORD3;
			};

			fixed4 _DiffuseColor;
			fixed4 _SpecularColor;

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;

			float _Gloss;
			
			v2f vert(a2v input)
			{
				v2f output;

				// necessary output value
				output.position = UnityObjectToClipPos(input.vertex);

				// calculate uv
				output.uv.xy = input.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				output.uv.zw = input.texcoord.xy * _NormalTex_ST.xy + _NormalTex_ST.zw;

				// calculate normal, viewDir, lightDir in tangent space
				float3 binormal = cross(input.normal, input.tangent.xyz) * input.tangent.w;
				float3x3 modelToTangentMatrix = float3x3(input.tangent.xyz, binormal, input.normal);

				output.tangentLightDir = mul(modelToTangentMatrix, normalize(ObjSpaceLightDir(input.vertex)));
				output.tangentViewDir = mul(modelToTangentMatrix, normalize(ObjSpaceViewDir(input.vertex)));

				return output;
			}

			fixed4 frag(v2f input): SV_Target
			{
				// normalization
				float3 tangentLightDir = normalize(input.tangentLightDir);
				float tangentViewDir = normalize(input.tangentViewDir);

				// get tangent space normal
				float3 unpackedNormal = UnpackNormal(tex2D(_NormalTex, input.uv.zw));
				float3 tangentNormal;
				tangentNormal.xy = unpackedNormal.xy;
				tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				// calculate diffuse
				float3 diffuse = _DiffuseColor.rgb * max(0, dot(tangentNormal, tangentLightDir));

				// calculate specular
				float3 tangentHalfDir = normalize(tangentViewDir + tangentLightDir);
				float3 specular = _SpecularColor.rgb * pow(max(0, dot(tangentHalfDir, tangentNormal)), _Gloss);
			
				// get MainTex color
				float3 mainTexColor = tex2D(_MainTex, input.uv.xy).xyz;

				fixed4 color = fixed4(_LightColor0.rgb * (specular + diffuse + mainTexColor), 1);

				color = fixed4(specular, 1);
				return color;
			}

			ENDCG
		}
	}
	FallBack "Specular"
}
