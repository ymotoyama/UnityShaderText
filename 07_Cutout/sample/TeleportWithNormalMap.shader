Shader "MyShader/Teleport"
{
    Properties
    {
        [NoScaleOffset] _MainTex("Texture", 2D) = "white" {}
        _NormalMap("Normal Map", 2D) = "bump" {}
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecularPower("Specular Power", Range(0, 50)) = 10
        _Ambient("Ambient Color", Color) = (0.1, 0.1, 0.1, 1)
        _Alpha("Alpha", Range(0, 1)) = 1
        _Frequency("Frequency", Float) = 5
        _ScrollSpeed("Scroll Speed", Float) = 1
        [HDR]_TeleportLight("Teleport Light", Color) = (0.5, 0.5, 1, 1)
        _LightWidth("Light Width", Float) = 0.1
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
                float3 normal   : NORMAL;    // 頂点の法線
                float4 tangent  : TANGENT;   // 頂点の接線
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 normal   : TEXCOORD1; // 頂点の法線
                float3 tangent  : TEXCOORD2; // 頂点の接線
                float3 binormal : TEXCOORD3; // 頂点の従法線
                float3 worldPos : TEXCOORD4; // ワールド空間座標
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            float4 _LightColor0;
            float4 _SpecularColor;
            float _SpecularPower;
            float4 _Ambient;
            float _Alpha;
            float _Frequency;
            float _ScrollSpeed;
            float4 _TeleportLight;
            float _LightWidth;

            v2f vert(appdata v)
            {
                v2f o;
                // オブジェクト空間の頂点座標をクリップ空間に変換
                o.vertex = UnityObjectToClipPos(v.vertex);
                // UV座標はそのまま出力構造体に渡す
                o.uv = v.uv;
                // 法線をワールド空間に変換
                o.normal = UnityObjectToWorldNormal(v.normal);
                // 接線をワールド空間に変換
                o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
                // 法線と接線の外積から従法線を求める
                o.binormal = normalize(cross(o.normal.xyz, o.tangent.xyz));
                // 環境による従法線の向きの違いを修正
                o.binormal *= v.tangent.w * unity_WorldTransformParams.w;
                // ワールド空間の頂点座標
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex); 

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // スライス
                float threshold = (1 - _Alpha) * (1 + _LightWidth) - _LightWidth;
                float y = frac(i.worldPos.y * _Frequency + _Time.y * _ScrollSpeed);
                if (y < threshold)
                {
                    discard;
                }

                float4 thresholdLight = float4(0, 0, 0, 0);
                if (y < threshold + _LightWidth)
                {
                    thresholdLight = _TeleportLight;
                }

                // ノーマルマップの内容を取得
                float3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv));
                // ノーマルマップから読み取った法線ベクトル（接空間）をワールド空間に変換する
                float3 worldNormal = (i.tangent * normalMap.x) + (i.binormal * normalMap.y) + (i.normal * normalMap.z);

                // 拡散光の計算
                float3 lightDir = _WorldSpaceLightPos0;
                float NdotL = dot(lightDir, worldNormal);
                NdotL = saturate(NdotL);
                float3 diffuse = _LightColor0 * NdotL;

                // 鏡面反射の計算
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos); // 視線ベクトル
                float3 halfVec = normalize(viewDir + lightDir); // ハーフベクトル
                float specular = dot(halfVec, worldNormal); // 鏡面反射量
                specular = saturate(specular); // 0～1にする
                specular = pow(specular, _SpecularPower); // 収斂させる
                float3 coloredSpecular = _SpecularColor * specular; // スペキュラーに色を適用

                // 拡散光＋鏡面反射＋環境光
                float3 light = diffuse + coloredSpecular + _Ambient;
                light += thresholdLight.rgb;

                // テクスチャカラーの取得
                float4 baseColor = tex2D(_MainTex, i.uv);

                return baseColor * float4(light, 1);
            }
            ENDCG
        }
    }
}
