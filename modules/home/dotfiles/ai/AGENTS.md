# Cómo trabajo con agentes

Hábitos que valen en TODOS mis proyectos. Lo que es regla de un repo va en el
`AGENTS.md` de ese repo, no aquí.

## Presupuesto de salida
- **Ningún comando debe volcar más de ~50 líneas.** El contexto es el recurso escaso de una
  sesión larga: las suites de tests pasan con `2>&1 | tail -5` y solo se imprimen enteras
  cuando fallan.
- Un artefacto que hay que inspeccionar (un documento renderizado, un JSON grande) se escribe
  a un archivo y se lee con `Read` (`offset`/`limit`) o se recorta con `grep -n`. Nunca `cat`
  de un archivo grande ni un `python -c` que imprima el resultado completo.

## Entorno (NixOS)
- Todo es declarativo: la toolchain de un proyecto vive en su `devenv.nix` y el sistema en
  `~/Dotfiles`. No instalar nada con `apt`, `pip`, `npm -g` ni `curl | sh`.
- Los binarios dinámicos descargados de fuera de Nix no corren; si algo "no encuentra" una
  librería, es eso y no un bug del proyecto.
- No tocar `.env*`, llaves SSH/GPG ni credenciales. No hacer `force-push`.
- Commitear solo cuando lo pida.
