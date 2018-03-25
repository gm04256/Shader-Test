// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/SimplestVFShader" 
{
	SubShader 
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			float4 vert(float4 v: POSITION): SV_POSITION
			{
				float4 position = UnityObjectToClipPos(v);
				return position;
			}

			float4 frag(): SV_TARGET
			{
				float4 color = float4(1, 1, 1, 1);
				return color;
			}

			ENDCG
		}
			
		
	}
	FallBack "VertexLit"
}
