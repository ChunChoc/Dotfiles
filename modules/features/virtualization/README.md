# Feature `virtualization` — VM de Windows sobre KVM/libvirt

Qué cubre este módulo, qué NO puede cubrir, y la receta para levantar una VM de
Windows usable en una máquina nueva sin repetir el viacrucis de 2026-08-06.

## Qué automatiza el módulo

- libvirtd + QEMU + swtpm (TPM 2.0, requisito de Windows 11) + virtiofsd.
- Una ISO `virtio-win.iso` reempaquetada en `/var/lib/libvirt/images/`, que
  **añade dos MSI que la ISO oficial de Red Hat no trae**:
  `spice-vdagent-*.msi` y `winfsp.msi`. Sin ellos no hay resolución dinámica ni
  carpeta compartida (ver "Trampas" abajo).
- `libvirt-images-nocow.service`: marca `/var/lib/libvirt/images` con `chattr +C`
  para que las imágenes **nuevas** nazcan sin copy-on-write en btrfs.
- El comando `vm-nocow`, para arreglar imágenes creadas antes de eso.
- `~/Compartido`, la carpeta que la VM monta por virtiofs
  (declarada en `modules/home/virtualization.nix`).

## Qué NO automatiza (y por qué)

El **dominio libvirt** es estado imperativo: lo crea virt-manager y vive en
`/etc/libvirt/qemu/`. NixOS no tiene módulo declarativo para dominios sin meter
un input extra al flake (NixVirt), así que `win11.xml` de esta carpeta es una
**referencia**, no algo que se aplique solo.

Al copiarlo a otra máquina, revisa que coincidan:
`machine='pc-q35-*'`, las rutas de OVMF (`/run/libvirt/nix-ovmf/...`), la ruta de
la imagen, el `<source dir>` de virtiofs y la MAC de la interfaz.

## Receta en una máquina nueva

1. `sudo nixos-rebuild switch --flake ~/Dotfiles#<host>` con
   `myFeatures.virtualization = true` en el host.
2. Crear la VM en virt-manager: firmware **UEFI con Secure Boot**, TPM 2.0, disco
   **VirtIO**, red **VirtIO**, display **SPICE**, vídeo **QXL**. Montar
   `virtio-win.iso` como segundo CD-ROM (sin él el instalador no ve el disco).
3. Instalar Windows. En "¿Dónde instalar?" → *Cargar controlador* →
   `E:\virtio-win\viostor\w11\amd64`.
4. Aplicar el afinado de rendimiento al dominio: copia los bloques marcados en
   `win11.xml` con `sudo virsh --connect qemu:///system edit <dominio>`.
   Qué cambiar y por qué:

   | Ajuste | Por qué |
   |---|---|
   | `cache='none' io='native' iothread='1'` en el disco | sin esto el host cachea otra vez lo que el invitado ya cachea; en un portátil con poca RAM eso lleva a swap |
   | `<iothreads>1</iothreads>` | saca la E/S del disco del hilo principal de QEMU |
   | `hpet present='no'` | timer caro e inútil en Windows |
   | `rtc catchup` + `pit delay` | evita derivas de reloj |
   | `<stimer state='on'><direct state='on'/></stimer>` | el enlightenment Hyper-V que más pesa en Windows |
   | `emsr_bitmap`, `xmm_input` | enlightenments baratos, siempre convienen |
   | **quitar `avic`** | es una feature de **AMD**; en un host Intel solo estorba |
   | `<memoryBacking><source type='memfd'/><access mode='shared'/>` | requisito de virtiofs |
   | `<filesystem>` virtiofs → `~/Compartido` | la carpeta compartida |

   No añadas `hv-reenlightenment` salvo que el host tenga TSC scaling (Skylake y
   anteriores no lo tienen): QEMU se niega a arrancar.

5. Dentro de Windows, en este orden:
   - `E:\virtio-win\virtio-win-guest-tools.exe` → drivers VirtIO + QEMU guest agent.
   - `E:\spice-vdagent-x64-*.msi` → resolución dinámica y portapapeles.
   - `E:\winfsp.msi` → dependencia de `VirtioFsSvc`.
   - Reiniciar, y `sc.exe start VirtioFsSvc` (déjalo en `Automatic`).
