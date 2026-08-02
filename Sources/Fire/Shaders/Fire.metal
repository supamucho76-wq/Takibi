#include <metal_stdlib>
using namespace metal;

struct FireUniforms {
    float2 resolution;
    float time;
    float heat;
    float deltaTime;
    float quality;
    float burst;
    float4 flameTint;
};

struct QuadOut {
    float4 position [[position]];
    float2 uv;
};

struct SparkVertexIn {
    float2 position;
    float life;
    float seed;
};

struct SparkOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float life;
    float seed;
};

float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash21(i), hash21(i + float2(1.0, 0.0)), u.x),
        mix(hash21(i + float2(0.0, 1.0)), hash21(i + 1.0), u.x),
        u.y
    );
}

float fbm4(float2 p) {
    float value = 0.0;
    float amplitude = 0.52;
    float2x2 rotation = float2x2(0.80, -0.60, 0.60, 0.80);
    for (int octave = 0; octave < 4; ++octave) {
        value += amplitude * valueNoise(p);
        p = rotation * p * 2.03 + 13.17;
        amplitude *= 0.49;
    }
    return value;
}

float3 blackBodyRamp(float temperature) {
    const float3 darkRed = float3(0.180, 0.027, 0.000);
    const float3 red = float3(0.761, 0.165, 0.000);
    const float3 orange = float3(1.000, 0.416, 0.000);
    const float3 yellow = float3(1.000, 0.761, 0.278);
    const float3 whiteHot = float3(1.000, 0.875, 0.540);

    float3 color = mix(darkRed, red, smoothstep(0.05, 0.31, temperature));
    color = mix(color, orange, smoothstep(0.27, 0.53, temperature));
    color = mix(color, yellow, smoothstep(0.49, 0.76, temperature));
    color = mix(color, whiteHot, smoothstep(0.74, 1.0, temperature));
    return color;
}

vertex QuadOut fireVertex(uint vertexID [[vertex_id]]) {
    const float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    QuadOut out;
    float2 position = positions[vertexID];
    out.position = float4(position, 0.0, 1.0);
    out.uv = position * 0.5 + 0.5;
    return out;
}

