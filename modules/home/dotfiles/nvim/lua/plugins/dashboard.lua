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
  -- OJO: además de █ usa glifos Powerline de la zona de uso privado de Unicode
  -- (U+E0B8, U+E0BA, U+E0BC y U+E0BE: los triángulos inclinados). Solo existen
  -- en una Nerd Font. La terminal ya usa JetBrainsMono Nerd Font
  -- (programs/ghostty.nix), así que se ve; con otra fuente saldrían cajas
  -- vacías y el rótulo quedaría ilegible.
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

-- Los cuatro tonos que recorre el logo, en variante Catppuccin Mocha: del azul
-- de la punta al verde del final, pasando por el cian de en medio.
local stops = {
  "#89b4fa", -- blue
  "#74c7ec", -- sapphire
  "#94e2d5", -- teal
  "#a6e3a1", -- green
}

-- Contra qué se apaga la sombra (solo la usa `ansi_shadow`).
local shadow_base = "#181825" -- mantle
local shadow_mix = 0.6

local function to_rgb(hex)
  return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function blend(from, to, t)
  local fr, fg, fb = to_rgb(from)
  local tr, tg, tb = to_rgb(to)
  return string.format(
    "#%02x%02x%02x",
    math.floor(fr + (tr - fr) * t + 0.5),
    math.floor(fg + (tg - fg) * t + 0.5),
    math.floor(fb + (tb - fb) * t + 0.5)
  )
end

-- Color del degradado en la posición t ∈ [0,1]: busca entre qué dos paradas
-- cae y las interpola.
local function ramp(t)
  local pos = t * (#stops - 1)
  local i = math.min(math.floor(pos) + 1, #stops - 1)
  return blend(stops[i], stops[i + 1], pos - (i - 1))
end

-- Un grupo de resaltado por columna (y otro para su sombra). Se redefinen en
-- cada pintado en vez de una sola vez al arrancar porque cargar un colorscheme
-- borra los grupos: si se definieran antes, el banner saldría sin color la
-- primera vez. Es un puñado de `nvim_set_hl` una vez por dashboard, no se nota.
local function highlights()
  local hl = {}
  for col = 1, width do
    local color = ramp((col - 1) / (width - 1))
    hl[col] = {
      solid = ("NeovimLogo%02d"):format(col),
      shade = ("NeovimLogoShadow%02d"):format(col),
    }
    vim.api.nvim_set_hl(0, hl[col].solid, { fg = color })
    vim.api.nvim_set_hl(0, hl[col].shade, { fg = blend(color, shadow_base, shadow_mix) })
  end
  return hl
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
        push(char, hl[col].shade)
      else
        push(char, hl[col].solid)
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
        -- si fuera una tabla se saltaría el formato y con él el degradado.
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
