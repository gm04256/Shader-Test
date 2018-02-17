// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/RenderOrderTestShader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_AlphaScale ("Alpha Scale", float) = 0.8
	}
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

		// 渲染正方体时，六个面的顺序不同。因而在一个Pass中使用ZWrite On也会造成被遮挡的部分有时被前面完全遮挡，有时与前面混合的现象。
		// 使用一个Pass专门刷新深度缓存（整个物体的深度都被更新到深度缓存），之后再使用第二个Pass进行深度检测，
		// 则自身被遮挡的部分都会被剔除掉，而不会再出现与自身被遮挡的部分混合的现象。（※与其它被渲染的部分还是会混合的，因为它们是在其它独立的渲染流程中先被渲染到了颜色缓存中。）

		///* #1
		Pass 
		{
			ZWrite On
			ColorMask 0
		}
		//*/

		Pass 
		{
			Tags { "LightMode"="ForwardBase" }
			
			Cull Off

			// #2
			ZWrite Off
			
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _AlphaScale;

			struct a2v 
			{
				float4 vertex: POSITION;
				float3 normal: NORMAL;
				float4 texcoord: TEXCOORD0;
			};

			struct v2f
			{
				float4 position: SV_POSITION;
				float3 worldPosition: TEXCOORD0;
				float3 worldNormal: TEXCOORD1;
				float2 uv: TEXCOORD2;
			};

			v2f vert (a2v input)
			{
				v2f output;

				output.position = UnityObjectToClipPos(input.vertex);
				output.worldNormal = UnityObjectToWorldNormal(input.normal);
				output.worldPosition = mul(unity_ObjectToWorld, input.vertex).xyz;
				output.uv = TRANSFORM_TEX(input.texcoord, _MainTex);

				return output;
			}

			fixed4 frag(v2f input): SV_TARGET
			{
				fixed3 worldNormal = normalize(input.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(input.worldPosition));
				fixed4 texColor = tex2D(_MainTex, input.uv);

				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb * albedo * max (0, dot(worldNormal, worldLightDir));
				
				return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
			}

		
			ENDCG
		}
		
	}
	FallBack "Transparent/VertexLit"
}
