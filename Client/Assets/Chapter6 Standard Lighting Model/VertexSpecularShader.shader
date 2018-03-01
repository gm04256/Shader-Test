// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VertexSpecularShader" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_Specular ("Specular", Color) = (1,1,1,1)
		_Power ("Power", float) = 1
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
				fixed4 color: TEXCOORD0;
			};

			fixed4 _Color;
			fixed4 _Specular;
			float _Power;

			v2f vert(a2v input)
			{
				v2f output;

				// position in clip space
				output.position = UnityObjectToClipPos(input.vertex);

				// world light direction
				float3 worldLightDirection = WorldSpaceLightDir(input.vertex);

				// world normal direction
				float3 worldNormalDirection = mul(transpose((float3x3)unity_WorldToObject), input.normal);

				// calculate diffuse color
				fixed3 diffuse = _LightColor0.rgb * max(0, dot(normalize(worldLightDirection), normalize(worldNormalDirection)));

				// world view direction
				float3 worldViewDirection = WorldSpaceViewDir(input.vertex);
				
				// world reflect direction
				float worldReflectDirection = reflect(normalize(-worldLightDirection), normalize(worldNormalDirection));

				// calculate specular
				fixed3 specular = pow(max(0, dot(normalize(worldViewDirection), normalize(worldReflectDirection))), _Power);

				//output.color = fixed4(diffuse * _Color.rgb + specular * _Specular.rgb, 1);
				output.color = fixed4(diffuse + specular, 1);

				return output;
			}

			fixed4 frag(v2f input): SV_Target
			{
				fixed4 color = input.color;

				return color;
			}

			ENDCG
		}
		
		
	}
	FallBack "Diffuse"
}
