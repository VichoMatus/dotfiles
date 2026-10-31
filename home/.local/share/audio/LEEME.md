# Volumen de Razer BlackShark V2 Pro por USB

Regla de usuario: `~/.config/wireplumber/wireplumber.conf.d/51-razer-blackshark-volume.conf`.

Se activa `api.alsa.soft-mixer = true` solo para receptores USB Razer BlackShark V2 Pro 2.4. El volumen y silencio se aplican en software, evitando depender del mezclador de volumen USB. No se desactiva la protección de volumen de iNiR ni se cambia la configuración de los altavoces o de otros modelos.

La rueda física del audífono sigue determinando su nivel de hardware. El mezclador software permite atenuar ese nivel; no lo amplifica por encima de la capacidad física del dispositivo.

Referencia oficial: https://pipewire.pages.freedesktop.org/pipewire/page_man_pipewire-props_7.html (api.alsa.soft-mixer).

La regla requiere reiniciar WirePlumber o la sesión para aplicarse. El reinicio interrumpe brevemente el audio. Comprobar la salida y el nivel antes de reanudar la reproducción.

Prueba: `python ~/.local/share/audio/check-razer-volume.py`. Silencia temporalmente los audífonos, verifica niveles 15–30 % y la orden de subir de iNiR, y restaura volumen/silencio previos. No verifica el volumen percibido: hace falta escuchar una prueba gradual para confirmarlo.

Revertir: retirar la regla anterior y reiniciar `wireplumber.service` de usuario; comprobar de nuevo el volumen. Si el notch mantiene información anterior, reiniciar `inir.service`.
