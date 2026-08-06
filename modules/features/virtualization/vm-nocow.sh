# Reescribe una imagen de VM con nodatacow (btrfs).
#
# Por qué: btrfs hace copy-on-write. Un qcow2 encima es CoW sobre CoW: cada
# escritura del invitado se amplifica y la imagen se fragmenta hasta que la VM
# se arrastra. `chattr +C` solo surte efecto en archivos vacíos, así que la
# única forma de arreglar una imagen existente es copiarla a un archivo nuevo
# que nazca marcado.
#
# El servicio libvirt-images-nocow ya marca /var/lib/libvirt/images, así que las
# imágenes NUEVAS no necesitan esto. Solo hace falta para las creadas antes de
# que ese servicio existiera, o para imágenes fuera de ese directorio.
#
# Uso:  sudo vm-nocow [dominio] [ruta-imagen]
#       sudo vm-nocow            -> win11, /var/lib/libvirt/images/win11.qcow2

DOM="${1:-win11}"
IMG="${2:-/var/lib/libvirt/images/$DOM.qcow2}"
VIRSH="virsh --connect qemu:///system"

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo."; exit 1; }
[[ -f "$IMG" ]] || { echo "No existe $IMG"; exit 1; }

estado=$($VIRSH domstate "$DOM")
if [[ "$estado" != *"shut off"* && "$estado" != *"apagado"* ]]; then
  echo "La VM '$DOM' está en estado '$estado'. Apágala desde dentro y reintenta."
  exit 1
fi

# Solo el primer campo de lsattr son los atributos; la ruta va después. Hay que
# aislarlo porque una ruta como /home/chunchoc/Compartido/x.qcow2 contiene una
# 'C' y daría un falso positivo si se buscara en la línea entera.
tiene_nocow() {
  lsattr -d "$1" 2>/dev/null | awk '{print $1}' | grep -q 'C'
}

if tiene_nocow "$IMG"; then
  echo "$IMG ya tiene nodatacow. No hay nada que hacer."
  exit 0
fi

[[ -e "$IMG.new" ]] && { echo "Ya existe $IMG.new; bórralo o revísalo antes."; exit 1; }
[[ -e "$IMG.old" ]] && { echo "Ya existe $IMG.old; parece que el script ya corrió."; exit 1; }

# A partir de aquí el .new lo creamos nosotros, así que somos responsables de
# limpiarlo si algo falla. Sin esto, un fallo a media copia deja un archivo
# inservible que además bloquea el siguiente intento. El trap se arma DESPUÉS
# de la comprobación de arriba, para no borrar nunca un .new preexistente.
COMPLETADO=""
limpiar() {
  [[ -n "$COMPLETADO" ]] && return
  if [[ -e "$IMG.new" ]]; then
    echo "Limpiando copia incompleta $IMG.new ..."
    rm -f "$IMG.new"
  fi
}
trap limpiar EXIT

# El +C tiene que aplicarse al archivo vacío, ANTES de escribir un solo byte.
touch "$IMG.new"
chattr +C "$IMG.new"
tiene_nocow "$IMG.new" || { echo "chattr +C no aplicó. ¿Es btrfs?"; exit 1; }

echo "Copiando $(du -h --apparent-size "$IMG" | cut -f1) ... (tarda varios minutos, sin salida)"
# --reflink=never es imprescindible: un reflink compartiría extents con el
# original y heredaría el CoW que precisamente queremos evitar.
cp --reflink=never --sparse=always "$IMG" "$IMG.new"

echo "Verificando la copia antes de tocar la original..."
qemu-img check "$IMG.new"

mv "$IMG" "$IMG.old"
mv "$IMG.new" "$IMG"
COMPLETADO=1          # desarma el trap: el .new ya es la imagen buena
chown root:root "$IMG"
chmod 600 "$IMG"

echo
echo "Atributos finales (debe aparecer la 'C'):"
lsattr "$IMG"
echo
echo "Listo. Arranca la VM y comprueba que todo va bien."
echo "Cuando estés seguro:  sudo rm $IMG.old"
