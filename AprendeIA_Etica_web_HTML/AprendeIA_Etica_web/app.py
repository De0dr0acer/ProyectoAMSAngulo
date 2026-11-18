#!/usr/bin/env python3
"""
AprendeIA Ética - Servidor Flask
Registro e inicio de sesión con MySQL + bcrypt
Autor: basado en el esquema de Angulo Posadas Saúl
"""

from flask import Flask, request, jsonify, redirect, send_from_directory, session
import mysql.connector
from mysql.connector import Error
import bcrypt
import os
from functools import wraps

app = Flask(__name__, static_folder=None)
app.secret_key = "aprendeia-etica-clave-secreta-cambiar-en-produccion-2026"

# ---------- Configuración de la base de datos (XAMPP) ----------
DB_CONFIG = {
    "host": "127.0.0.1",
    "user": "root",
    "password": "",          # en XAMPP normalmente va vacío
    "database": "aprendeia_etica",
    "charset": "utf8mb4",
    "collation": "utf8mb4_unicode_ci",
}

# Carpeta donde están los HTML (misma carpeta del app.py)
STATIC_DIR = os.path.dirname(os.path.abspath(__file__))


def get_db():
    return mysql.connector.connect(**DB_CONFIG)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def check_password(password: str, password_hash: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))


def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if "id_usuario" not in session:
            return redirect("/login")
        return f(*args, **kwargs)
    return decorated


# ---------- Páginas ----------
@app.route("/")
def index():
    return send_from_directory(STATIC_DIR, "01_inicio.html")


@app.route("/login")
def login_page():
    return send_from_directory(STATIC_DIR, "02_login.html")


@app.route("/registro")
def registro_page():
    return send_from_directory(STATIC_DIR, "03_registro.html")


@app.route("/dashboard")
@login_required
def dashboard():
    return send_from_directory(STATIC_DIR, "04_dashboard.html")


@app.route("/perfil")
@login_required
def perfil():
    return send_from_directory(STATIC_DIR, "05_perfil.html")


# ---------- API: Registro ----------
@app.route("/api/registro", methods=["POST"])
def api_registro():
    data = request.get_json(silent=True) or request.form

    nombre = (data.get("nombre_completo") or data.get("nombre") or "").strip()
    correo = (data.get("correo") or data.get("email") or "").strip().lower()
    contrasena = data.get("contrasena") or data.get("password") or ""
    confirmar = data.get("confirmar_contrasena") or data.get("confirm_password") or contrasena

    if not nombre or not correo or not contrasena:
        return jsonify({"ok": False, "mensaje": "Nombre, correo y contraseña son obligatorios."}), 400
    if len(contrasena) < 6:
        return jsonify({"ok": False, "mensaje": "La contraseña debe tener al menos 6 caracteres."}), 400
    if contrasena != confirmar:
        return jsonify({"ok": False, "mensaje": "Las contraseñas no coinciden."}), 400
    if "@" not in correo:
        return jsonify({"ok": False, "mensaje": "Correo electrónico no válido."}), 400

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id_usuario FROM usuarios WHERE correo = %s", (correo,))
        if cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"ok": False, "mensaje": "Ese correo ya está registrado."}), 409

        hash_pw = hash_password(contrasena)
        cursor.execute(
            "INSERT INTO usuarios (id_rol, nombre_completo, correo, contrasena_hash) VALUES (2, %s, %s, %s)",
            (nombre, correo, hash_pw),
        )
        id_usuario = cursor.lastrowid

        cursor.execute(
            "INSERT INTO perfiles_usuario (id_usuario, biografia, institucion) VALUES (%s, %s, %s)",
            (id_usuario, "", ""),
        )
        cursor.execute(
            "INSERT INTO progreso_academico (id_usuario, porcentaje_global, cursos_completados) VALUES (%s, 0.00, 0)",
            (id_usuario,),
        )

        conn.commit()
        cursor.close()
        conn.close()

        session["id_usuario"] = id_usuario
        session["nombre"] = nombre
        session["correo"] = correo

        return jsonify({
            "ok": True,
            "mensaje": "Cuenta creada correctamente.",
            "usuario": {"id": id_usuario, "nombre": nombre, "correo": correo},
            "redirect": "/dashboard",
        }), 201

    except Error as e:
        return jsonify({"ok": False, "mensaje": f"Error de base de datos: {str(e)}"}), 500


# ---------- API: Login ----------
@app.route("/api/login", methods=["POST"])
def api_login():
    data = request.get_json(silent=True) or request.form

    correo = (data.get("correo") or data.get("email") or "").strip().lower()
    contrasena = data.get("contrasena") or data.get("password") or ""

    if not correo or not contrasena:
        return jsonify({"ok": False, "mensaje": "Correo y contraseña son obligatorios."}), 400

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)

        cursor.execute(
            "SELECT id_usuario, nombre_completo, correo, contrasena_hash, activo FROM usuarios WHERE correo = %s",
            (correo,),
        )
        usuario = cursor.fetchone()
        cursor.close()
        conn.close()

        if not usuario:
            return jsonify({"ok": False, "mensaje": "Correo o contraseña incorrectos."}), 401
        if not usuario["activo"]:
            return jsonify({"ok": False, "mensaje": "Esta cuenta está desactivada."}), 403
        if not check_password(contrasena, usuario["contrasena_hash"]):
            return jsonify({"ok": False, "mensaje": "Correo o contraseña incorrectos."}), 401

        session["id_usuario"] = usuario["id_usuario"]
        session["nombre"] = usuario["nombre_completo"]
        session["correo"] = usuario["correo"]

        return jsonify({
            "ok": True,
            "mensaje": f"Bienvenido, {usuario['nombre_completo']}.",
            "usuario": {
                "id": usuario["id_usuario"],
                "nombre": usuario["nombre_completo"],
                "correo": usuario["correo"],
            },
            "redirect": "/dashboard",
        })

    except Error as e:
        return jsonify({"ok": False, "mensaje": f"Error de base de datos: {str(e)}"}), 500


@app.route("/api/logout", methods=["POST", "GET"])
def api_logout():
    session.clear()
    return jsonify({"ok": True, "mensaje": "Sesión cerrada.", "redirect": "/"})


@app.route("/api/me")
def api_me():
    if "id_usuario" not in session:
        return jsonify({"ok": False, "mensaje": "No hay sesión activa."}), 401

    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT u.id_usuario, u.nombre_completo, u.correo, u.fecha_registro,
                   p.biografia, p.institucion,
                   pr.porcentaje_global, pr.cursos_completados
            FROM usuarios u
            LEFT JOIN perfiles_usuario p ON p.id_usuario = u.id_usuario
            LEFT JOIN progreso_academico pr ON pr.id_usuario = u.id_usuario
            WHERE u.id_usuario = %s
            """,
            (session["id_usuario"],),
        )
        datos = cursor.fetchone()
        cursor.close()
        conn.close()

        if not datos:
            return jsonify({"ok": False, "mensaje": "Usuario no encontrado."}), 404
        return jsonify({"ok": True, "usuario": datos})
    except Error as e:
        return jsonify({"ok": False, "mensaje": f"Error de base de datos: {str(e)}"}), 500


# Servir el resto de archivos (HTML, CSS, etc.)
@app.route("/<path:filename>")
def static_files(filename):
    return send_from_directory(STATIC_DIR, filename)


if __name__ == "__main__":
    print("=" * 55)
    print("  AprendeIA Ética → http://127.0.0.1:5000")
    print("=" * 55)
    app.run(host="0.0.0.0", port=5000, debug=True)