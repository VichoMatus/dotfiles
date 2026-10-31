# Audio USB — Razer BlackShark V2 Pro

Estado: control de hardware original de PipeWire, sin reglas especiales de WirePlumber para estos audífonos.

Se probó api.alsa.soft-mixer el 31 de octubre de 2026 y se revirtió: el mezclador físico PCM quedó silenciado mientras el control software aparecía activo. El usuario confirmó que el sonido volvió al retirar la regla, reactivar el mezclador físico y restaurar su volumen anterior.

No restaurar la antigua regla 51-razer-blackshark-volume.conf ni la prueba check-razer-volume.py. Fueron retiradas del repositorio. La copia de diagnóstico está fuera de los directorios de configuración, en el respaldo local audio-usb-20261031-122614.

El comportamiento reportado de poca variación audible por encima del 20 % sigue pendiente de diagnosticar. Una lectura correcta de porcentaje no demuestra un cambio audible. No dar este problema por resuelto ni aplicar otro cambio de mezclador sin comprobar el resultado auditivo.
