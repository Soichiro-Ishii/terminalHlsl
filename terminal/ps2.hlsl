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
Texture2D img : register(t1);
SamplerState smp : register(s0);

//初期値
#define numMaterials 3
#define MAX_STEPS 1000
#define MAX_DIST 50
#define SURF_DIST 0.01
static const float PI = 3.14159265358979f;
static const float intensity = 1.0f; //0~1でデカいほど色が濃くなる
static const float mass = 0.15f; //質量
static const float3 bPos = float3(0, 0, 0); //ブラックホールの位置
static const float speed = 0.5f; //回転速度
static const float3 materials[numMaterials] =
{
    float3(0.8, 0.4, 0), //赤
    float3(0, 0, 0), //黒
    float3(0.5, 0.7, 0.9) //白
};

//構造体
struct RayHit
{
    float t; //衝突点までの距離
    int material; //衝突したオブジェクトのマテリアルID
    float3 rd; //終了時の向き(空の表示で使用)
    bool hit; //衝突したかどうか
};
struct SDFResult
{
    float dist; //距離
    int material; //マテリアルID
};
//輝度計算
float calcLuminance(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}
//2D回転行列
float2x2 rot2D(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float2x2(c, -s, s, c);
}
//ベクトルから角度
float2 dirToAngle(float3 dir)
{
    float2 angle;
    angle.x = atan2(dir.z, dir.x);
    angle.y = atan2(dir.y, length(float2(dir.x, dir.z)));
    return angle;
}
//skyの色を返す
float3 getSkyColor(float3 rd)
{
    float2 uv = dirToAngle(rd);
    uv.x = uv.x / (2 * PI) + 0.5;
    uv.y = uv.y / PI + 0.5;
    return img.Sample(smp, uv).rgb;
}

//2つの距離のうち、近い方を返す。マテリアルのIDも返す。
SDFResult opUnion(SDFResult a, SDFResult b)
{
    if (a.dist < b.dist)
        return a;
    else
        return b;
}

float sdSphere(float3 p, float r)
{
    return length(p) - r;
}

SDFResult getDist(float3 rp)
{
    float3 rp_ = rp;
    SDFResult result;
    //普通の星1
    rp_ += float3(cos(time * 1.5), 0, sin(time * 1.5)) * 3;
    SDFResult s1 = { sdSphere(rp_, 1.0f), 0 };
    rp_ = rp;
    rp_ -= bPos;
    //ブラックホール
    SDFResult s2 = { sdSphere(rp_, 2 * mass), 1 }; //半径はシュワルツシルト半径
    result = opUnion(s1, s2);
    //普通の星2
    rp_ = rp;
    float3 s3Pos = float3(cos(time) * 2, 0, sin(time)) * 5;
    s3Pos.yz = mul(rot2D(PI / 3.5), s3Pos.yz);
    rp_ += s3Pos;
    
    SDFResult s3 = { sdSphere(rp_, 1.0f), 2 };
    result = opUnion(result, s3);
    return result;
}

//ニュートンの重力加速度を計算する関数
float3 calcGravityNT(float3 pos, float3 blackHolePos, float m)
{
    float3 dir = pos - blackHolePos;
    float rSq = dot(dir, dir);
    float r = sqrt(rSq);
    return -(2 * m * dir) / (rSq * r);

}

//衝突判定
RayHit rayMarch(float3 ro, float3 rd)
{
    float t = 0;
    RayHit result;
    float3 rp = ro;
    float d = getDist(rp).dist;
    [loop]
    for (int i = 0; i < MAX_STEPS; i++)
    {
        //ニュートンの重力加速度を計算
        float3 dir = rp - bPos;
        float rSq = dot(dir, dir);
        float r = sqrt(rSq);
        float3 acc = -(2 * mass * dir) / (rSq * r);
        //dtを計算
        float rs = 2 * mass; //シュワルツシルト半径
        float r_min = 1.5f * rs; //最小距離
        float r_max = 10.0f * rs; //最大距離
        float dt_min = SURF_DIST * rs; //最小dt
        float dt_max = SURF_DIST * 100 * rs; //最大dt
        float dt = lerp(dt_min, dt_max, smoothstep(r_min, r_max, r));
        //float dt = SURF_DIST;
        dt = min(dt, d);

        rd += acc * dt;
        rd = normalize(rd);
        rp = rp + rd * dt;
        
        SDFResult res = getDist(rp);
        d = res.dist;
        result.material = res.material;
        t += dt;
        
        result.hit = (d < SURF_DIST);
        
        if (result.hit || t > MAX_DIST)
            break;
        
    }
    result.t = t;
    result.rd = rd;
    return result;
}

//uvはtex上の座標[0,1]
//posはmicrosoftさんいわく、関係ない値だそうです。
float4 main(float4 pos : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
    //-1から1に座標を変換
    float2 p = uv * 2.0 - 1.0;
    p.x *= res.x / res.y; //比率を合わせる
    p.y *= -1; //第三象限が左下に来るようにする
    //回転
    float2 angle = float2(time * speed, 0);
    //レイの原点と方向
    float3 ro = float3(sin(time * speed), 0, -cos(time * speed)) * 5;
    float3 rd = normalize(float3(p, 1));
    rd.xz = mul(rot2D(angle.x), rd.xz);
    rd.yz = mul(rot2D(angle.y), rd.yz);
    
    //衝突判定
    RayHit hit = rayMarch(ro, rd);
    
    float3 col;
    if (!hit.hit)
    {
        col = getSkyColor(hit.rd); //背景色
    }
    else
    {
        col = materials[hit.material];
    }
    //輝度を計算する
    float luminance = calcLuminance(col);
    float4 cf = float4(col, 1.0f);
    cf.a *= luminance; //輝度に合わせてアルファを調整
    float4 texCol = tex.Sample(smp, uv);
    luminance = calcLuminance(texCol.rgb);
    texCol.a *= luminance;
    //return cf + float4(0.0f, 0.0f, 0.0f, 1.0f);
    return cf * intensity + texCol;
}