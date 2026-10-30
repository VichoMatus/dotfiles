# Restaurar la configuración

Estos pasos se ejecutan desde la raíz del repositorio. Primero instalar y comprobar **iNiR 2.33.0**. Si la versión es distinta, comparar los tres archivos de integración QML y GlobalStates.qml antes de copiarlos; no sobrescribir una versión nueva a ciegas.

## 1. Crear un respaldo previo

Salir de modo Tele si estaba activo: `modo-tele off`. Tener una terminal abierta para completar la restauración si el escritorio deja de mostrarse.

```bash
backup_dir="$HOME/.local/state/dotfiles-backups/antes-de-restaurar-$(date +%Y%m%d-%H%M%S)"
mkdir -p -m 700 "$backup_dir"
systemctl --user stop inir.service
tar -czf "$backup_dir/configuracion.tar.gz" -C "$HOME" .config/niri .config/inir .config/quickshell/inir .config/systemd/user .config/autostart .local/bin
chmod 600 "$backup_dir/configuracion.tar.gz"
```

Si el respaldo falla, resolverlo antes de continuar. No publicarlo: puede contener datos personales.

## 2. Copiar y fusionar

```bash
cp -a home/. "$HOME/"
python3 - <<'PY'
import json
from pathlib import Path
path = Path.home() / '.config/inir/config.json'
current = json.loads(path.read_text())
overrides = json.loads(Path('inir-overrides.json').read_text())
def merge(target, source):
    for key, value in source.items():
        if isinstance(value, dict):
            if not isinstance(target.get(key), dict):
                target[key] = {}
            merge(target[key], value)
        else:
            target[key] = value
merge(current, overrides)
temporary = path.with_suffix('.json.restore-tmp')
temporary.write_text(json.dumps(current, ensure_ascii=False, indent=4) + '\n')
temporary.replace(path)
PY
niri validate
```

La fusión conserva campos personales que no se incluyeron en el respaldo público. Revisar la distribución de teclado, pantallas y rutas personales de Niri si se restaura en otro equipo. Los overrides de autostart ocultan Blueman y LocalSearch; pueden afectar esas funciones hasta retirarlos.

## 3. Iniciar

Solo continuar si `niri validate` termina correctamente.

```bash
systemctl --user daemon-reload
systemctl --user enable --now power-profile-auto.service
systemctl --user start inir.service
```

Cerrar y abrir sesión para que se apliquen todos los cambios de inicio. Verificar volumen, brillo, bloqueo, pantalla completa, modo Tele y conectar/desconectar el cargador.

El límite de carga del 80 % queda configurado en iNiR; su aplicación al hardware puede solicitar autorización. El gobernador/ventilador y los servicios del sistema no se reemplazan.

## Recuperación

Si iNiR falla, desde una terminal o TTY:

```bash
systemctl --user stop inir.service
systemctl --user disable --now power-profile-auto.service
tar -xzf /RUTA/AL/RESPALDO/configuracion.tar.gz -C "$HOME"
systemctl --user daemon-reload
systemctl --user start inir.service
```

Retirar los archivos nuevos que no existían antes si siguen activos: el servicio `power-profile-auto.service`, los overrides de autostart y los lanzadores del modo Tele. Extraer un tar restaura archivos anteriores, pero no elimina archivos añadidos después. El módulo Notch.qml puede permanecer sin uso si se restauraron los cargadores originales.