fragment float4 fireFragment(QuadOut in [[stage_in]], constant FireUniforms &u [[buffer(0)]]) {
    float heat = clamp(u.heat / 100.0, 0.0, 1.0);
    float aspect = u.resolution.x / max(u.resolution.y, 1.0);
    float2 p = float2((in.uv.x - 0.5) * aspect, in.uv.y - 0.285);

    float slowFlicker = 0.95
        + 0.055 * (fbm4(float2(u.time * 0.37, 7.2)) - 0.5) * 2.0
        + 0.025 * sin(u.time * 3.71 + valueNoise(float2(u.time * 0.21, 2.4)) * 5.0);

    // Keep the flame comfortably inside the phone while still allowing a short
    // ignition jump when a new log lands.
    float targetHeight = mix(0.085, 0.60, pow(heat, 0.70));
    targetHeight *= 1.0 + u.burst * 0.14;
    float y = p.y / max(targetHeight, 0.001);
    float turbulence = smoothstep(-0.05, 1.0, y);

    // Two domain-warp stages create rolling folds instead of a periodic flame silhouette.
    float2 advected = float2(
        p.x * 3.8,
        p.y * 3.2 - u.time * mix(0.46, 0.83, heat) - u.burst * 0.24
    );
    float2 warpA = float2(
        fbm4(advected + float2(1.7, 5.3)),
        fbm4(advected * 1.07 + float2(8.1, 2.2))
    ) - 0.5;
    float2 warpB = float2(
        fbm4(advected * 1.62 + warpA * 2.15 + float2(4.4, 1.2)),
        fbm4(advected * 1.47 - warpA * 1.73 + float2(0.8, 9.4))
    ) - 0.5;

    float warpedX = p.x
        + warpA.x * mix(0.010, 0.065, turbulence)
        + warpB.x * mix(0.006, 0.038, turbulence)
        + sin(y * 9.0 - u.time * 2.1) * 0.008 * turbulence;
    float warpedY = p.y + warpA.y * 0.018 + warpB.y * 0.011;
    float warpedYN = warpedY / max(targetHeight, 0.001);

    float baseWidth = mix(0.042, 0.148, pow(heat, 0.78)) * (1.0 + u.burst * 0.10);
    float taper = mix(1.10, 0.085, smoothstep(-0.05, 1.02, warpedYN));
    float width = max(0.009, baseWidth * taper);
    float verticalMask = smoothstep(-0.055, 0.015, warpedY)
        * (1.0 - smoothstep(0.79, 1.08, warpedYN));

    // Low, medium and high heat have genuinely different silhouettes. A low
    // fire is one narrow tongue, medium heat forks in two, and high heat grows
    // a wide crown with several independently moving side flames.
    float smallCore = exp(-pow(abs(warpedX) / width, 1.82)) * verticalMask;

    float sideWidth = width * 0.72 + 0.003;
    float leftFork = exp(-pow(abs(warpedX + baseWidth * 0.50) / sideWidth, 1.70));
    float rightFork = exp(-pow(abs(warpedX - baseWidth * 0.46) / sideWidth, 1.70));
    float leftForkY = smoothstep(-0.04, 0.03, warpedY)
        * (1.0 - smoothstep(0.55, 0.78, warpedYN));
    float rightForkY = smoothstep(-0.04, 0.03, warpedY)
        * (1.0 - smoothstep(0.43, 0.68, warpedYN));
    float mediumShape = max(
        smallCore * 0.92,
        max(leftFork * leftForkY * 0.82, rightFork * rightForkY * 0.76)
    );

    float crownWidth = width * 0.62 + 0.004;
    float outerLeft = exp(-pow(abs(warpedX + baseWidth * 0.92) / crownWidth, 1.58));
    float outerRight = exp(-pow(abs(warpedX - baseWidth * 0.88) / crownWidth, 1.58));
    float outerLeftY = smoothstep(-0.045, 0.025, warpedY)
        * (1.0 - smoothstep(0.50, 0.74, warpedYN));
    float outerRightY = smoothstep(-0.045, 0.025, warpedY)
        * (1.0 - smoothstep(0.36, 0.61, warpedYN));
    float crownPulse = 0.82 + 0.18 * sin(u.time * 3.4 + warpedYN * 11.0 + warpB.y * 5.0);
    float largeShape = max(
        mediumShape,
        max(outerLeft * outerLeftY, outerRight * outerRightY) * crownPulse
    );

    float mediumBlend = smoothstep(0.34, 0.52, heat);
    float largeBlend = smoothstep(0.67, 0.82, heat);
    float stagedShape = mix(smallCore, mediumShape, mediumBlend);
    stagedShape = mix(stagedShape, largeShape, largeBlend);

    float detail = fbm4(float2(warpedX * 10.5, warpedY * 8.0 - u.time * 1.34));
    float fine = valueNoise(float2(warpedX * 31.0, warpedY * 24.0 - u.time * 2.42));
    float breakupThreshold = mix(0.24, 0.72, smoothstep(0.25, 1.0, warpedYN));
    float breakup = smoothstep(breakupThreshold - 0.20, breakupThreshold + 0.14, detail * 0.78 + fine * 0.22);
    float coherentBase = 1.0 - smoothstep(0.18, 0.82, warpedYN);
    float flameMask = stagedShape * max(coherentBase * 0.68, breakup);

    float flamePresence = smoothstep(0.095, 0.235, heat);
    float temperature = clamp(
        flameMask * flamePresence * (0.65 + detail * 0.38) * slowFlicker * (1.0 + u.burst * 0.24),
        0.0,
        1.0
    );
    temperature *= mix(0.86, 1.17, 1.0 - smoothstep(0.0, 0.64, warpedYN));

    // A wider analytic halo is the deliberately cheap single-pass bloom approximation.
    float haloWidth = width * 2.25 + 0.018;
    float halo = max(
        exp(-pow(abs(warpedX) / haloWidth, 1.45)),
        stagedShape * 0.52
    )
        * verticalMask
        * (1.0 - smoothstep(0.62, 1.05, warpedYN))
        * flamePresence;
    halo *= 0.13 + 0.15 * heat;

    // The ember bed is independent from flamePresence and therefore never disappears.
    float emberBreath = 0.77 + 0.23 * sin(u.time * 1.16 + fbm4(float2(u.time * 0.08, 3.0)) * 2.1);
    float2 emberP = float2(p.x / mix(0.105, 0.185, heat), (p.y + 0.003) / 0.041);
    float emberNoise = 0.70 + 0.30 * fbm4(float2(p.x * 27.0, p.y * 31.0 + u.time * 0.22));
    float ember = exp(-dot(emberP, emberP) * 1.38) * emberBreath * emberNoise;
    ember *= mix(0.52, 1.0, heat);

    float3 flameColor = blackBodyRamp(temperature) * temperature * mix(1.02, 1.52, heat);
    // Preserve the white-hot core while letting collectible flame styles
    // genuinely recolor the body and halo of the flame.
    float tintStrength = 0.74 * (1.0 - smoothstep(0.82, 1.0, temperature));
    flameColor = mix(flameColor, flameColor * u.flameTint.rgb * 1.62, tintStrength);
    float blueBase = stagedShape
        * smoothstep(-0.025, 0.025, warpedY)
        * (1.0 - smoothstep(0.10, 0.22, warpedYN))
        * smoothstep(0.48, 0.90, heat);
    flameColor += float3(0.12, 0.28, 0.82) * blueBase * 0.36;
    float3 haloColor = mix(float3(1.0, 0.16, 0.008), u.flameTint.rgb, 0.68) * halo;
    float3 emberColor = mix(float3(0.36, 0.006, 0.0), float3(1.0, 0.105, 0.006), ember) * ember;

    // Thin cool-gray smoke is most visible when only the ember bed remains.
    float smokeY = smoothstep(0.04, 0.23, p.y) * (1.0 - smoothstep(0.58, 0.91, p.y));
    float smokeCurl = fbm4(float2(p.x * 5.2 + warpA.x, p.y * 5.7 - u.time * 0.19));
    float smokeColumn = exp(-pow(abs(p.x + warpA.x * 0.055) / mix(0.045, 0.10, smokeCurl), 1.4));
    float smoke = smokeY * smokeColumn * smoothstep(0.42, 0.72, smokeCurl) * mix(0.11, 0.025, heat);

    float3 color = flameColor + haloColor + emberColor + float3(0.21, 0.23, 0.25) * smoke;
    float alpha = clamp(temperature * 0.91 + halo * 0.24 + ember * 0.88 + smoke * 0.34, 0.0, 1.0);
    return float4(color, alpha);
}

