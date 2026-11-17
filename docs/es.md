# Iniciar SSH en una consola portátil con EmuELEC

El lanzador original se probó en una XiFan XF45V V8-2 con el EmuELEC 4.7 original de 64 bits. El ordenador necesita un cliente SSH y debe estar en la misma red local que la consola.

## 1. Descargar

Descarga el **ZIP para ARM64** en [Releases → Assets](https://github.com/ohnobug/emuelec-ssh-launcher/releases/latest) y extráelo en el ordenador. Para verificarlo, compara el SHA-256 del ZIP con su valor en `SHA256SUMS`.

## 2. Configurar el acceso

El usuario es **`root`** y el puerto TCP es **`2222`**. El paquete no incluye una contraseña predefinida. Elige un método de acceso.

**Clave SSH.** Desde una carpeta privada del ordenador, ejecuta `ssh-keygen -t ed25519 -f emuelec_ed25519`. Copia `emuelec_ed25519.pub` a la carpeta extraída `ports/emuelec-ssh-launcher/` y cámbiale el nombre a `authorized_keys`, sin extensión. Guarda la clave privada `emuelec_ed25519` en el ordenador.

**Contraseña.** Abre un terminal con OpenSSL, como Git Bash o WSL, y entra en la carpeta raíz extraída. Ejecuta el comando e introduce la contraseña que quieras usar. El archivo guarda el hash. Para SSH, usa la contraseña que acabas de elegir. La contraseña del Wi-Fi y la del sistema original se gestionan por separado.

~~~sh
openssl passwd -6 > ports/emuelec-ssh-launcher/password.hash
~~~

## 3. Copiar a la tarjeta de juegos

Apaga la consola e inserta la **tarjeta de juegos** en el ordenador. Combina las carpetas extraídas `ports_scripts` y `ports` con las carpetas del mismo nombre en la raíz de la tarjeta. En la XF45V se probó una tarjeta MBR con una partición primaria FAT32 y la etiqueta `EEROMS`.

~~~text
EEROMS/
├── ports_scripts/Start-SSH.sh
└── ports/emuelec-ssh-launcher/
    ├── dropbear
    ├── dropbearkey
    ├── authorized_keys
    └── password.hash
~~~

Coloca el archivo del método elegido o los dos si quieres habilitar ambos. Expulsa la tarjeta de forma segura y vuelve a insertarla en la ranura de juegos.

## 4. Conectar al Wi-Fi e iniciar SSH

1. Enciende la consola y abre **Start → Network Settings**. Activa el Wi-Fi, selecciona el SSID e introduce la contraseña de la red. Los nombres de los menús pueden variar según el firmware.
2. Cuando aparezca la dirección IP, anótala. Conecta también el ordenador a la misma red local.
3. Vuelve a la lista de sistemas y abre **Ports → Start-SSH**. Si no aparece Ports, comprueba la estructura de la tarjeta y actualiza la lista de juegos o reinicia EmulationStation.
4. SSH escucha en el puerto TCP `2222`. El registro `ports_scripts/Start-SSH.log` muestra la IP y la huella de la clave del servidor.

## 5. Iniciar sesión desde el ordenador

Sustituye `192.168.1.42` por la IP de la consola. En la primera conexión, compara la huella que muestra SSH con la del registro.

- Con clave, desde la carpeta de la clave privada: `ssh -i ./emuelec_ed25519 -p 2222 root@192.168.1.42`.
- Con contraseña: `ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -p 2222 root@192.168.1.42`. Introduce la contraseña elegida en el paso 2.

Si se agota el tiempo de espera, comprueba el Wi-Fi y la IP. Si se rechaza la conexión, ejecuta Start-SSH y revisa el registro. Si falla la autenticación, revisa los nombres de archivo y el comando. SSH se detiene al apagar la consola. Puedes volver a iniciarlo desde Ports tras encenderla.

## 6. Compilar desde el código fuente

Instala las dependencias en Ubuntu 24.04 o WSL y ejecuta los comandos desde la raíz del repositorio. El script verifica los archivos fuente y la firma de Dropbear, compila libxcrypt, Dropbear y dropbearkey para ARM64 y deja el ZIP, las fuentes y las sumas en `dist/`. Los registros se guardan en `build/`.

~~~bash
sudo apt-get update
sudo apt-get install -y build-essential gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
    binutils-aarch64-linux-gnu ca-certificates curl gnupg file python3
bash scripts/build.sh
~~~

[Detalles de compilación y primera instalación en la XF45V](build.md)
