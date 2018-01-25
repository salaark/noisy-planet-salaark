#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_Specular;
uniform float u_Time;
uniform vec3 u_Camera;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

//NOISE FUNCTION (Found online from https://github.com/ashima/webgl-noise)
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

//Custom fractal brownian motion based on above noise function
float fbm(vec3 p) {
    float n = 0.0;
    float w = 0.5;
    for (int i = 0; i < 5; i++) {
        n += noise(p) * w;
        w *= 0.5;
        p *= 2.0;
        p += vec3(100);
    }
    return n;
}

void main()
{
        // Material base color (before shading)
        vec4 diffuseColor = u_Color;
        vec4 norm = normalize(fbm(vec3(fs_Pos.xyz)+vec3(u_Time*0.01, u_Time*0.01, u_Time*0.01))/1.5+fs_Nor);

        // Calculate the diffuse term for shader
        float diffuseTerm = dot(normalize(norm), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);

        float ambientTerm = 0.2;
        float lightIntensity = diffuseTerm + ambientTerm;

        // Material specular color
        vec4 specularColor = u_Specular;
        // Calculate the specular term for shader
        vec4 refl = normalize(normalize(vec4(u_Camera,1.0)-fs_Pos)+normalize(fs_LightVec));
        float intensity = (cos(u_Time/20.0)+2.0)*4.0;
        float specularTerm = pow(max(dot(refl,norm),0.0),intensity);

        // Compute final shaded color
        out_Col = vec4(diffuseColor.rgb * lightIntensity + specularColor.rgb * specularTerm, diffuseColor.a);
}
