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

// --------------------------------------------------------
// Movimiento: el mismo muelle que usa niri
// --------------------------------------------------------
// Todo el escritorio (niri + DMS) se mueve con muelles al estilo Material 3
// Expressive: arranque rápido y frenada larga y blanda, nunca a velocidad
// constante. Una estela interpolada linealmente se sentía mecánica al lado del
// resto, así que aquí se resuelve el mismo muelle subamortiguado.
//
// Los valores son los de `window-movement` en niri/config.kdl —el caso análogo,
// algo que se desplaza por la pantalla— y no una elección aparte: si algún día
// se retoca allí, hay que copiarlo aquí.
#define SPRING_DAMPING 0.82
#define SPRING_STIFFNESS 750.0
// Igual que el `epsilon` de niri: cuándo se da por terminado el muelle.
#define SPRING_EPSILON 0.0001
// Grosor de la cola respecto al lado corto del cursor.
#define TRAIL_THICKNESS 0.65
// Opacidad máxima de la cola.
#define TRAIL_OPACITY 0.9
// Celdas que se tiene que mover el cursor para que aparezca la estela. Es el
// equivalente al cursor_trail_start_threshold de Kitty (que también usa 2): al
// escribir el cursor avanza de una en una, así que no se dispara; solo en
// saltos (limpiar la pantalla, moverse en vim, cambiar de línea).
#define START_THRESHOLD 2.0

// Muelle subamortiguado de 0 a 1, en reposo al empezar. Es la misma solución
// analítica que integra niri, con masa 1:
//   x(t) = 1 - e^(-ζω₀t)·(cos(ω_d·t) + (ζω₀/ω_d)·sin(ω_d·t))
// Con ζ=0.82 el rebote máximo es del 1 %, así que asoma como un frenado suave y
// no como un vaivén; aun así se recorta a 1 para que la cola nunca adelante al
// cursor.
float spring(in float t, in float omega0, in float decay) {
    float omegaD = omega0 * sqrt(1.0 - SPRING_DAMPING * SPRING_DAMPING);
    float x = 1.0 - exp(-decay * t) * (cos(omegaD * t) + (decay / omegaD) * sin(omegaD * t));
    return clamp(x, 0.0, 1.0);
}

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

    float omega0 = sqrt(SPRING_STIFFNESS);
    float decay = SPRING_DAMPING * omega0;
    // La duración no se elige a ojo: es la que tarda el muelle en caer por
    // debajo de su epsilon. Con estos valores salen ~0.41 s, de los cuales los
    // primeros ~0.17 s son los que se ven de verdad; el resto es la cola de la
    // exponencial, ya casi transparente.
    float duration = log(1.0 / SPRING_EPSILON) / decay;

    float elapsed = iTime - iTimeCursorChange;
    // Animación terminada: el frame queda idéntico al del terminal.
    if (elapsed < 0.0 || elapsed >= duration) {
        return;
    }

    float progress = spring(elapsed, omega0, decay);

    vec2 currentCenter = iCurrentCursor.xy + vec2(iCurrentCursor.z, -iCurrentCursor.w) * 0.5;
    vec2 previousCenter = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;

    // El salto, medido en celdas y no en píxeles: el cursor mide una celda, así
    // que dividir entre su ancho y su alto vuelve comparables el eje horizontal
    // y el vertical (una fila y una columna cuentan igual, como en Kitty).
    vec2 cell = max(iCurrentCursor.zw, vec2(1.0));
    if (length((currentCenter - previousCenter) / cell) < START_THRESHOLD) {
        return;
    }

    // La punta de la cola persigue al cursor: al llegar a 1.0 se juntan.
    vec2 tailTip = mix(previousCenter, currentCenter, progress);
    float radius = min(iCurrentCursor.z, iCurrentCursor.w) * 0.5 * TRAIL_THICKNESS;

    float dist = sdSegment(fragCoord, tailTip, currentCenter, radius);
    // 1 px de antialias contra el borde de la cápsula.
    float mask = 1.0 - smoothstep(0.0, 1.0, dist);
    // ...y además se desvanece con la propia envolvente del muelle, e^(-ζω₀t).
    // Así el desvanecido y el movimiento terminan a la vez y en el último frame
    // la opacidad ya vale epsilon: se apaga sin corte visible. Hace falta que
    // llegue a cero porque la cápsula nunca se queda sin grosor —si no, sobre el
    // cursor quedaría una mancha morada fija.
    mask *= exp(-decay * elapsed) * TRAIL_OPACITY;

    fragColor = mix(base, iCurrentCursorColor, mask);
}
