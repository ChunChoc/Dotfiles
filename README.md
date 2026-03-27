# NixOS Dotfiles

Configuración modular de NixOS con soporte multi-host.

## Hosts

| Host | Uso | Features |
|------|-----|----------|
| `vm` | Desarrollo/testing | development, virtualization, localsend |
| `thinkpad` | Trabajo y programación | development, localsend |
| `aorus` | Gaming y desarrollo ocasional | development, gaming, localsend |

## Instalación desde cero

### 1. Instalar NixOS

Instalación estándar con la ISO oficial. Durante la instalación, crear el usuario `chunchoc`.

### 2. Clonar dotfiles

```bash
cd ~
git clone https://github.com/TU_USUARIO/Dotfiles.git
cd Dotfiles
```

### 3. Copiar configuración de hardware

NixOS genera automáticamente un archivo con la configuración de hardware específica de tu máquina:

```bash
# Copiar el archivo autogenerado a tu host
cp /etc/nixos/hardware-configuration.nix ~/Dotfiles/hosts/TU_HOST/
```

> **Importante:** Reemplaza `TU_HOST` con `thinkpad` o `aorus` según corresponda.

### 4. Ajustar configuración de monitor

Editar `flake.nix` y modificar `monitorSettings` para tu host:

```nix
thinkpad = mkHost {
  hostname = "thinkpad";
  monitorSettings = {
    name = "eDP-1";        # Nombre del monitor (ver con `niri msg outputs`)
    width = 1920;
    height = 1080;
    refreshRate = 60;
    scale = 1.0;
  };
};
```

### 5. Aplicar configuración

```bash
sudo nixos-rebuild switch --flake ~/Dotfiles#TU_HOST
```

## Comandos útiles

### Aplicar cambios

```bash
# Aplicar configuración del sistema
sudo nixos-rebuild switch --flake ~/Dotfiles#TU_HOST
```

### Actualizar paquetes

```bash
# Actualizar flake.lock y aplicar cambios
cd ~/Dotfiles
nix flake update
sudo nixos-rebuild switch --flake .#TU_HOST
```

## Aliases disponibles

Estos aliases están configurados en zsh y usan el hostname actual automáticamente:

| Alias | Descripción |
|-------|-------------|
| `update` | Aplicar cambios de configuración |
| `upgrade` | Actualizar paquetes (`nix flake update`) y aplicar |
| `ll` | Listado largo (`ls -l`) |
| `root` | Obtener shell de root |
| `sudo` | Ejecuta `run0 --background=` |

## Estructura

```
Dotfiles/
├── flake.nix              # Punto de entrada, define hosts
├── lib/
│   └── options.nix        # Opciones custom (myFeatures)
├── hosts/
│   ├── vm/
│   ├── thinkpad/
│   └── aorus/
└── modules/
    ├── core/              # Sistema base (bootloader, system, user)
    ├── desktop.nix        # Niri + SDDM + Catppuccin
    ├── features/          # Features activables
    └── home/              # Configuración de usuario
```

## Activar/desactivar features

Editar `hosts/TU_HOST/default.nix`:

```nix
myFeatures = {
  development = true;    # Herramientas de desarrollo
  gaming = false;        # Steam + soporte 32-bit
  virtualization = true; # KVM/QEMU + virt-manager
  localsend = true;      # Abrir puertos para LocalSend
};
```

## Stack de software

- **Compositor:** Niri (scrolling-tiling Wayland)
- **Display Manager:** SDDM
- **Tema:** Catppuccin Mocha Mauve
- **Terminal:** Alacritty
- **Lanzador:** Fuzzel
- **Shell:** Zsh + Starship
