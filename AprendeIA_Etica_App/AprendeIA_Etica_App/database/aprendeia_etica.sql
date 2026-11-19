-- =====================================================
-- AprendeIA Ética - Script físico MySQL (XAMPP / phpMyAdmin)
-- Autor: Angulo Posadas Saúl
-- =====================================================
DROP DATABASE IF EXISTS aprendeia_etica;
CREATE DATABASE aprendeia_etica CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE aprendeia_etica;

CREATE TABLE roles (
  id_rol INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(30) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE usuarios (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  id_rol INT NOT NULL DEFAULT 2,
  nombre_completo VARCHAR(100) NOT NULL,
  correo VARCHAR(120) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL COMMENT 'Hash bcrypt (RNF-01)',
  fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_usuarios_roles FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
) ENGINE=InnoDB;

CREATE TABLE perfiles_usuario (
  id_perfil INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL UNIQUE,
  biografia VARCHAR(300),
  institucion VARCHAR(100),
  CONSTRAINT fk_perfil_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE progreso_academico (
  id_progreso INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL UNIQUE,
  porcentaje_global DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  cursos_completados INT NOT NULL DEFAULT 0,
  fecha_actualizacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_progreso_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT chk_porcentaje CHECK (porcentaje_global BETWEEN 0 AND 100)
) ENGINE=InnoDB;

CREATE TABLE cursos (
  id_curso INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(120) NOT NULL,
  descripcion VARCHAR(300),
  categoria VARCHAR(50) NOT NULL,
  duracion_min SMALLINT NOT NULL DEFAULT 10
) ENGINE=InnoDB;

CREATE TABLE lecciones (
  id_leccion INT AUTO_INCREMENT PRIMARY KEY,
  id_curso INT NOT NULL,
  titulo VARCHAR(120) NOT NULL,
  contenido TEXT NOT NULL,
  orden TINYINT NOT NULL DEFAULT 1,
  duracion_min SMALLINT NOT NULL DEFAULT 10,
  CONSTRAINT fk_leccion_curso FOREIGN KEY (id_curso) REFERENCES cursos(id_curso) ON DELETE CASCADE,
  INDEX idx_leccion_curso (id_curso, orden)
) ENGINE=InnoDB;

CREATE TABLE progreso_leccion (
  id_progreso_leccion INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL,
  id_leccion INT NOT NULL,
  completada TINYINT(1) NOT NULL DEFAULT 0,
  fecha_completada DATETIME NULL,
  UNIQUE KEY uq_usuario_leccion (id_usuario, id_leccion),
  CONSTRAINT fk_pl_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_pl_leccion FOREIGN KEY (id_leccion) REFERENCES lecciones(id_leccion) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE normativas (
  id_normativa INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(150) NOT NULL,
  resumen VARCHAR(500) NOT NULL,
  palabra_clave VARCHAR(100) NOT NULL,
  categoria VARCHAR(50) NOT NULL,
  que_hacer VARCHAR(400),
  que_no_hacer VARCHAR(400),
  FULLTEXT KEY ft_normativa (titulo, resumen, palabra_clave)  -- búsqueda < 2 s (RNF-02)
) ENGINE=InnoDB;

CREATE TABLE consultas_normativa (
  id_consulta INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL,
  id_normativa INT NOT NULL,
  fecha_consulta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cons_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_cons_normativa FOREIGN KEY (id_normativa) REFERENCES normativas(id_normativa) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Datos iniciales ----------
INSERT INTO roles (nombre) VALUES ('Administrador'), ('Usuario');

INSERT INTO cursos (titulo, descripcion, categoria, duracion_min) VALUES
('Fundamentos de ética en IA generativa','Qué es la IA generativa, sus riesgos y cómo usarla con responsabilidad.','Ética',25),
('Privacidad y protección de datos','Qué datos nunca compartir con una IA y cómo anonimizar antes de preguntar.','Privacidad',20),
('Citación y derechos de autor','Cómo declarar y citar el contenido generado o asistido por IA.','Derechos de autor',20);

INSERT INTO lecciones (id_curso, titulo, contenido, orden, duracion_min) VALUES
(1,'¿Qué es la IA generativa?','La inteligencia artificial generativa (IAG) produce texto, imágenes, código u otro contenido a partir de las instrucciones que le das. Herramientas como ChatGPT, Gemini o Claude son ejemplos.

Una IAG no entiende el mundo como una persona: predice la respuesta más probable según los datos con los que fue entrenada. Por eso puede sonar muy segura y aun así equivocarse.

Idea clave: la IA es una herramienta de apoyo. La responsabilidad sobre lo que entregas, publicas o decides sigue siendo tuya.',1,8),
(1,'Plagio y uso responsable','Presentar como propio un texto generado por una IA, sin declararlo, es una forma de plagio. También lo es copiar fragmentos de otras obras que la IA reproduce sin que lo notes.

Buenas prácticas:
- Declara cuándo usaste IA y para qué (apoyo, borrador, corrección, ideas).
- Reescribe con tus palabras y agrega tu propio análisis.
- Contrasta los datos con fuentes confiables antes de usarlos.

Revisa siempre las reglas de tu institución o empresa: algunas permiten la IA solo para ciertas tareas.',2,9),
(1,'Verifica antes de confiar','Las IAG pueden generar alucinaciones: datos, citas o fuentes inventadas que parecen reales. También pueden reproducir sesgos presentes en sus datos de entrenamiento.

Antes de usar una respuesta:
- Contrasta los datos importantes con al menos dos fuentes confiables.
- Comprueba que las citas y los enlaces existan realmente.
- Pregúntate si la respuesta trata de forma justa a todas las personas mencionadas.

No aceptes la primera salida generada sin revisarla.',3,8),
(2,'Datos que nunca debes compartir','Todo lo que escribes en un chat de IA puede almacenarse o usarse según las políticas de la plataforma. Por eso no debes pegar:
- Nombres reales, correos, teléfonos o direcciones de otras personas.
- Contraseñas, claves de acceso o credenciales, incluso de prueba.
- Información confidencial de tu escuela o empresa.
- Datos de salud, financieros o documentos oficiales.

Si necesitas ayuda con un texto que contiene datos personales, anonimízalo primero.',1,8),
(2,'Anonimizar antes de preguntar','Anonimizar significa reemplazar los datos reales por datos ficticios que conserven el sentido del texto.

Ejemplo: en lugar de "Juan Pérez, juan@correo.com, contraseña 1234", escribe "Persona A, correo@ejemplo.com, [CONTRASEÑA]".

Pasos rápidos:
1. Reemplaza nombres por etiquetas (Persona A, Empresa X).
2. Sustituye correos y teléfonos por valores de ejemplo.
3. Elimina cualquier credencial.
4. Relee el texto completo antes de enviarlo.',2,7),
(2,'Lee la política de privacidad','Las plataformas de IA explican en su política de privacidad qué datos guardan y si los usan para entrenar sus modelos. Muchas personas nunca la leen.

Busca estos puntos:
- Si tus conversaciones se guardan y por cuánto tiempo.
- Si se usan para entrenar el modelo y cómo desactivarlo.
- Cómo pedir que se eliminen tus datos.

Una lectura rápida de estos tres puntos ya reduce mucho el riesgo.',3,5),
(3,'Cómo citar contenido de IA','Cuando uses contenido generado o asistido por IA en un trabajo, debes declararlo. Una cita básica incluye:
- Nombre de la herramienta y versión o modelo.
- Empresa que la desarrolla.
- Fecha en que generaste el contenido.
- La instrucción (prompt) que usaste.

Los formatos como APA, MLA o Chicago ya incluyen recomendaciones para citar IA. Consulta el formato que pide tu institución.',1,10),
(3,'Derechos de autor y obras generadas','Las leyes sobre quién es el autor de un contenido generado por IA aún están en discusión y cambian según el país. Por eso conviene actuar con prudencia.

- No asumas que lo generado es libre de derechos.
- No pidas a la IA copiar el estilo exacto o el texto de una obra protegida.
- Si publicas el resultado, revisa los términos de uso de la herramienta.

Ante la duda, cita, declara el uso de IA y consulta las reglas de tu institución.',2,10);

INSERT INTO normativas (titulo, resumen, palabra_clave, categoria, que_hacer, que_no_hacer) VALUES
('Uso de datos personales','Los datos personales no deben ingresarse en chats de IA sin anonimizar. Todo lo que escribes puede ser almacenado por la plataforma.','privacidad datos personales anonimizar','Privacidad','Anonimizar nombres, correos y teléfonos antes de preguntar. Revisar la política de privacidad de la herramienta.','Pegar credenciales, contraseñas o datos reales de otras personas en el chat.'),
('Información confidencial de la institución','La información interna de tu escuela o empresa es confidencial y no debe compartirse con herramientas públicas de IA.','confidencial empresa institución secreto','Privacidad','Usar ejemplos ficticios. Consultar la política interna sobre uso de IA.','Subir documentos internos, contratos o bases de datos a una IA pública.'),
('Citación de contenido IA','Todo contenido generado o asistido por IA debe declararse y citarse según el formato que exija tu institución.','cita referencia apa autoría declarar','Derechos de autor','Indicar la herramienta, la fecha y la instrucción usada. Agregar tu propio análisis.','Presentar texto de IA como si fuera totalmente propio.'),
('Plagio y originalidad','Entregar un trabajo hecho totalmente con IA sin declararlo es plagio y compromete tu integridad académica o profesional.','plagio originalidad integridad copia','Buenas prácticas','Usar la IA como apoyo y reescribir con tus palabras. Declarar el apoyo recibido.','Entregar un trabajo completo generado por IA sin revisarlo ni declararlo.'),
('Verificación de resultados','Las salidas de la IA pueden contener errores, datos inventados (alucinaciones) y sesgos. Siempre deben contrastarse.','alucinaciones sesgos verificar fuentes','Buenas prácticas','Contrastar con al menos dos fuentes confiables. Comprobar que las citas existan.','Aceptar la primera respuesta sin verificarla ni revisar sus fuentes.'),
('Derechos de autor y obras protegidas','El estatus legal de lo generado por IA varía según el país. No uses la IA para copiar obras protegidas.','derechos autor copyright licencia obras','Derechos de autor','Revisar los términos de uso de la herramienta. Citar las fuentes que uses.','Pedir a la IA reproducir un texto protegido o imitar una obra de forma exacta.');
