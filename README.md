# StreamLab · Irving Jesús Montes López

Plataforma de streaming de la práctica del Tecnológico de Colima. Basada en el Anexo B del manual proporcionado por el docente, con ajustes de validación, sesiones, copiado sobre HTTP y reconexión del reproductor.

## Inicio rápido en Windows (Git Bash)

1. Extrae el ZIP. Abre la carpeta `streamlab` que contiene `package.json`.
2. Abre Git Bash dentro de esa carpeta.
3. Ejecuta:

```bash
bash scripts/configurar-local.sh
npm start
```

4. Abre **http://localhost:3000**. Regístrate y entra en **Mi canal**.
5. Configura OBS con el servidor y la clave que muestra tu panel.

Lee **GUIA_PASO_A_PASO.md** para GitHub, AWS, capturas y reporte.

## Requisitos

- Node.js 22.13 o superior; para seguir el manual, usa la rama 22 LTS.
- Git Bash, ffmpeg, OBS Studio y AWS CLI v2.
- Cuentas propias de GitHub y AWS para el despliegue.
- Una VPC y subred predeterminadas en la región seleccionada para `aws.sh`.

## Funciones

Registro y sesiones de siete días; canales; seis categorías; transmisión RTMP validada con clave privada; reproducción HLS; chat por canal con límite de mensajes; espectadores; seguidores; grabación MP4 y miniaturas.

## Archivos principales

| Archivo | Función |
|---|---|
| SPEC.md | Requisitos del manual |
| server.js | API, autenticación, Socket.io, RTMP y conversión a HLS |
| db.js | Tablas SQLite |
| public/ | Interfaz en español |
| .env.example | Configuración de ejemplo |
| scripts/configurar-local.sh | Detecta ffmpeg y prepara Windows o Linux |
| deploy/setup-ec2.sh | Instala Node, ffmpeg y PM2 en Ubuntu 24.04 |
| aws.sh | Crea, consulta, conecta y elimina el despliegue registrado |
| scripts/test.cjs | Pruebas aisladas de API, chat y video real de prueba |
| scripts/latencia.py | Media, desviación estándar y estimación de transferencia |
| REPORTE_BASE.md | Borrador para completar con tus resultados reales |
| EVIDENCIAS.md | Capturas y datos que faltan obtener |

## Pruebas

```bash
npm ci
npm test
```

Se necesita ffmpeg instalado. Las pruebas usan una carpeta temporal independiente y los puertos 3910, 1936 y 8001. En Windows puede ser necesario habilitar el modo de desarrollador para crear enlaces de directorios. `npm test` no modifica las cuentas de la aplicación principal.

Ver **VALIDACION_LOCAL.md** para el alcance de las pruebas realizadas. No se ha desplegado este paquete en una cuenta AWS ni se ha probado OBS en tu computadora.

## Configuración

- `PORT`: web; 3000 en local, 80 en AWS.
- `RTMP_PORT`: 1935.
- `PUBLIC_HOST`: vacío para detectar el host de acceso.
- `FFMPEG_PATH`: ruta absoluta al ejecutable. El configurador local la detecta.
- `RECORD_VOD`: true o false.
- `HLS_TIME`: 1, 2 o 4 segundos; reinicia el servidor después de cambiarlo.
- `NMS_HTTP_PORT`: 8000 por defecto. No abras este puerto ni el 3000 en el grupo de seguridad de AWS. El sitio público se sirve por el 80.

No se incluyen usuarios, contraseñas, base de datos, grabaciones ni llaves SSH. Se generan al usar la aplicación. `.gitignore` evita subir esos archivos a GitHub. Sigue siendo una práctica sobre HTTP; para uso con cuentas reales, agrega HTTPS.

## Fuentes

- Manual_StreamLab_Streaming_AWS (1).pdf, proporcionado por el docente. El Anexo B es la base del código.
- Node.js, SQLite: https://nodejs.org/api/sqlite.html
- AWS CLI, EC2: https://docs.aws.amazon.com/cli/latest/reference/ec2/run-instances.html
- AWS CLI, grupos de seguridad: https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-sg.html
- Tarifas EC2 y transferencia: https://aws.amazon.com/ec2/pricing/on-demand/
- Tarifas IPv4: https://aws.amazon.com/vpc/pricing/

Los precios de AWS y los créditos se deben comprobar en la cuenta y región antes de desplegar. Una estimación no es la factura final.
