# Modo Tele

Desde el lanzador: buscar **Modo Tele**. Cada ejecución alterna entre Tele y normal.

Terminal: `modo-tele on`, `modo-tele off`, `modo-tele status`.

Tele selecciona power-saver incluso con cargador; desactiva animaciones de Niri/iNiR, widgets de escritorio, clima, estadísticas de la barra, sincronización de calendarios y comprobaciones de actualizaciones de iNiR. Detiene LocalSearch y el applet Blueman solo si estaban activos. Mantiene Bluetooth, red, audio, Docker y aplicaciones abiertas.

Mientras está activo, la pantalla no se apaga ni se bloquea o suspende por inactividad. El bloqueo antes de una suspensión manual sigue configurado. Al terminar, desactivar Tele para recuperar los tiempos normales y evitar gastar batería con la pantalla encendida.

Al salir restaura los campos modificados y el archivo de animaciones anterior; regresa a rendimiento con cargador o balanceado en batería. No editar esos mismos ajustes ni actualizar iNiR mientras Tele esté activo. El estado persiste tras reiniciar hasta desactivar Tele.

Recuperación: `modo-tele off`. Estado de restauración: `~/.local/state/modo-tele/restore.json`; última restauración: `last-restore.json`. Estos archivos son locales; pueden contener datos personales, no publicarlos sin revisión.

Pruebas: `python ~/.local/share/modo-tele/test_modo_tele.py`.

Para video, probar Firefox con un perfil dedicado y verificar decodificación por hardware en about:support durante una reproducción. No hay un navegador de menor consumo demostrado para este equipo. Para archivos o enlaces compatibles: `mpv --hwdec=auto-safe "archivo-o-url"`; comprobar que el video concreto usa hardware. No todos los sitios, códecs o servicios DRM funcionan en mpv. No se han medido diferencias de autonomía entre reproductores.
