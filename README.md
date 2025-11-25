# 🎮 Game Manager App

Aplicación móvil desarrollada en **Flutter** para gestionar un catálogo personal de videojuegos, con autenticación de usuarios, favoritos, modo oscuro y un diseño tipo gamer.

> Cada usuario tiene **su propio catálogo**: solo ve los juegos que él mismo ha registrado.

---

## ✨ Funcionalidades principales

- 🔐 **Autenticación con Firebase**
  - Registro e inicio de sesión con email y contraseña.
  - Validaciones en formularios (login / registro).
  - Cierre de sesión.
  - Eliminación completa de cuenta (borra usuario, juegos y favoritos).

- 🎮 **Gestión de videojuegos (CRUD)**
  - Crear, leer, actualizar y eliminar juegos.
  - Campos como título, género, plataforma, descripción, precio, imagen, etc.
  - (Opcional) Subida de imagen a Firebase Storage.

- ⭐ **Favoritos**
  - Marcar o desmarcar juegos como favoritos.
  - Sección de **“Favoritos”** que muestra solo los juegos marcados.
  - Favoritos guardados por usuario (no se mezclan con otros).

- 🔍 **Búsqueda y filtros**
  - Búsqueda por título, género o plataforma.
  - Filtro por géneros en la lista de juegos.
  - Resultados con diseño tipo card gamer.

- 👤 **Perfil y ajustes**
  - Ver nombre y correo del usuario.
  - Cambiar nombre para mostrar.
  - Cambiar contraseña (con reautenticación y validaciones).
  - Cambiar foto de perfil (placeholder listo para integrar).
  - Zona peligrosa: eliminar cuenta (usuario + datos asociados).

- 🕹️ **Interfaz tipo gamer**
  - Tema oscuro por defecto con colores morado / neón.
  - Componentes personalizados:
    - `GameBackground` (fondo degradado gamer).
    - `GameGlassCard` (cards con efecto glassmorphism).
    - Botones principales con estilo gamer.
  - Bottom Navigation Bar con:
    - Inicio, Buscar, Lista, Favoritos y Perfil.
  - Drawer lateral con:
    - Datos del usuario.
    - Navegación rápida.
    - Switch de modo oscuro.
    - Cerrar sesión.

---

## 🧱 Tecnologías utilizadas

- **Framework:** Flutter
- **Lenguaje:** Dart
- **Backend as a Service:** Firebase
  - Firebase Authentication
  - Cloud Firestore
  - (Opcional) Firebase Storage
- **State Management:** `provider`
- **Plataformas objetivo:** Android (APK release), Web (para pruebas)

---

## 📁 Estructura general del proyecto

> Nota: ajusta los nombres de archivos si en tu proyecto cambiaron.

```text
lib/
 ├─ main.dart
 ├─ providers/
 │   ├─ theme_provider.dart
 │   └─ auth_service.dart
 ├─ screens/
 │   ├─ auth/
 │   │   ├─ login_page.dart
 │   │   └─ register_page.dart
 │   ├─ main/
 │   │   ├─ main_app_screen.dart
 │   │   ├─ home_page.dart
 │   │   ├─ search_page.dart
 │   │   ├─ game_list_page.dart
 │   │   ├─ favorites_page.dart
 │   │   └─ profile_page.dart
 │   ├─ game/
 │   │   └─ game_crud_page.dart
 │   └─ game_detail_page.dart
 ├─ widgets/
 │   ├─ game_ui.dart      // fondo, cards y botones gamer
 │   └─ favorite_button.dart
 └─ models/
     └─ game_model.dart   // (si aplica)
```

---

## ⚙️ Requisitos previos

- Tener instalado:
  - [Flutter](https://flutter.dev) (canal stable)
  - Dart SDK (incluido con Flutter)
  - Android Studio o VS Code (opcional pero recomendado)
- Tener una cuenta en [Firebase](https://firebase.google.com/)

---

## 🔥 Configuración de Firebase

1. Crear un proyecto en Firebase.
2. Habilitar:
   - **Authentication → Email/Password**
   - **Cloud Firestore** (modo production o test según necesidad).
3. Agregar una app de Android:
   - Registrar el paquete (por ejemplo: `com.example.game_manager_app`).
   - Descargar `google-services.json` y colocarlo en:
     ```text
     android/app/google-services.json
     ```
4. Instalar y configurar Firebase en el proyecto:
   ```bash
   flutter pub get
   flutterfire configure
   ```

> 🔒 **Importante:** No subir a GitHub claves sensibles.  
> Puedes ignorar `google-services.json` si lo deseas.

---

## ▶️ Cómo ejecutar el proyecto en modo debug

1. Clonar el repositorio:

   ```bash
   git clone https://github.com/tu-usuario/tu-repo.git
   cd tu-repo
   ```

2. Instalar dependencias:

   ```bash
   flutter pub get
   ```

3. Ejecutar en un dispositivo/emulador:

   ```bash
   flutter run
   ```

---

## 📦 Generar APK (Android)

Para generar el APK en modo **release**:

```bash
flutter build apk --release
```

El archivo generado se encuentra en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Si deseas APKs separados por arquitectura:

```bash
flutter build apk --release --split-per-abi
```

---

## 👀 Puntos fuertes para presentar

- Multiusuario: cada usuario ve **solo sus juegos** gracias al campo `createdBy` en Firestore.
- Favoritos guardados en subcolección: `users/{uid}/favorites`.
- Pantalla de detalle para cada juego:
  - Imagen grande.
  - Género, plataforma, descripción, precio.
  - Botones para **Editar** y **Eliminar**.
- Perfil completo:
  - Cambiar contraseña con reautenticación.
  - Eliminar cuenta borrando datos relacionados.
- Diseño consistente gamer (colores, sombras, glassmorphism, iconos).

---

## 🚀 Posibles mejoras futuras

- Soporte multilenguaje (es/en).
- Paginación o infinite scroll en listas grandes.
- Filtros avanzados (precio, plataforma, etc.).
- Sistema de ratings o reseñas para cada juego.
- Notificaciones push (Firebase Cloud Messaging).

---

## 📜 Licencia

Puedes añadir la licencia que utilices, por ejemplo:

```text
MIT License
```

o la que tu proyecto requiera.
