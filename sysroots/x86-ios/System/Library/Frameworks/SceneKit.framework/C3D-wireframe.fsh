

#extension GL_OES_standard_derivatives : enable

uniform vec4 u_color;
varying vec3 v_vertexCenter;

#if 0
// Fragment shader function
vec3 smooth(vec3 edge0, vec3 edge1, vec3 x);

vec3 smooth(vec3 edge0, vec3 edge1, vec3 x)
{
    vec3 t = clamp((x - edge0)/(edge1 - edge0), vec3(0.), vec3(1));
    return t * t * (3. - 2. * t);
}
#endif

void main()
{
    vec3 d = fwidth(v_vertexCenter);
    vec3 a3 = smoothstep(vec3(0.0), d * 1.5, v_vertexCenter);
    //    vec3 a3 = smoothstep(vec3(0.0), d * 1.5, in.center);
    float edge =  min(min(a3.x, a3.y), a3.z);
    if (edge >= 1.0)
        discard;
    gl_FragColor = u_color * (1.0 - edge) * 0.95;
}

