uniform mat4 u_modelViewProjectionTransform;

attribute vec4 a_position;
attribute vec4 a_color;

varying vec3 v_vertexCenter;

void main()
{
    vec3 pos = a_position.xyz;
    int id = int(a_position.w); //  Position stores the vertex ID in the current triangle. Yup, a bit ugly.

    gl_Position = (u_modelViewProjectionTransform * vec4(pos, 1.0));
    
    float s = 1.;
    mat3 centers = mat3(vec3(s, 0. ,0.), vec3(0., s, 0.), vec3(0., 0., s));
    v_vertexCenter = centers[id];
}