6. En virt-manager: **Ver → Escalar pantalla → "Redimensionar VM con la ventana"**.
   Sin esto el agente nunca recibe la orden de resize aunque esté corriendo.

## Trampas que costaron horas (léelas antes de depurar)

1. **`virtio-win-guest-tools.exe` NO instala el agente SPICE ni WinFsp.** Solo
   drivers y guest agent. Es la causa número uno de "instalé todo y sigue en
   1024x768". Por eso este módulo mete los dos MSI en la ISO.

2. **El servicio del agente SPICE se llama `spice-agent`, no `vdservice`.** Lo
   renombraron en la versión 0.10.0. `sc query vdservice` devuelve ERROR 1060
   aunque esté instalado y corriendo, y te hace perseguir un fantasma.
   Usa `Get-Service spice-agent`.

3. **Registro fantasma de MSI**: si al doble clic el instalador solo ofrece
   Repair/Uninstall y "no pasa nada", Windows lo tiene registrado como instalado
   aunque los archivos no existan; `/i` solo reconfigura. En el log se ve
   `Configuration completed successfully` en vez de `Installation`. Se fuerza con:
   ```
   msiexec /x E:\spice-vdagent-x64-0.10.0.msi /qn
   msiexec /i E:\spice-vdagent-x64-0.10.0.msi /qn /norestart /l*v C:\vdagent.log
   ```

4. **qcow2 sobre btrfs sin nodatacow** es CoW sobre CoW: se fragmenta y amplifica
   cada escritura hasta arrastrarse. Es lo que hacía que la VM fuera lenta pese a
   tener KVM. El servicio `libvirt-images-nocow` lo previene en imágenes nuevas;
   para una existente, `sudo vm-nocow <dominio>` (VM apagada). `chattr +C` solo
   surte efecto en archivos vacíos, de ahí que haya que recopiar.

5. **NixOS no trae `chattr`/`lsattr`** en el PATH; están en `e2fsprogs`. Por eso
   `vm-nocow` se empaqueta con `writeShellApplication` y `runtimeInputs`: así sus
   dependencias son parte del cierre y no puede fallar a media ejecución.

## Truco de diagnóstico

El QEMU guest agent corre como **SYSTEM**, así que desde el host se puede
instalar y depurar dentro de Windows sin pelear con el UAC ni guiar clics:

```bash
virsh --connect qemu:///system qemu-agent-command win11 \
  '{"execute":"guest-exec","arguments":{"path":"msiexec.exe","arg":["/i","E:\\winfsp.msi","/qn"],"capture-output":true}}'
# devuelve {"return":{"pid":N}}; recoge el resultado con:
virsh --connect qemu:///system qemu-agent-command win11 \
  '{"execute":"guest-exec-status","arguments":{"pid":N}}'
# out-data viene en base64
```

## Comprobar que quedó bien

```bash
sudo lsattr /var/lib/libvirt/images/<dominio>.qcow2   # debe salir la bandera C
# flags reales de QEMU, no los del XML:
tr '\0' '\n' < /proc/$(pgrep -f 'qemu-system.*<dominio>')/cmdline \
  | grep -oE 'hpet=[a-z]*|hv-stimer-direct=on|cache.direct.:true|"aio":"native"'
pgrep -a virtiofsd     # debe apuntar a ~/Compartido
```

Dentro del invitado: `Get-Service spice-agent,VirtioFsSvc` (ambos `Running`), la
unidad `Z:` en el Explorador, y redimensionar la ventana de virt-manager para
confirmar que la resolución la sigue.

## Techo de rendimiento (no todo es configuración)

En el T480 (i5-8250U, 15 W, 4c/8t, iGPU UHD 620) **no hay passthrough posible**:
solo existe la gráfica integrada, y pasársela a la VM dejaría ciego al host. Para
apps de escritorio tipo Power BI eso da igual — QXL+SPICE es el camino correcto.
Lo que sí sigue pesando: la RAM (Power BI levanta un motor Analysis Services
local) y el TDP de 15 W. Ajuste opcional mientras se usa la VM:
`sudo cpupower frequency-set -g performance` (se come la batería, por eso no está
en el módulo).
