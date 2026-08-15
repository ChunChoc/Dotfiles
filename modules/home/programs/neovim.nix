{ config, pkgs, ... }:

{
  # --------------------------------------------------------
  # LazyVim (Neovim como IDE de terminal)
  # --------------------------------------------------------
  # La config Lua vive en el repo como archivos normales (igual que Niri).
  # Se enlaza FUERA de la store con mkOutOfStoreSymlink porque lazy.nvim
  # necesita escribir lazy-lock.json en ~/.config/nvim; un symlink a la
  # store (solo lectura) rompería la instalación de plugins.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Dotfiles/modules/home/dotfiles/nvim";

  home.packages = with pkgs; [
    # LazyVim lo usa para pickers y grep (lazygit viene de programs/lazygit.nix)
    ripgrep

    # Treesitter compila sus parsers en runtime y necesita un compilador C
    # y el CLI de tree-sitter en el PATH incluso fuera de un devshell
    # (p. ej. editando estos dotfiles)
    gcc
    tree-sitter

    # Linters/formatters que piden los extras de LazyVim para archivos que
    # se editan fuera de un devshell (estos dotfiles, notas en markdown):
    # con Mason desactivado deben venir del PATH
    statix
    nixfmt
    markdownlint-cli2
    markdown-toc
    prettier

    # El extra lang.astro necesita el binario astro-ls en el PATH; el
    # ts-plugin que lo acompaña se enlaza abajo en la ruta de Mason.
    astro-language-server

    # Resto de LSP que activan los extras importados en config/lazy.lua y que
    # ningún devshell provee. Sin ellos Neovim los descarta en silencio al no
    # ser ejecutables; tailwindcss además falla en el spawn con un error
    # visible al abrir cualquier .ts/.tsx/.astro de un proyecto con Tailwind.
    tailwindcss-language-server # lang.tailwind
    marksman # lang.markdown
    vscode-langservers-extracted # lang.json -> vscode-json-language-server
    ruff # lang.python (LSP + formateo; un devshell que lo fije tiene prioridad)
    lua-language-server # lua_ls, del core de LazyVim (estos mismos dotfiles)
  ];

  # El extra lang.astro de LazyVim busca @astrojs/ts-plugin dentro del árbol
  # de paquetes de Mason (LazyVim.get_pkg_path) y avisa con un warning al
  # abrir cualquier proyecto si no existe. Con Mason desactivado, se enlaza
  # ahí el plugin real que trae astro-language-server de nixpkgs.
  home.file.".local/share/nvim/mason/packages/astro-language-server/node_modules/@astrojs/ts-plugin".source =
    "${pkgs.astro-language-server}/lib/node_modules/astro-language-server/packages/language-tools/ts-plugin";

  # direnv + nix-direnv: al entrar al directorio de un proyecto, cualquier
  # proceso (incluido nvim en su propio tab de Herdr) hereda el devshell del
  # flake con sus LSP/formatters, sin tener que correr `nix develop -c nvim`.
  # La integración con Fish es automática al estar programs.fish habilitado.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    # Sin las líneas "direnv: loading/export..." en cada cd. Ojo: también
    # silencia el aviso de ".envrc is blocked"; en un proyecto nuevo hay que
    # acordarse de correr `direnv allow` a mano.
    silent = true;

    # ------------------------------------------------------------------
    # use devenv_locked: un devenv a la vez por proyecto
    # ------------------------------------------------------------------
    # `stdlib` acaba en ~/.config/direnv/direnvrc, que direnv carga antes que
    # cualquier .envrc. Lo que se defina aquí está disponible en todos los
    # proyectos.
    #
    # El problema que resuelve: devenv da por hecho que solo corre una
    # instancia por directorio y escribe archivos compartidos dentro de
    # .devenv/ sin ningún candado. Cuando un espacio de herdr abre sus dos o
    # tres tabs de golpe, los tres devenv arrancan a la vez y se pisan:
    #
    #   .devenv/load-exports  -> se escribe y después se le hace chmod; si otro
    #                            proceso lo reemplaza en medio, el chmod falla.
    #   .devenv/gc/shell      -> es un symlink que devenv BORRA y vuelve a
    #                            crear; si dos lo borran, el segundo se lleva
    #                            "Failed to remove existing GC root (os error 2)".
    #
    # El resultado es que una de las pestañas se queda sin entorno y hay que
    # hacerle `direnv reload` a mano. Reproducido lanzando tres
    # `devenv direnv-export` en paralelo: falla de forma intermitente.
    #
    # La corrección es un candado por proyecto: con flock solo un devenv entra
    # a la vez y los demás esperan su turno. No esconde la carrera, la vuelve
    # imposible. El precio es que los tabs 2 y 3 esperan al 1, que con la caché
    # de devenv son segundos; tras tocar devenv.nix esperan la evaluación
    # entera, pero esa espera ya existía —solo que antes terminaba en error.
    #
    # El candado vive en XDG_RUNTIME_DIR (tmpfs), así que no deja rastro en el
    # repo y desaparece al reiniciar. La clave es la ruta del proyecto con las
    # barras cambiadas por %, para no depender de ningún comando externo.
    #
    # Se descartó reintentar cuando falla: esconde el problema en vez de
    # arreglarlo.
    stdlib = ''
      use_devenv_locked() {
        local lock="''${XDG_RUNTIME_DIR:-/tmp}/devenv-lock-''${PWD//\//%}"

        # Sin timeout a propósito: quien tiene el candado siempre acaba
        # soltándolo (lo libera el kernel al morir el proceso), y esperar una
        # compilación larga es justo lo que se quiere. Un timeout solo
        # devolvería el fallo que se está corrigiendo.
        exec {devenv_lock_fd}>"$lock"
        flock "$devenv_lock_fd"

        use devenv "$@"
      }
    '';
  };
}
