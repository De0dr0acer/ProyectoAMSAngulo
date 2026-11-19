# AprendeIA Ética

Plataforma web para el aprendizaje ético y seguro de la IA generativa.
Autor: Angulo Posadas Saúl.

## Contenido

```
AprendeIA_Etica_App/
├── app.py                    Servidor Flask (API + sesiones + bcrypt)
├── requirements.txt          Dependencias de Python
├── database/
│   └── aprendeia_etica.sql   Esquema MySQL y datos iniciales (3 cursos, 8 lecciones, 6 normas)
├── static/
│   ├── index.html            Todas las páginas fusionadas en una sola aplicación
│   ├── css/app.css           Estilos (responsivo para escritorio y móvil)
│   └── js/app.js             Vistas y llamadas a la API
└── tests/                    Pruebas automáticas (usan SQLite, no necesitan XAMPP)
```

## Cómo ejecutarlo con XAMPP

1. Abre el panel de XAMPP e inicia **MySQL** (Apache no es necesario).
2. Abre http://localhost/phpmyadmin, elige la pestaña **Importar** y carga `database/aprendeia_etica.sql`.
   Atención: el script empieza con `DROP DATABASE IF EXISTS aprendeia_etica`, así que borra y recrea la base.
3. En una terminal, dentro de esta carpeta:
   ```
   pip install -r requirements.txt
   python app.py
   ```
4. Abre http://127.0.0.1:5000 y crea tu cuenta.

Si tu MySQL tiene contraseña para `root`, define las variables de entorno antes de iniciar:
`DB_PASSWORD`, y opcionalmente `DB_HOST`, `DB_USER` y `DB_NAME`.

## Pantallas

| Vista | Ruta | Requiere sesión |
|---|---|---|
| Inicio | `/#/` | No |
| Iniciar sesión / Registro | `/#/login`, `/#/registro` | No |
| Normatividad y guía rápida (Sí / No hacer) | `/#/normatividad` | No |
| Dashboard | `/#/dashboard` | Sí |
| Cursos, curso y lección | `/#/cursos`, `/#/curso/1`, `/#/leccion/1` | Sí |
| Mi progreso | `/#/progreso` | Sí |
| Mi perfil | `/#/perfil` | Sí |

Las rutas antiguas `/login`, `/registro`, `/dashboard` y `/perfil` siguen funcionando y redirigen a la vista correspondiente.

## API

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/registro` | Crea usuario, perfil y progreso; inicia sesión |
| POST | `/api/login` | Inicia sesión |
| POST | `/api/logout` | Cierra sesión |
| GET | `/api/me` | Usuario actual y estadísticas |
| PUT | `/api/perfil` | Actualiza nombre, institución, biografía y, si se envía, la contraseña |
| GET | `/api/cursos`, `/api/cursos/<id>` | Cursos y lecciones con el avance del usuario |
| GET | `/api/lecciones/<id>` | Contenido de una lección |
| POST | `/api/lecciones/<id>/completar` | Marca o desmarca una lección y recalcula el avance global |
| GET | `/api/siguiente-leccion` | Primera lección pendiente |
| GET | `/api/normativas?q=&categoria=` | Búsqueda de normas (pública) |
| GET | `/api/normativas/<id>` | Detalle de una norma; registra la consulta si hay sesión |

## Seguridad

- Contraseñas con hash bcrypt (RNF-01). Para HTTPS, define `APRENDEIA_HTTPS=1`.
- Antes de publicar, define `APRENDEIA_SECRET` con un valor largo y aleatorio.
- Consultas SQL parametrizadas y texto insertado en la página sin HTML (contra inyección SQL y XSS).
- `APRENDEIA_DEBUG=1` activa el modo depuración; por defecto está apagado y el servidor solo escucha en 127.0.0.1.

## Pruebas

```
cd tests
python test_api.py     # 29 comprobaciones de la API
python test_ui.py      # recorrido completo en navegador (requiere: pip install playwright && playwright install chromium)
```
