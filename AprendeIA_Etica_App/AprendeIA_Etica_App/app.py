import sqlite3
import os
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory

# Rutas exactas según tu estructura de carpetas
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
WEB_DIR = os.path.join(BASE_DIR, "static")
DB_DIR = os.path.join(BASE_DIR, "database")
os.makedirs(DB_DIR, exist_ok=True)
DB_PATH = os.path.join(DB_DIR, "etia_interactiva.db")

app = Flask(__name__, static_folder=WEB_DIR, static_url_path="")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()
    cursor.executescript("""
        CREATE TABLE IF NOT EXISTS usuarios (
            id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            progreso_general REAL DEFAULT 0.0
        );

        CREATE TABLE IF NOT EXISTS evaluaciones (
            id_evaluacion INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER NOT NULL,
            id_modulo INTEGER NOT NULL,
            calificacion REAL NOT NULL,
            aprobado INTEGER NOT NULL,
            FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS certificados (
            id_certificado INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER UNIQUE NOT NULL,
            folio_unico TEXT UNIQUE NOT NULL,
            fecha_emision TEXT NOT NULL,
            FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
        );
    """)
    conn.commit()
    conn.close()

@app.route("/")
def index():
    return send_from_directory(WEB_DIR, "index.html")

@app.route("/favicon.ico")
def favicon():
    return "", 204

@app.route("/<path:filename>")
def static_files(filename):
    return send_from_directory(WEB_DIR, filename)

# 1. API: Registro de Usuario en SQLite (RF-01)
@app.route("/api/registro", methods=["POST"])
def registro():
    data = request.json
    nombre = data.get("nombre")
    email = data.get("email")
    password = data.get("password")

    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO usuarios (nombre, email, password, progreso_general) VALUES (?, ?, ?, 0.0)",
            (nombre, email, password)
        )
        conn.commit()
        user_id = cursor.lastrowid
        conn.close()
        return jsonify({
            "ok": True,
            "usuario": {
                "id_usuario": user_id,
                "nombre": nombre,
                "email": email,
                "progreso_general": 0,
                "modulosCompletados": [],
                "examenAprobado": False
            }
        })
    except sqlite3.IntegrityError:
        return jsonify({"ok": False, "mensaje": "Este correo ya está registrado."}), 400

# 2. API: Inicio de Sesión validando contra SQLite (RF-01)
@app.route("/api/login", methods=["POST"])
def login():
    data = request.json
    email = data.get("email")
    password = data.get("password")

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM usuarios WHERE email = ? AND password = ?", (email, password))
    user = cursor.fetchone()

    if not user:
        conn.close()
        return jsonify({"ok": False, "mensaje": "Correo o contraseña incorrectos. Regístrate si no tienes cuenta."}), 401

    cursor.execute("SELECT id_modulo FROM evaluaciones WHERE id_usuario = ? AND aprobado = 1", (user["id_usuario"],))
    aprobados = [row["id_modulo"] for row in cursor.fetchall()]
    conn.close()

    return jsonify({
        "ok": True,
        "usuario": {
            "id_usuario": user["id_usuario"],
            "nombre": user["nombre"],
            "email": user["email"],
            "progreso_general": user["progreso_general"],
            "modulosCompletados": aprobados,
            "examenAprobado": (4 in aprobados)
        }
    })

# 3. API: Guardar avance de módulo, examen y certificado en SQLite (RF-07, RF-08)
@app.route("/api/progreso", methods=["POST"])
def guardar_progreso():
    data = request.json
    id_usuario = data.get("id_usuario")
    id_modulo = data.get("id_modulo")
    calificacion = data.get("calificacion", 100.0)
    progreso_total = data.get("progreso_general")

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT id_evaluacion FROM evaluaciones WHERE id_usuario = ? AND id_modulo = ? AND aprobado = 1", (id_usuario, id_modulo))
    if not cursor.fetchone():
        cursor.execute(
            "INSERT INTO evaluaciones (id_usuario, id_modulo, calificacion, aprobado) VALUES (?, ?, ?, 1)",
            (id_usuario, id_modulo, calificacion)
        )

    cursor.execute("UPDATE usuarios SET progreso_general = ? WHERE id_usuario = ?", (progreso_total, id_usuario))

    if progreso_total >= 100:
        cursor.execute("SELECT id_certificado FROM certificados WHERE id_usuario = ?", (id_usuario,))
        if not cursor.fetchone():
            folio = f"ETIA-2026-UACM-{id_usuario:03d}"
            fecha = datetime.now().strftime("%Y-%m-%d")
            cursor.execute(
                "INSERT INTO certificados (id_usuario, folio_unico, fecha_emision) VALUES (?, ?, ?)",
                (id_usuario, folio, fecha)
            )

    conn.commit()
    conn.close()
    return jsonify({"ok": True})

if __name__ == "__main__":
    init_db()
    print(" Servidor ETIA_interactiva activo en: http://127.0.0.1:5000")
    app.run(debug=True, port=5000)