vertex SparkOut sparkVertex(
    const device SparkVertexIn *vertices [[buffer(0)]],
    constant FireUniforms &u [[buffer(1)]],
    uint vertexID [[vertex_id]]
) {
    SparkVertexIn spark = vertices[vertexID];
    SparkOut out;
    out.position = float4(spark.position * 2.0 - 1.0, 0.0, 1.0);
    out.pointSize = mix(1.4, 4.8, clamp(u.heat / 100.0, 0.0, 1.0)) * (0.75 + spark.seed * 0.55);
    out.life = spark.life;
    out.seed = spark.seed;
    return out;
}

fragment float4 sparkFragment(SparkOut in [[stage_in]], float2 pointCoord [[point_coord]]) {
    float2 centered = pointCoord - 0.5;
    float radial = smoothstep(0.5, 0.06, length(centered));
    float fadeIn = smoothstep(0.0, 0.08, in.life);
    float fadeOut = 1.0 - smoothstep(0.58, 1.0, in.life);
    float lifeAlpha = fadeIn * fadeOut;
    float3 hot = float3(1.0, 0.68, 0.22);
    float3 cold = float3(0.30, 0.018, 0.002);
    float3 color = mix(hot, cold, smoothstep(0.42, 1.0, in.life));
    float alpha = radial * lifeAlpha;
    return float4(color * alpha * 1.8, alpha);
}

