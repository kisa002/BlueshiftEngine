$include "fragment_common.glsl"

#ifdef USE_SHADOW_MAP
$include "shadow.fp"
#endif

in vec4 v2f_color;
in vec3 v2f_normal;
in vec3 v2f_lightVector;
in vec2 v2f_texCoord;
in vec3 v2f_viewVector;
in vec3 v2f_lightFallOff;
in vec4 v2f_lightProjection;

out vec4 o_fragColor : FRAG_COLOR;

uniform sampler2D diffuseMap;
uniform sampler2D specularMap;
uniform sampler2D lightProjectionMap;
uniform samplerCube lightCubeMap;

uniform vec3 specularColor;
uniform float specularExponent = 32.0;
uniform vec4 lightColor;
uniform float lightFallOffExponent;
uniform bool useLightCube;
uniform bool useShadowMap;
uniform bool removeBackProjection;

// TODO: to be replaced by 2dmap
float toonify(float intensity) {
	float t;

	if (intensity > 0.899) {
		t = 1.0;
	} else if (intensity > 0.499) {
		t = 0.7;
	} else {
		t = 0.3;
	}

	return t;
}

void main() {
	vec3 L = normalize(v2f_lightVector);

	float A = 1.0 - min(dot(v2f_lightFallOff, v2f_lightFallOff), 1.0);
	A = pow(A, lightFallOffExponent);

	vec3 Cl = tex2Dproj(lightProjectionMap, v2f_lightProjection).xyz * lightColor.xyz * A;

#ifdef USE_LIGHT_CUBE_MAP
	if (useLightCube) {
		Cl *= texCUBE(lightCubeMap, -L);
	}
#endif

#ifndef USE_SHADOW_POINT
	if (removeBackProjection) {
		Cl *= min((v2f_lightProjection.z < 0.0 ? 0.0 : 10.0) * v2f_lightProjection.z / v2f_lightProjection.w, 1.0);
	}
#endif

	if (Cl == vec3(0.0)) {
		discard;
	}

	vec3 shadowLighting = vec3(1.0);

#if defined(USE_SHADOW_MAP)
#if defined(USE_SHADOW_SPOT) || defined(USE_SHADOW_POINT) || defined(USE_SHADOW_CASCADE)
	shadowLighting = ShadowFunc();
	/*if (shadowLighting == 0.0) {
		discard;
	}*/
#endif
#endif

#if _DIFFUSE_SOURCE == 0
	vec4 diffuse = diffuseColor;
#elif _DIFFUSE_SOURCE == 1
	vec4 diffuse = tex2D(diffuseMap, v2f_texCoord);
#endif

#ifdef PERFORATED
	if (diffuse.w < 0.5) {
		discard;
	}
#endif

	vec3 N = normalize(v2f_normal);
	float NdotL = max(dot(N, L), 0.0);

	vec3 Cd = diffuse.xyz * toonify(NdotL);

	vec3 R = reflect(-L, N);
	float RdotV = max(dot(R, V), 0.0);

#if _SPECULAR_SOURCE == 0
	vec3 Cs = vec3(0.0, 0.0, 0.0);
#elif _SPECULAR_SOURCE == 1
	vec3 Cs = specularColor.xyz * (pow((NdotL > 0.0 ? RdotV : 0.0), specularExponent) > 0.9 ? 1.0 : 0.0);
#elif _SPECULAR_SOURCE == 2
	vec3 Cs = tex2D(specularMap, v2f_texCoord).xyz * (pow(NdotL > 0.0 ? RdotV : 0.0, specularExponent) > 0.9 ? 1.0 : 0.0);
#endif

	vec3 C = Cd + Cs;

	vec3 V = normalize(v2f_viewVector);
	float NdotV = max(dot(N, V), 0.0) < 0.15 ? 0.0 : 1.0;

	C *= NdotV * shadowLighting;

	vec4 outputColor = v2f_color * vec4(Cl * C, diffuse.w);

#ifdef LOGLUV_HDR
	o_fragColor = encodeLogLuv(outputColor.xyz);
#else
	o_fragColor = outputColor;
#endif
}
