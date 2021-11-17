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
                float3 normal   : NORMAL;    // ���_�̖@��
                float4 tangent  : TANGENT;   // ���_�̐ڐ�
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float3 normal   : TEXCOORD1; // ���_�̖@��
                float3 tangent  : TEXCOORD2; // ���_�̐ڐ�
                float3 binormal : TEXCOORD3; // ���_�̏]�@��
                float3 worldPos : TEXCOORD4; // ���[���h��ԍ��W
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
                // �I�u�W�F�N�g��Ԃ̒��_���W���N���b�v��Ԃɕϊ�
                o.vertex = UnityObjectToClipPos(v.vertex);
                // UV���W�͂��̂܂܏o�͍\���̂ɓn��
                o.uv = v.uv;
                // �@�������[���h��Ԃɕϊ�
                o.normal = UnityObjectToWorldNormal(v.normal);
                // �ڐ������[���h��Ԃɕϊ�
                o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
                // �@���Ɛڐ��̊O�ς���]�@�������߂�
                o.binormal = normalize(cross(o.normal.xyz, o.tangent.xyz));
                // ���ɂ��]�@���̌����̈Ⴂ���C��
                o.binormal *= v.tangent.w * unity_WorldTransformParams.w;
                // ���[���h��Ԃ̒��_���W
                o.worldPos = mul(UNITY_MATRIX_M, v.vertex); 

                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // �X���C�X
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

                // �m�[�}���}�b�v�̓��e���擾
                float3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv));
                // �m�[�}���}�b�v����ǂݎ�����@���x�N�g���i�ڋ�ԁj�����[���h��Ԃɕϊ�����
                float3 worldNormal = (i.tangent * normalMap.x) + (i.binormal * normalMap.y) + (i.normal * normalMap.z);

                // �g�U���̌v�Z
                float3 lightDir = _WorldSpaceLightPos0;
                float NdotL = dot(lightDir, worldNormal);
                NdotL = saturate(NdotL);
                float3 diffuse = _LightColor0 * NdotL;

                // ���ʔ��˂̌v�Z
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos); // �����x�N�g��
                float3 halfVec = normalize(viewDir + lightDir); // �n�[�t�x�N�g��
                float specular = dot(halfVec, worldNormal); // ���ʔ��˗�
                specular = saturate(specular); // 0�`1�ɂ���
                specular = pow(specular, _SpecularPower); // ���ʂ�����
                float3 coloredSpecular = _SpecularColor * specular; // �X�y�L�����[�ɐF��K�p

                // �g�U���{���ʔ��ˁ{����
                float3 light = diffuse + coloredSpecular + _Ambient;
                light += thresholdLight.rgb;

                // �e�N�X�`���J���[�̎擾
                float4 baseColor = tex2D(_MainTex, i.uv);

                return baseColor * float4(light, 1);
            }
            ENDCG
        }
    }
}
