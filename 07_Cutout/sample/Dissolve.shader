Shader "MyShader/Dissolve"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Main Texture", 2D) = "white" {}
        [NoScaleOffset] _DissolveTex("Dissolve Texture", 2D) = "white" {}
        _DissolveAmount("Dissolve Amount", Range(0, 1)) = 0.5
        _Scale("Scale", Float) = 1
        [HDR] _BrightColor("Bright Color", Color) = (1, 1, 1, 1)
        _BrightWidth("Bright Width", Range(0, 1)) = 0.1
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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            sampler2D _DissolveTex;
            float _DissolveAmount;
            float _Scale;
            float4 _BrightColor;
            float _BrightWidth;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // グレースケール画像なので、RGBどれも同じ。とりあえずR要素を使う。
                float d = tex2D(_DissolveTex, i.uv / _Scale).r;
                // 明るくする幅の分、しきい値を調整する
                float threshold = _DissolveAmount * (1 + _BrightWidth) - _BrightWidth;
                // _DissolveAmount(ディゾルブ度合い）がDissolveテクスチャーの明るさを超えていたら描画しない
                if (d < threshold)
                    discard;
                // テクスチャーから色を取得
                float4 color = tex2D(_MainTex, i.uv);
                // しきい値付近を光らせる
                if (d < threshold + _BrightWidth)
                    color += float4(_BrightColor.xyz, 0);
                return color;
            }
            ENDCG
        }
    }
}
