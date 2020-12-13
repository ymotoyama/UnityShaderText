Shader "MyShader/Teleport"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Main Texture", 2D) = "white" {}
        _Freq ("Frequency", Float) = 1
        _Alpha("Alpha", Range(0, 1)) = 0.5
        _Speed("Speed", Float) = 1
        _BrightColor ("Bright Color", Color) = (0.3, 0.3, 7, 0)
        _BrightWidth("Bright Width", Float) = 0.2
    }

    SubShader
    {
        Tags {"Queue" = "AlphaTest" "RenderType" = "TransparentCutout"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float _Freq;
            float _Alpha;
            float _Speed;
            float4 _BrightColor;
            float _BrightWidth;

            v2f vert(appdata v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;
                o.worldPos = mul(UNITY_MATRIX_M, v.pos);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float alpha = (1 + _BrightWidth) * _Alpha - 1;
                float val = frac(i.worldPos.y * _Freq + _Time.y * _Speed) + alpha;
                clip(val);
                float4 color = tex2D(_MainTex, i.uv);
                if (val < _BrightWidth)
                {
                    color += _BrightColor;
                }
                return color;
            }
            ENDCG
        }
    }
}