# NixOS Dotfiles

Configuracion modular de NixOS con soporte multi-host, Home Manager y entorno grafico Wayland con Niri.

## Hosts

| Flake target | Carpeta | Uso | Features |
|--------------|---------|-----|----------|
| `thinkpad` | `hosts/thinkpad` | Trabajo y programacion | development, localsend |
| `aorus` | `hosts/aorus` | Gaming y desarrollo ocasional | development, gaming, localsend |
| `nixos-vm` | `hosts/vm` | Desarrollo/testing en VM | development, virtualization, localsend |

> Nota: la VM usa la carpeta `hosts/vm`, pero el target del flake y el hostname son `nixos-vm`.

## Antes de Formatear

Verifica esto antes de instalar en hardware real:

- Tener una copia externa de archivos importantes.
- Saber que target vas a instalar: `thinkpad` o `aorus`.
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

Para ThinkPad:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/Dotfiles/hosts/thinkpad/hardware-configuration.nix
```

Para Aorus:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/Dotfiles/hosts/aorus/hardware-configuration.nix
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

Para ThinkPad:

```bash
nixos-install --flake /mnt/etc/nixos/Dotfiles#thinkpad
```

Para Aorus:

```bash
nixos-install --flake /mnt/etc/nixos/Dotfiles#aorus
```

### 6. Asignar password al usuario

El usuario `chunchoc` se crea por la configuracion declarativa, pero este repo no define una password por seguridad. Antes de reiniciar, asignala dentro del sistema instalado:

```bash
nixos-enter --root /mnt -c 'passwd chunchoc'
```

Este paso evita quedar bloqueado en SDDM sin poder iniciar sesion.

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
sudo nixos-rebuild switch --flake ~/Dotfiles#aorus
sudo nixos-rebuild switch --flake ~/Dotfiles#nixos-vm
```

Actualizar `flake.lock` y aplicar:

```bash
cd ~/Dotfiles
nix flake update
sudo nixos-rebuild switch --flake .#$(hostname)
```

## Aliases Disponibles

Estos aliases estan configurados en Zsh y usan el hostname actual automaticamente:

| Alias | Descripcion |
|-------|-------------|
| `update` | Aplica la configuracion actual con `nixos-rebuild switch` |
| `upgrade` | Ejecuta `nix flake update`, agrega `flake.lock` a Git y aplica la configuracion |
| `ll` | Listado largo con `ls -l` |
| `root` | Obtiene shell de root usando `run0 --background=` |
| `sudo` | Alias de `run0 --background=` |

## Estructura

```text
Dotfiles/
├── flake.nix              # Punto de entrada, define hosts y monitorSettings
├── flake.lock             # Versiones bloqueadas de nixpkgs y home-manager
├── lib/
│   └── options.nix        # Opciones custom myFeatures
├── hosts/
│   ├── vm/                # Host usado por el target nixos-vm
│   ├── thinkpad/          # Host para laptop ThinkPad
│   └── aorus/             # Host para laptop/PC Aorus
└── modules/
    ├── core/              # Sistema base: bootloader, usuario, Nix, locale
    ├── desktop.nix        # Niri, DMS, SDDM, PipeWire, Catppuccin
    ├── features/          # Features activables por host
    └── home/              # Home Manager, paquetes, temas y dotfiles de usuario
```

## Activar o Desactivar Features

Edita `hosts/TU_HOST/default.nix`:

```nix
myFeatures = {
  development = true;    # Herramientas de desarrollo
  gaming = false;        # Steam + soporte 32-bit
  virtualization = true; # KVM/QEMU + virt-manager
  localsend = true;      # Abre puertos para LocalSend
};
```

## Stack de Software

- Compositor: Niri
- Shell/bar: DankMaterialShell
- Display Manager: SDDM
- Tema: Catppuccin Mocha Mauve
- Terminal: Alacritty
- Lanzador: Fuzzel
- Shell: Zsh + Starship
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

### El target vm no existe

El target correcto para la VM es `nixos-vm`, no `vm`:

```bash
nixos-rebuild switch --flake ~/Dotfiles#nixos-vm
```

### Quiero probar antes de instalar en hardware real

Usa la VM primero:

```bash
nixos-install --flake /mnt/etc/nixos/Dotfiles#nixos-vm
```
