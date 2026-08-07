// Estela suave del cursor ("smear"), el equivalente al cursor_trail de Kitty.
//
// Ghostty no trae animación de cursor: lo único que anima es el pipeline de
// custom shaders. Aquí el terminal ya dibujó el cursor en su posición nueva
// (viene en iChannel0); este shader solo pinta encima la cola que va desde
// donde estaba hasta donde está, y la encoge hasta desaparecer.
//
// Uniforms usados (ver ghostty.5, sección custom-shader):
//   iCurrentCursor/iPreviousCursor -> .xy esquina -X/+Y, .zw ancho y alto
//   iTimeCursorChange -> segundos (en la escala de iTime) del último movimiento

// Cuánto dura la estela. Más alto = más lento y más notorio.
#define DURATION 0.15
// Grosor de la cola respecto al lado corto del cursor.
#define TRAIL_THICKNESS 0.65
// Opacidad máxima de la cola.
#define TRAIL_OPACITY 0.9

// Distancia con signo a una cápsula (segmento de grosor r).
float sdSegment(in vec2 p, in vec2 a, in vec2 b, in float r) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = base;

    // Sin cursor visible no hay nada que animar.
    if (iCursorVisible.x < 0.5) {
        return;
    }

    float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    // Animación terminada: el frame queda idéntico al del terminal.
    if (progress >= 1.0) {
        return;
    }

    vec2 currentCenter = iCurrentCursor.xy + vec2(iCurrentCursor.z, -iCurrentCursor.w) * 0.5;
    vec2 previousCenter = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;

    // La punta de la cola persigue al cursor: al llegar a 1.0 se juntan.
    vec2 tailTip = mix(previousCenter, currentCenter, progress);
    float radius = min(iCurrentCursor.z, iCurrentCursor.w) * 0.5 * TRAIL_THICKNESS;

    float dist = sdSegment(fragCoord, tailTip, currentCenter, radius);
    // 1 px de antialias contra el borde de la cápsula.
    float mask = 1.0 - smoothstep(0.0, 1.0, dist);
    // ...y además se desvanece conforme se acorta.
    mask *= (1.0 - progress) * TRAIL_OPACITY;

    fragColor = mix(base, iCurrentCursorColor, mask);
}
