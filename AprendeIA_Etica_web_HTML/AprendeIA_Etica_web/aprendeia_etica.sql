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
('Fundamentos de ética en IA generativa','Conceptos básicos y buenas prácticas','Ética',20),
('Privacidad y protección de datos','Cómo evitar exponer datos sensibles','Privacidad',15),
('Citación y derechos de autor','Cómo citar contenido asistido por IA','Derechos de autor',15);

INSERT INTO lecciones (id_curso, titulo, contenido, orden, duracion_min) VALUES
(1,'¿Qué es la IA generativa?','Introducción breve a la IAG.',1,8),
(1,'Plagio y uso responsable','Cómo evitar el plagio con IA.',2,10),
(2,'Datos que nunca debes compartir','Nombres, correos y credenciales.',1,8),
(2,'Anonimizar antes de preguntar','Técnicas rápidas de anonimización.',2,7),
(3,'Cómo citar contenido de IA','Formatos de cita para contenido asistido.',1,10);

INSERT INTO normativas (titulo, resumen, palabra_clave, categoria, que_hacer, que_no_hacer) VALUES
('Uso de datos personales','Los datos personales no deben ingresarse en chats de IA sin anonimizar.','privacidad datos','Privacidad','Anonimizar nombres, correos y credenciales.','Pegar credenciales o datos reales en el chat.'),
('Citación de contenido IA','Todo contenido generado o asistido por IA debe declararse y citarse.','cita referencia','Derechos de autor','Indicar la herramienta, fecha y prompt usado.','Presentar texto de IA como propio.'),
('Verificación de resultados','Las salidas de la IA deben contrastarse con fuentes confiables.','alucinaciones sesgos','Buenas prácticas','Contrastar con al menos dos fuentes.','Aceptar la primera respuesta sin verificar.');
