#ifndef __PARTICLESET_CGINC__
#define __PARTICLESET_CGINC__

#include "UnityCG.cginc"

#if _USE_PMAP
  fixed4 _PMAPAlpColor;
  fixed4 _PMAPAddColor;
#endif

sampler2D _MainTex;
float4 _MainTex_ST;

#if _USE_UVSCROLL
 fixed4 _UVScroll;
#endif

#if _USE_UVSCROLL ||_USE_MASK
 float4 _TimeEditor;
#endif

#if _USE_MASK
 sampler2D _MaskTex;
 float4 _MaskTex_ST;
 fixed4 _MaskDetail1;
 fixed4 _MaskDetail2;
 fixed _MaskDistortionPowor;
 fixed4 _MaskTexTiliMask;
#endif

struct appdata
{
   float4 vertex : POSITION;
   fixed4 color:COLOR;
   float2 uv : TEXCOORD0;
};

struct v2f
{
   float4 vertex : SV_POSITION;
   fixed4 color:TEXCOORD0;
   float2 uv : TEXCOORD1;
};


v2f vert(appdata v)
{
   	v2f o;
   	o.vertex = UnityObjectToClipPos(v.vertex);
   	o.uv = TRANSFORM_TEX(v.uv, _MainTex);

   	#if _USE_PMAP
   		o.color = v.color * _PMAPAlpColor;
		o.color.rgb *= o.color.a;								//事前乗算
		o.color.rgb += v.color.rgb * _PMAPAddColor.rgb * v.color.a;	//加算成分追加
	#elif _USE_ALPFABLACK 
   		o.color = v.color;
		o.color.rgb *= o.color.a;								//事前乗算
	#else
		o.color = v.color;
	#endif

	return o;
}

fixed4 frag(v2f i) : SV_Target
{
	//タイムエディタ
	#if _USE_UVSCROLL ||_USE_MASK
		fixed4 node_838 = _Time + _TimeEditor;
    #endif

	//MainTexのUVのアニメーション
    #if _USE_UVSCROLL
     	fixed2 node_3991 = (float2(1,1)*float2(_UVScroll.r,_UVScroll.g)*node_838.g);
    #else
	    fixed2 node_3991 =0;
    #endif

   	//DistortionMapのUVのアニメーション
	#if _USE_MASK
        fixed2 node_2810 = ((i.uv*float2(_MaskDetail1.g,_MaskDetail1.b))+(node_838.g*_MaskDetail1.r)*float2(1,1)); // U_scroll
        fixed4 _UV1_tex2D_r = tex2D(_MaskTex,TRANSFORM_TEX(node_2810, _MaskTex));
        fixed2 node_4373 = ((i.uv*float2(_MaskDetail2.g,_MaskDetail2.b))+(node_838.g*_MaskDetail2.r)*float2(-0.75,-0.75)); // U_scroll
        fixed4 _UV2_tex2D_g = tex2D(_MaskTex,TRANSFORM_TEX(node_4373, _MaskTex));
        fixed2 node_5516 = saturate(( _UV2_tex2D_g.r > 0.5 ? (1.0-(1.0-2.0*(_UV2_tex2D_g.r-0.5))*(1.0-_UV1_tex2D_r.r)) : (2.0*_UV2_tex2D_g.r*_UV1_tex2D_r.r) )).rr; // 合成してRGのアニメーションデータを作成
        fixed2 node_5092 =((node_5516*_MaskDistortionPowor)*(node_5516*_MaskDistortionPowor*(-1.0)));
        //↓Texturetiling用のマスク作成準備
        fixed node_3272_if_leA = step(_MaskTexTiliMask.a,1.0);
        fixed node_3272_if_leB = step(1.0,_MaskTexTiliMask.a);
        fixed2 node_5795 = fixed2(frac((_MaskTexTiliMask.r*i.uv.r)),frac((_MaskTexTiliMask.g*i.uv.g)));
        fixed2 node_7293 = (node_5795*2.0+-1.0);
        fixed2 node_4245 = (node_7293*node_7293).rg;
        fixed2 node_3554 = pow(sin((node_5795*3.141592654)),1.75).rg;
        fixed node_6474 = ((1.0 - (node_4245.r+node_4245.g))*min(node_3554.r,node_3554.g));
    #else
    	fixed2 node_5092 =0;
	#endif

	#if _USE_UVSCROLL ||_USE_MASK
	    float4 texColor = tex2D(_MainTex,TRANSFORM_TEX((i.uv+node_3991+node_5092), _MainTex));
	 #else
   		fixed4 texColor = tex2D(_MainTex, i.uv);  //テクスチャの色を取得
   #endif

    //各ブレンドモードモードに対する処理
    #if _USE_PMAP
    	#if _USE_MASK
			fixed node_3272 = lerp((node_3272_if_leA*1.0)+(node_3272_if_leB*node_6474),node_6474,node_3272_if_leA*node_3272_if_leB);
        	texColor.rgb = texColor.rgb*node_3272;
      	#endif
      	   	texColor.a *=texColor.r;
 			texColor=saturate(texColor * i.color+pow(texColor.r,7.0)*_PMAPAddColor.a);
	#endif

	#if _USE_ALPFABLACK
	    #if _USE_MASK
			fixed node_3272 = lerp((node_3272_if_leA*1.0)+(node_3272_if_leB*node_6474),node_6474,node_3272_if_leA*node_3272_if_leB);
        	texColor.rgb = texColor.rgb*node_3272*i.color.a;
      	#endif
      	texColor.a *=texColor.r;
	   	texColor *= i.color;
	#endif

	#if _USE_SUBTRACTION
		#if _USE_MASK
			fixed node_3272 = lerp((node_3272_if_leA*1.0)+(node_3272_if_leB*node_6474),node_6474,node_3272_if_leA*node_3272_if_leB);
        	texColor.rgb =texColor.rgb*node_3272;
      	#endif
			texColor.rgb *= i.color.rgb*i.color.a;
	#endif

	#if _USE_MULTIPLY
		#if _USE_MASK
			texColor.rgb = saturate(lerp(texColor.rgb,float3(1,1,1),((1.0 - (texColor.a*lerp((node_3272_if_leA*1.0)+(node_3272_if_leB*node_6474),node_6474,node_3272_if_leA*node_3272_if_leB))))));
      	#endif
      		texColor.rgb = saturate(lerp((i.color.rgb*texColor.rgb),float3(1,1,1),((1.0 - i.color.a)+(1.0 - texColor.a))));
			texColor.a =1;
	#endif

	#if _USE_ADD
	  #if _USE_MASK
			fixed node_3272 = lerp((node_3272_if_leA*1.0)+(node_3272_if_leB*node_6474),node_6474,node_3272_if_leA*node_3272_if_leB);
        	texColor.rgb =texColor.rgb*node_3272*i.color.a;
      #endif
        texColor *= i.color;
	#endif

	#if _USE_ALPHA
		#if _USE_MASK
			texColor.a =texColor.a*lerp((node_3272_if_leA*1.0)+(node_3272_if_leB*node_6474),node_6474,node_3272_if_leA*node_3272_if_leB);
		#endif
			texColor *= i.color;
 	#endif

	#if _USE_OPAQUE
		texColor *= i.color;
 	#endif

#if MULTIPLY_200
	texColor =saturate(texColor*2.0);
#elif MULTIPLY_400
	texColor =saturate(texColor*4.0);
#endif


#if COLORCHANGE

#endif

#if ALPHA_EMISSIVE

#endif

    return texColor;
}

#endif // __PARTICLESET_CGINC__