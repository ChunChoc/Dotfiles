-- Cabecera del dashboard: "NEOVIM" con el degradado del logo
--
-- Sustituye al banner que trae LazyVim (el "LAZYVIM" con las zzz al lado).
--
-- El degradado es HORIZONTAL, columna por columna, porque así es el logo
-- oficial: la N va del azul de la punta izquierda al verde de la derecha. Lo
-- fácil habría sido pintar una línea de cada color (degradado vertical), pero
-- eso no se parece al logo, que es justo lo que se quería.
--
-- Se probó también con los dos colores planos, "Neo" en azul y "Vim" en verde,
-- y se descartó: el degradado quedaba mejor.
--
-- Cómo se consigue un color por columna: Snacks deja que un campo se formatee
-- a una lista de trozos `{ texto, hl = grupo }` y le pone un extmark propio a
-- cada trozo (ver `D:render` y `D:block` en snacks.nvim/lua/snacks/dashboard.lua).
-- Así que basta con partir cada línea en caracteres y darle a cada uno su
-- grupo. No hacen falta extmarks a mano ni un plugin aparte.

-- Los dos rótulos, ambos de MaximilianLloyd/ascii.nvim (lua/ascii/text/neovim.lua).
-- El que se usa es el de `art`, justo debajo de la tabla.
--
-- Todas las líneas de un rótulo tienen que medir lo mismo y sus caracteres han
-- de ser de ancho simple: `width` es lo que reparte el degradado y lo que se
-- usa para centrar. Si se cambia el arte, se recuenta.
local arts = {
  -- El logo angular, el que se parece de verdad al de Neovim (incluida la
  -- banderita, que aquí cae encima de la i).
  --
  -- Los bordes usan triángulos Powerline extendidos de la Nerd Font.
  -- Conservar sus diagonales originales: sustituirlos por sextantes produce
  -- dientes de sierra visibles en lugar de corregir el renderizado.
  sharp = {
    width = 71,
    -- Sin sombra: aquí los triángulos son el borde inclinado de la letra, no
    -- un relieve. Apagarlos le comería las diagonales, que es justo lo que
    -- hace que se lea como el logo.
    shadow = "",
    lines = {
      "                                                                     ",
      "       ████ ██████           █████      ██                     ",
      "      ███████████             █████                             ",
      "      █████████ ███████████████████ ███   ███████████   ",
      "     █████████  ███    █████████████ █████ ██████████████   ",
      "    █████████ ██████████ █████████ █████ █████ ████ █████   ",
      "  ███████████ ███    ███ █████████ █████ █████ ████ █████  ",
      " ██████  █████████████████████ ████ █████ █████ ████ ██████ ",
    },
  },

  -- La tipografía "ANSI Shadow" de figlet: bloques macizos y, detrás, una
  -- sombra hecha de caracteres de caja. Más sobria y sin depender de una Nerd
  -- Font. Fue la primera versión; se queda por si se quiere volver.
  ansi_shadow = {
    width = 50,
    -- Estos caracteres no son el cuerpo de la letra, son la sombra que dibuja
    -- la tipografía: se pintan apagados y eso es lo que le da el relieve.
    shadow = "╔╗╚╝═║",
    lines = {
      "███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
      "████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
      "██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
      "██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
      "██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
      "╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
    },
  },
}

local art = arts.sharp
local width = art.width

local shadow = {}
for _, char in ipairs(vim.fn.split(art.shadow, "\\zs")) do
  shadow[char] = true
end

-- Tramos del logo en ANSI: Alacritty cambia sus colores con DMS, incluso
-- mientras el dashboard está abierto.
local stops = { 4, 12, 6, 14, 2 }

-- Se redefinen al pintar porque cargar un colorscheme borra los grupos.
local function highlights()
  local groups = {}
  for index, color in ipairs(stops) do
    local group = ("NeovimLogo%02d"):format(index)
    vim.api.nvim_set_hl(0, group, { ctermfg = color })
    groups[index] = group
  end
  vim.api.nvim_set_hl(0, "NeovimLogoShadow", { ctermfg = 8 })
  return groups
end

---@param ctx { width: number }
local function header(_, ctx)
  local hl = highlights()
  local texts = {}

  -- Centrado a mano. `ctx.width` es el ancho útil que Snacks le deja a este
  -- campo (su `opts.width`, 60 por defecto); calcularlo así en vez de meter
  -- espacios fijos en el arte hace que siga centrado si algún día cambia.
  --
  -- Con un rótulo más ancho que ese hueco (el caso de `sharp`, 71) esto da 0 y
  -- el centrado lo termina haciendo Snacks, que reconoce las líneas que se le
  -- salen y las recoloca (`D:render`, la rama `line.width > self.opts.width`).
  local pad = math.max(0, math.floor((ctx.width - width) / 2))

  -- Junta trozos seguidos del mismo grupo para no generar un extmark por
  -- carácter cuando no hace falta (los espacios, sobre todo).
  local function push(str, group)
    local last = texts[#texts]
    if last and last.hl == group then
      last[1] = last[1] .. str
    else
      texts[#texts + 1] = { str, hl = group }
    end
  end

  for row, line in ipairs(art.lines) do
    if row > 1 then
      push("\n", nil)
    end
    push((" "):rep(pad), nil)
    local col = 0
    for _, char in ipairs(vim.fn.split(line, "\\zs")) do
      col = col + 1
      if char == " " then
        push(char, nil)
      elseif shadow[char] then
        push(char, "NeovimLogoShadow")
      else
        local band = math.floor((col - 1) * #hl / width) + 1
        push(char, hl[band])
      end
    end
  end

  return texts
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        -- El texto plano se queda aquí porque es lo que recibe la función de
        -- formato de abajo: Snacks solo pinta el campo `header` si existe, y
          -- si fuera una tabla se saltaría el formato y con él los colores.
        preset = {
          header = table.concat(art.lines, "\n"),
        },
        formats = {
          header = header,
        },
      },
    },
  },
}
