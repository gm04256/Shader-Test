Shader "PUNK/effect/ParticleSet"
{
  Properties
  {
    [HideInInspector] _Mode("Mode", Float) = 0.0
    [HideInInspector]_SrcBlend("Blend Src", Float) = 0
    [HideInInspector]_DstBlend("Blend Dst", Float) = 0
 //   [HideInInspector]_ZWrite("ZWrite", Float) = 0
	[Enum(UnityEngine.Rendering.CompareFunction)]_ZTestMode("Ztest",Float)= 4
    [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Float) = 2
    [HideInInspector]_QueueMode("Render Queue",Float)=3000

    _MainTex("Texture", 2D) = "white" {}
    _PMAPAlpColor("AlpColor White", Color) = (1, 1, 1, 1)
    _PMAPAddColor("AddColor Black", Color) = (0, 0, 0, 0)
    _UVScroll("UVScroll(X,Y)",Vector)=(0,0,0,0)
    _MaskTex("DistortionMap", 2D) = "white" {}
    _MaskDetail1("detail1_(X)speed_(YZ)tile",Vector)=(0,1,1,0)
    _MaskDetail2("detail1_(X)speed_(YZ)tile",Vector)=(0,1,1,0)
    _MaskDistortionPowor("DistortionPowor", Range(0,1)) = 0
    _MaskTexTiliMask("(XY)MaskTiling)",Vector)=(1,1,0,0)
  }

  SubShader
  {
    Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
	Blend [_SrcBlend] [_DstBlend]
    ZTest [_ZTestMode]
    Cull [_CullMode]
	ZWrite off

    Pass
    {
      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag

	  #pragma multi_compile _ _USE_OPAQUE _USE_ADD _USE_PMAP _USE_ALPFABLACK _USE_SUBTRACTION _USE_MULTIPLY _USE_ALPHA
	  #pragma multi_compile _ _USE_UVSCROLL
      #pragma multi_compile _ _USE_MASK
      #pragma target 3.0
      #pragma multi_compile DEFAULT MULTIPLY_200 MULTIPLY_400

		#include "ParticleSet.cginc"
		ENDCG
    }
  }
  FallBack "Diffuse"
  CustomEditor "ParticleSetInspector_test"
}