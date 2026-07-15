# NixOS Dotfiles

Configuracion modular de NixOS con soporte multi-host, Home Manager y entorno grafico Wayland con Niri.

## Hosts

| Flake target | Carpeta | Uso | Features |
|--------------|---------|-----|----------|
| `thinkpad` | `hosts/thinkpad` | Trabajo y programacion | development, communication, office, localsend, batteryChargeLimit 90 |

Los hosts se definen con la funcion `mkHost` en `flake.nix`; agregar una maquina nueva es declarar su carpeta en `hosts/` y su entrada `mkHost` con sus monitores.

## Antes de Formatear

Verifica esto antes de instalar en hardware real:

- Tener una copia externa de archivos importantes.
- Saber que target vas a instalar (actualmente solo `thinkpad`).
- Tener internet disponible desde la ISO minimal.
- Tener este repositorio accesible por Git o en una USB.
- Recordar que `hardware-configuration.nix` se genera en cada maquina y no viene incluido en este repo.
- Recordar que el usuario `chunchoc` ya esta declarado en `modules/core/user.nix`; no hace falta crearlo a mano en la configuracion, pero si debes asignarle password antes de reiniciar.

## Instalacion Desde ISO Minimal

Estos pasos asumen que ya arrancaste desde la ISO minimal oficial de NixOS, particionaste/formateaste el disco y montaste el sistema en `/mnt`.

### 1. Generar configuracion base de hardware

```bash
nixos-generate-config --root /mnt
```

Esto crea `/mnt/etc/nixos/hardware-configuration.nix` con discos, filesystem, swap, CPU, GPU y otros detalles especificos de la maquina.

### 2. Clonar dotfiles dentro del sistema nuevo

```bash
git clone https://github.com/TU_USUARIO/Dotfiles.git /mnt/etc/nixos/Dotfiles
cd /mnt/etc/nixos/Dotfiles
```

Reemplaza `TU_USUARIO` por el usuario real del repositorio.

### 3. Copiar hardware-configuration.nix al host correcto

```bash
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/Dotfiles/hosts/thinkpad/hardware-configuration.nix
```

El archivo debe quedar en la misma carpeta que el `default.nix` del host que vas a instalar.

### 4. Revisar el monitor del host

Edita `flake.nix` si necesitas ajustar resolucion, refresh rate o escala:

```nix
thinkpad = mkHost {
  hostname = "thinkpad";
  monitorSettings = {
    name = "eDP-1";
    width = 1920;
    height = 1080;
    refreshRate = 60;
    scale = 1.0;
  };
};
```

Si no sabes el nombre exacto del monitor, deja `eDP-1` para laptop. Despues de iniciar Niri puedes comprobarlo con:

```bash
niri msg outputs
```

### 5. Instalar usando el flake

```bash
nixos-install --flake /mnt/etc/nixos/Dotfiles#thinkpad
```

### 6. Asignar password al usuario

El usuario `chunchoc` se crea por la configuracion declarativa, pero este repo no define una password por seguridad. Antes de reiniciar, asignala dentro del sistema instalado:

```bash
nixos-enter --root /mnt -c 'passwd chunchoc'
```

Este paso evita quedar bloqueado en la TTY sin poder iniciar sesion.

### 7. Reiniciar

```bash
reboot
```

Al iniciar, deberias poder entrar con el usuario `chunchoc` y la password que acabas de definir.

### 8. Mover los dotfiles al home del usuario

Durante la instalacion el repo se clono en `/etc/nixos/Dotfiles` dentro del sistema nuevo. Despues del primer inicio de sesion, copialo a `~/Dotfiles` para que los aliases `update` y `upgrade` funcionen como estan escritos:

```bash
cp -r /etc/nixos/Dotfiles ~/Dotfiles
cd ~/Dotfiles
```

Esto conserva el `hardware-configuration.nix` que copiaste durante la instalacion.

## Aplicar Cambios Despues de Instalar

Cuando ya estes dentro del sistema instalado, trabaja desde `~/Dotfiles`.

Aplicar cambios sin actualizar paquetes:

```bash
sudo nixos-rebuild switch --flake ~/Dotfiles#$(hostname)
```

Aplicar cambios para un host especifico:

```bash
sudo nixos-rebuild switch --flake ~/Dotfiles#thinkpad
```

Actualizar `flake.lock` y aplicar:

```bash
cd ~/Dotfiles
nix flake update
sudo nixos-rebuild switch --flake .#$(hostname)
```

## Aliases Disponibles

Estas funciones y abreviaturas estan configuradas en Fish (`modules/home/programs/fish.nix`) y usan el hostname actual automaticamente:

| Alias | Descripcion |
|-------|-------------|
| `update` | Aplica la configuracion actual con `nixos-rebuild switch` |
| `upgrade` | Ejecuta `nix flake update`, agrega `flake.lock` a Git y aplica la configuracion |
| `ls` / `ll` | Listados con `eza` (iconos, directorios primero) |
| `cat` | `bat` con resaltado |
| `cd` | `z` (zoxide) |
| `nd` | `nix develop --command fish` |
| `root` | Obtiene shell de root usando `run0 --background=` |
| `sudo` | Funcion que envuelve `run0 --background=` |

## Estructura

```text
Dotfiles/
├── flake.nix              # Punto de entrada, define hosts y monitorSettings
├── flake.lock             # Versiones bloqueadas de nixpkgs y home-manager
├── lib/
│   └── options.nix        # Opciones custom myFeatures
├── hosts/
│   └── thinkpad/          # Host para laptop ThinkPad
└── modules/
    ├── core/              # Sistema base: bootloader, usuario, Nix, locale
    ├── desktop.nix        # Niri, DMS, PipeWire, keyring y PAM
    ├── features/          # Features activables por host
    └── home/              # Home Manager, paquetes, temas y dotfiles de usuario
```

## Activar o Desactivar Features

Edita `hosts/TU_HOST/default.nix`:

```nix
myFeatures = {
  development = true;    # Editores, LSP de Nix y agentes AI (con su config de usuario)
  communication = true;  # Discord, Signal
  office = true;         # LibreOffice
  gaming = false;        # Steam + soporte 32-bit
  virtualization = false; # KVM/QEMU + virt-manager
  localsend = true;      # App LocalSend + sus puertos de firewall
  batteryChargeLimit = 90; # Limite de carga de bateria (1-100)
};
```

## Stack de Software

- Compositor: Niri
- Shell/bar: DankMaterialShell
- Login: greetd + dms-greeter (sesion `niri-dms`)
- Tema: Catppuccin Mocha Mauve
- Terminal: Alacritty
- Editor: Neovim (LazyVim) + Zed
- Shell: Fish + Starship
- Audio: PipeWire

## Problemas Comunes

### No puedo iniciar sesion despues de instalar

Probablemente no asignaste password a `chunchoc`. Desde la ISO minimal, monta tu sistema de nuevo y ejecuta:

```bash
nixos-enter --root /mnt -c 'passwd chunchoc'
```

### Falta hardware-configuration.nix

Generalo desde la ISO con:

```bash
nixos-generate-config --root /mnt
```

Luego copialo al host correcto dentro de `hosts/`.
