// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/FragmentDiffuseShader" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		
	}
	SubShader 
	{
		Pass
		{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
		
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct a2v 
			{
				float4 vertex: POSITION;
				float3 normal: NORMAL;
			};

			struct v2f
			{
				float4 position: SV_POSITION;
				float3 worldNormalDirection: TEXCOORD0;
			};

			fixed4 _Color;

			v2f vert(a2v input)
			{
				v2f output;

				// position in clip space
				output.position = UnityObjectToClipPos(input.vertex);

				// world normal direction
				output.worldNormalDirection = mul(transpose((float3x3)unity_WorldToObject), input.normal);

				return output;
			}

			fixed4 frag(v2f input): SV_Target
			{
				// world light direction
				float3 worldLightDirection = _WorldSpaceLightPos0.xyz;

				// calculate diffuse color
				fixed3 diffuse = _LightColor0.rgb * max(0, dot(normalize(worldLightDirection), normalize(input.worldNormalDirection)));

				fixed4 color = fixed4(diffuse * _Color.rgb, 1);

				return color;
			}

			ENDCG
		}
		
		
	}
	FallBack "Diffuse"
}
