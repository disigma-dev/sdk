uniform sampler2D sceneColor;
uniform sampler2D authoringColor;

uniform sampler2D sceneDepth;
uniform sampler2D authoringDepth;

varying vec2 uv;

void main()
{
    vec4 scene = texture2D(sceneColor, uv);
    vec4 authoring = texture2D(authoringColor, uv);

    float scene_depth = texture2D(sceneDepth, uv).r;
    float authoring_depth = texture2D(authoringDepth, uv).r;

    if(scene_depth < authoring_depth){
        authoring.rgb *= 0.75;
//        authoring.rgb = mix(authoring.rgb, vec3(dot(authoring.rgb, authoring.rgb)), 0.5);
    }
    
    gl_FragColor = mix(scene, authoring, authoring.a);
}

