Shader "Unlit/NewUnlitShader"
{
    Properties
    {
        _SceneColor ("Scene Color", 2D) = "white" {}
        _WaterMask ("Water Mask", 2D) = "white" {}
        _WaterNormal ("Water Normal", 2D) = "white" {}
        _Gloss ("Gloss", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderQueue"="Transparent" }
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _SceneColor;
            sampler2D _WaterMask;
            sampler2D _WaterNormal;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float centerColor = tex2D(_WaterNormal, i.uv);

                float4 normalBlurred = float4(0.0, 0.0, 0.0, 0.0);
                float kernelSum = 0.0;
 
                static const float weights5[11] = {0.009300040045324049, 0.028001560233780885, 0.06598396774984912, 0.17571363439579307, 0.19859610213125314, 0.17571363439579307, 0.12170274650962626, 0.121702746509626260, 06598396774984912, 0.028001560233780885, 0.009300040045324049};
                static const float weights3[7] = {0.07130343198685299,0.13151412084312236,0.1898792328888381,0.214606428562373,0.1898792328888381,0.13151412084312236,0.07130343198685299};
                
                int upper = ((5 - 1) / 2);
                int lower = -upper;
 
                for (int x = lower; x <= upper; ++x)
                {
                    for (int y = lower; y <= upper; ++y)
                    {
                        float weight = weights5[max(x+5, y+5)];
                        //float weight = weights3[max(x+3, y+3)];
                        kernelSum += weight;
 
                        float2 offset = float2(4.0/1920 * x, 4.0/1080 * y);
                        normalBlurred += tex2D(_WaterNormal, i.uv + offset) * weight;
                    }
                }
 
                normalBlurred /= kernelSum;
                //normalBlurred = normalBlurred*2-1;

                // Specular (Blinn-Phong)
                half3 lightDirection = _WorldSpaceLightPos0.xyz;
                float3 viewVector = mul((float3x3)unity_CameraToWorld, float3(0,0,1));
                half4 specularColor = half4(saturate(dot(normalize(lightDirection + viewVector), normalize(normalBlurred*2-1))).xxx, 1);
                float specularExponent = 3;
                specularColor = pow(specularColor, specularExponent);
                //specularColor *= 2;

                if(length(centerColor) == 0)
                    return tex2D(_SceneColor, i.uv);
                return tex2D(_SceneColor, i.uv + (normalBlurred)*0.03) + float4(0,0.9,1,1)*0.02 + specularColor;
            }
            ENDCG
        }
    }
}
