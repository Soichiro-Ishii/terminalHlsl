cbuffer PixelShaderSettings : register(b0)
{
// psが適応されてからの時間(s)
    float time;
// UIの大きさ
    float scale;
// texの解像度
    float2 res;
//背景色
    float4 bg;
};
//デフォルトのターミナル画面
Texture2D tex : register(t0);
SamplerState smp : register(s0);

static const float PI = 3.14159265358979;
static const float brightness = 40; //明るさ 低いほど明るい
static const float intensity = 1.0f; //0~1でデカいほど色が濃くなる
static const float attraction = 4.0f;
//リピート
float2 repeat(float2 p, float2 period)
{
    return p - period * round(p / period);
}
//滑らかにくっつける
float smin(float a, float b, float k)
{
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * (1.0 / 6.0);
}
float sminExp(float a, float b, float k)
{
    float ea = exp(-k * a);
    float eb = exp(-k * b);
    return -log(ea + eb) / k;
}

//球体
float sdCircle(float2 p, float r)
{
    return length(p) - r;
}
//三角形
float sdTriangleIsosceles(float2 p, float2 q)
{
    p.x = abs(p.x);
    float2 a = p - q * clamp(dot(p, q) / dot(q, q), 0.0, 1.0);
    float2 b = p - q * float2(clamp(p.x / q.x, 0.0, 1.0), 1.0);
    float s = -sign(q.y);
    float2 d = min(float2(dot(a, a), s * (p.x * q.y - p.y * q.x)),
                  float2(dot(b, b), s * (p.y - q.y)));
    return -sqrt(d.x) * sign(d.y);
}
//水滴
float sdUnevenCapsule(float2 p, float r1, float r2, float h)
{
    p.x = abs(p.x);
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(p, float2(-b, a));
    if (k < 0.0)
        return length(p) - r1;
    if (k > a * h)
        return length(p - float2(0.0, h)) - r2;
    return dot(p, float2(a, b)) - r1;
}

//uvはtex上の座標[0,1]
//posはmicrosoftさんいわく、関係ない値だそうです。
float4 main(float4 pos : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
//-1から1に座標を変換
    float2 p = uv * 2.0 - 1.0;
    p.x *= res.x / res.y; //比率を合わせる
    p.y *= -1; //第三象限が左下に来るようにする
    float fluctuation1 = sin(time) * 0.1f;
    float fluctuation2 = cos(time / 2) * 0.15f;
    float3 c = float3(0.0, 1.0 - fluctuation2, 0.4 - fluctuation1);
    //距離計算
    //水滴1--------------------
    float2 p_ = p;
    p_.x += 0.5f;
    p_.y += time;
    float2 q = repeat(p_, float2(2.0f, 1.5f));
    float dWaterDrop = sdUnevenCapsule(q, 0.1f, 0.01f, 0.4f);
    float d = dWaterDrop;
    //水滴2--------------------
    p_ = p;
    p_.x -= 1.0f;
    p_.y += time * 1.57;
    q = repeat(p_, float2(2.75f, 1.5f));
    float dWaterDrop2 = sdUnevenCapsule(q, 0.075f, 0.002f, 0.3f);
    d = sminExp(d, dWaterDrop2, attraction);
    //水滴3--------------------
    p_ = p;
    p_.x -= 0.4f;
    p_.y += time * 1.89 / 3;
    q = repeat(p_, float2(3.5f, 2.5f));
    float dWaterDrop3 = sdUnevenCapsule(q, 0.2f, 0.01f, 0.6f);
    d = sminExp(d, dWaterDrop3, attraction);


    //色計算
    c *= exp(-abs(d * brightness));
    float4 cf = float4(c, 1.0f);
    float4 texCol = tex.Sample(smp, uv);
    return cf * intensity + texCol;
}