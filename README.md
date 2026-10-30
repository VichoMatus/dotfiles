# CachyOS + Niri — dotfiles de VichoMatus

Respaldo de la configuración personal, basada en [iNiR](https://github.com/snowarch/iNiR).

- Notch negro con hora, portada estática, controles musicales, progreso con búsqueda y tiempos transcurrido/restante.
- Notificaciones, volumen y brillo integrados; cierre automático, atenuación y desplazamiento del contenido.
- Notch oculto al bloquear, en pantalla completa y durante modo Tele.
- Modo Tele reversible: ahorro de energía y menos trabajo de escritorio.
- Rendimiento con cargador y balanceado en batería; Tele tiene prioridad y usa ahorro.
- Ajustes de Niri, inactividad y widgets.

Base: **iNiR 2.33.0, commit `48cdcecb`**, CachyOS, ASUS Zenbook 14 UM3406GA. Este repositorio es una capa de personalización; requiere iNiR instalado.

## Contenido

- `home/`: archivos que corresponden a rutas bajo la carpeta personal.
- `inir-overrides.json`: ajustes seleccionados para fusionar con el JSON de iNiR.
- [Restauración](RESTORE.md): pasos, precauciones de versión y recuperación.
- [Diagnóstico inicial](diagnostico/2026-10-30.md).
- `SHA256SUMS.json`: sumas para comprobar integridad.

No contiene el JSON completo de iNiR, credenciales, fuentes de calendarios, historiales, carátulas ni fondos personales. El respaldo completo con datos locales se conserva aparte, fuera de Git.

Los archivos QML de integración reemplazan archivos de iNiR: las actualizaciones del proyecto base pueden sobrescribirlos. Compararlos antes de actualizar o restaurar sobre otra versión. Las protecciones visuales del notch no garantizan evitar desgaste OLED.

## Uso

Buscar **Modo Tele** en el lanzador o ejecutar `modo-tele on`, `modo-tele off`, `modo-tele status`.

Comprobar energía: `systemctl --user status power-profile-auto.service`.

Los scripts requieren las herramientas ya presentes en este sistema: Python con PyGObject/Gio, systemd de usuario, powerprofilesctl, Niri, Quickshell e iNiR. No se instalan paquetes automáticamente.

Código de iNiR y personalizaciones distribuidos bajo GPL-3.0; ver LICENSE y NOTICE.
