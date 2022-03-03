//Original Made by Leviant,

Shader "Luc/AudioEqualizer Addendum"
{
    Properties
    {
        _MainColor("MainColor", Color) = (0,0,0,1)
        _Smoothness("Smoothness", Range( 0 , 1)) = 0
        _multiplyMap("Multiply Map", Float) = 1
        _WaveSpeed("Wave Speed", Float) = 1
        [HDR]_CustomColor("Custom Color", Color) = (0,0,0,0)
        _OverlayTexture("Overlay texture", 2D) = "black" {}
        _FallOffTexture("Fall Off texture", 2D) = "white" {}
        _VideoTexture("Video texture", 2D) = "black" {}
        _DistortVal("Distortion", Range(0,5)) = 0
        _MoveSpeedX("Move Speed X", Range(0,5)) = 0
        _MoveSpeedY("Move Speed Y", Range(0,5)) = 0
        [HideInInspector] __dirty( "", Int ) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "Queue" = "Geometry+0" "IgnoreProjector" = "True" "IsEmissive" = "true"
        }
        Cull Back
        CGPROGRAM
        #pragma target 5.0
        #pragma surface surf Standard vertex:vertexDataFunc

        #include "UnityCG.cginc"
        #include "Assets/AudioLink/Shaders/AudioLink.cginc"

        struct Input
        {
            float2 texcoord_0;
            float3 worldRefl;
            float4 vertData;
            INTERNAL_DATA
        };

        uniform sampler2D _OverlayTexture;
        uniform sampler2D _FallOffTexture;
        uniform sampler2D _VideoTexture;
        uniform float _WaveSpeed;
        uniform float _multiplyMap;
        uniform float4 _MainColor;
        uniform float _Smoothness;
        uniform float4 _CustomColor;
        uniform float _MoveSpeedX, _MoveSpeedY, _DistortVal;
        float4 _OverlayTexture_ST;

        void vertexDataFunc(inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.texcoord_0 = v.texcoord.xy;
            float fallOf = tex2Dlod(_FallOffTexture, v.texcoord).r;
            float2 temp_output_24_0 = v.texcoord.xy + float2(-0.5, -0.5);
            float delay = sqrt(temp_output_24_0.x * temp_output_24_0.x + temp_output_24_0.y * temp_output_24_0.y) * 127 * _WaveSpeed;
            float4 tex2DNode1 = AudioLinkData(ALPASS_AUDIOLINK + uint2( delay, 0 )).rrrr;
            float3 ase_vertex3Pos = v.vertex.xyz;
            float3 appendResult9 = float3(0.0, tex2DNode1.a * _multiplyMap * ase_vertex3Pos.y, 0.0);
            v.vertex.xyz += appendResult9 * fallOf.r;
            o.vertData = tex2DNode1;
        }

        float4 permute(float4 x)
        {
            return (x * 34.0 + 1.0) * x - floor((x * 34.0 + 1.0) * x * (1.0 / 289.0)) * 289.0;
        }

        float cnoise(float2 P)
        {
            float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
            Pi = Pi - floor(Pi * (1.0 / 289.0)) * 289.0;
            float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
            float4 ix = Pi.xzxz;
            float4 iy = Pi.yyww;
            float4 fx = Pf.xzxz;
            float4 fy = Pf.yyww;
            float4 i = permute(permute(ix) + iy);
            float4 gx = frac(i * (1.0 / 41.0)) * 2.0 - 1.0;
            float4 gy = abs(gx) - 0.5;
            float4 tx = floor(gx + 0.5);
            gx = gx - tx;
            float2 g00 = float2(gx.x, gy.x);
            float2 g10 = float2(gx.y, gy.y);
            float2 g01 = float2(gx.z, gy.z);
            float2 g11 = float2(gx.w, gy.w);
            float4 norm = 1.79284291400159 - 0.85373472095314 * float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
            g00 *= norm.x;
            g01 *= norm.y;
            g10 *= norm.z;
            g11 *= norm.w;
            float n00 = dot(g00, float2(fx.x, fy.x));
            float n10 = dot(g10, float2(fx.y, fy.y));
            float n01 = dot(g01, float2(fx.z, fy.z));
            float n11 = dot(g11, float2(fx.w, fy.w));
            float2 fade_xy = Pf.xy * Pf.xy * Pf.xy * (Pf.xy * (Pf.xy * 6.0 - 15.0) + 10.0);
            float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
            float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
            return 2.3 * n_xy;
        }

        void surf(Input i, inout SurfaceOutputStandard o)
        {
            o.Albedo = _MainColor.rgb;
            float2 scale = float2(_OverlayTexture_ST.x, _OverlayTexture_ST.y);
            float2 distort = float2(_Time.y * _MoveSpeedX, _Time.y * _MoveSpeedY) + cnoise(i.worldRefl.xz) *
                _DistortVal;

            float3 over = tex2D(_OverlayTexture,
                                (i.worldRefl.xz + float2(_OverlayTexture_ST.z, _OverlayTexture_ST.w)) * scale + distort).rgb;
            float3 vid = tex2Dlod(_VideoTexture, float4(i.texcoord_0, 0, 5)).rgb;
            float3 tex = lerp(over, vid, float3(0.5, 0.5, 0.5));

            o.Emission = tex + _CustomColor.rgb * i.vertData;
            o.Smoothness = _Smoothness;
            o.Alpha = 1;
        }
        ENDCG
    }
    Fallback "Diffuse"
}