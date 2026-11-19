"""Capa de prueba: reemplaza MySQL por SQLite para verificar la lógica del servidor sin XAMPP."""
import os, re, sqlite3, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
DB = '/tmp/aprendeia_test.db'
DDL = """
CREATE TABLE roles (id_rol INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL UNIQUE);
CREATE TABLE usuarios (id_usuario INTEGER PRIMARY KEY AUTOINCREMENT, id_rol INT NOT NULL DEFAULT 2, nombre_completo TEXT NOT NULL,
 correo TEXT NOT NULL UNIQUE, contrasena_hash TEXT NOT NULL, fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, activo INT NOT NULL DEFAULT 1);
CREATE TABLE perfiles_usuario (id_perfil INTEGER PRIMARY KEY AUTOINCREMENT, id_usuario INT NOT NULL UNIQUE, biografia TEXT, institucion TEXT);
CREATE TABLE progreso_academico (id_progreso INTEGER PRIMARY KEY AUTOINCREMENT, id_usuario INT NOT NULL UNIQUE, porcentaje_global REAL NOT NULL DEFAULT 0, cursos_completados INT NOT NULL DEFAULT 0, fecha_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE cursos (id_curso INTEGER PRIMARY KEY AUTOINCREMENT, titulo TEXT NOT NULL, descripcion TEXT, categoria TEXT NOT NULL, duracion_min INT NOT NULL DEFAULT 10);
CREATE TABLE lecciones (id_leccion INTEGER PRIMARY KEY AUTOINCREMENT, id_curso INT NOT NULL, titulo TEXT NOT NULL, contenido TEXT NOT NULL, orden INT NOT NULL DEFAULT 1, duracion_min INT NOT NULL DEFAULT 10);
CREATE TABLE progreso_leccion (id_progreso_leccion INTEGER PRIMARY KEY AUTOINCREMENT, id_usuario INT NOT NULL, id_leccion INT NOT NULL, completada INT NOT NULL DEFAULT 0, fecha_completada TEXT, UNIQUE(id_usuario,id_leccion));
CREATE TABLE normativas (id_normativa INTEGER PRIMARY KEY AUTOINCREMENT, titulo TEXT NOT NULL, resumen TEXT NOT NULL, palabra_clave TEXT NOT NULL, categoria TEXT NOT NULL, que_hacer TEXT, que_no_hacer TEXT);
CREATE TABLE consultas_normativa (id_consulta INTEGER PRIMARY KEY AUTOINCREMENT, id_usuario INT NOT NULL, id_normativa INT NOT NULL, fecha_consulta TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
"""
def reset():
    if os.path.exists(DB): os.remove(DB)
    c = sqlite3.connect(DB); c.executescript(DDL)
    sql = open(os.path.join(os.path.dirname(__file__), '..', 'database', 'aprendeia_etica.sql'), encoding='utf-8').read()
    c.executescript(sql[sql.index('-- ---------- Datos iniciales'):]); c.commit(); c.close()
class Cur:
    def __init__(s, c, d): s.c = c.cursor(); s.d = d
    def execute(s, sql, p=()): s.c.execute(sql.replace('%s', '?'), tuple(p)); return s
    @property
    def lastrowid(s): return s.c.lastrowid
    def _r(s, r): return (dict(r) if s.d else tuple(r)) if r is not None else None
    def fetchone(s): return s._r(s.c.fetchone())
    def fetchall(s): return [s._r(r) for r in s.c.fetchall()]
    def close(s): s.c.close()
class Conn:
    def __init__(s): s.c = sqlite3.connect(DB); s.c.row_factory = sqlite3.Row; s.c.execute('PRAGMA foreign_keys=ON')
    def cursor(s, dictionary=False): return Cur(s.c, dictionary)
    def commit(s): s.c.commit()
    def close(s): s.c.close()
import app as A
A.get_db = lambda: Conn()
