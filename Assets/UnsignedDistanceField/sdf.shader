﻿Shader "iHuman/SDF/normal"
{
	Properties
	{
		[PerRendererData] _MainTex ("Texture", 2D) = "white" {}
		[PerRendererData] _Color ("Color", color) = (1, 0, 0, 1)
		[PerRendererData] _RampTex ("RampTex", 2d) = "white" {}

		// 样式对应规则
		// 0 发光
		// 1 纯色
		[PerRendererData] [Enum(Rim,0,Pure,1,Edge,2)]_Style("Style", int) = 0

		// 通道对应：1:r 2:g 3:b 4:a
		// r通道：第一笔
		// g通道：第二笔
		// b通道：第三笔
		// a通道：字母
		[PerRendererData] [Enum(First,1,Second,2,Third,3,All,4)]_Step("Step", int) = 0

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Transparent" }
		Blend SrcAlpha oneMinusSrcAlpha
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 color : Color;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 color : TEXCOORD1;
				// UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _RampTex;
			float4 _MainTex_ST;
			float4 _RampTex_ST;
			int _Step;
			int _Style;
			fixed4 _Color;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 udf_col = tex2D(_MainTex, i.uv);
				float udf_v = 0;
				// 选择笔画
				switch (_Step){
					case 1:
						udf_v = udf_col.r;
						break;
					case 2:
						udf_v = udf_col.g;
						break;
					case 3:
						udf_v = udf_col.b;
						break;
					case 4:
						udf_v = udf_col.a;
						break;
					default:
						udf_v = 0;
						break;
				}

				// 选择样式
				if (_Style == 0){
					// 发光
					float2 ramp_uv = TRANSFORM_TEX(float2(udf_v, 0.5), _RampTex);
					fixed4 out_col = tex2D(_RampTex, ramp_uv);
					udf_col.rgb = out_col.rgb;
					udf_col.a = udf_v * out_col.a;
				}
				else if (_Style == 1){
					// 纯色
					udf_col = i.color * _Color;
					clip(udf_v - 0.5);
				}
				else if (_Style == 2){
					fixed4 c = i.color * _Color;
					// 边缘
					udf_col = abs(udf_v - 0.5) < 0.05 ? c : fixed4(0, 0, 0, 0);
				}
				return udf_col;
			}
			ENDCG
		}
	}
}