# Notch

Módulo: ~/.config/quickshell/inir/modules/notch/Notch.qml.

Portada circular estática de 28 px en compacto y cuadrada con esquinas redondeadas de 94 px al expandirse, junto a controles y progreso con tiempos y búsqueda. Ondas decorativas de 8 actualizaciones por segundo, detenidas al pausar u ocultarse. Animación breve al expandir, sin giro de portada.

Medición: `python ~/.local/share/notch/measure.py`, dentro de la sesión gráfica. Alterna visible/oculto cuatro veces, deja 3 segundos de estabilización y mide 8 segundos por fase. Restaura la visibilidad y expansión originales. Requiere la instancia inir y notch-eDP-1; adaptar el nombre para otra pantalla.

CPU normalizada a un núcleo (100 % equivale a un núcleo ocupado), calculada por diferencia de ticks en /proc. RSS corresponde al proceso completo de Quickshell o Niri; ocultar el notch no descarga su memoria. Las lecturas de batería son del equipo completo, no miden vatios exclusivos del notch. Muestra corta con aplicaciones abiertas: no permite proyectar autonomía ni atribuir diferencias pequeñas de potencia al notch.

El consumo gráfico no se midió directamente; el muestreo incluye CPU de Niri, pero no trabajo de GPU.

Volumen y brillo se presentan dentro del notch durante 1,8 segundos; sliders usan los servicios existentes y conservan los límites de audio. El panel musical se cierra a los 4 segundos sin interacción. Prueba de sesión: `python ~/.local/share/notch/check-interactions.py` (no modifica niveles; abre/cierra paneles).

Barra izquierda: logo CachyOS, CPU total en porcentaje y RAM usada/total en GiB (indicada G). Reutiliza ResourceUsage con el intervalo configurado (10 segundos en esta instalación) y deja de mantenerlo activo al ocultarse. Las apps abiertas se agrupan por aplicación; cada clic activa la siguiente ventana. Si hay demasiadas, desplazar horizontalmente los iconos con la rueda. Prueba: `python ~/.local/share/notch/check-left-status.py`.
