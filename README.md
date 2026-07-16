# 🎵 Resonar - Music Streaming App

Plataforma de streaming musical con funcionalidades sociales, chat en tiempo real, métricas para creadores y autenticación biométrica.

---

## 🏗️ Arquitectura

```
├── backend/          # API REST (Node.js + Express + TypeScript)
│   ├── prisma/       # Schema y migraciones de base de datos
│   ├── src/
│   │   ├── controllers/  # Lógica de negocio
│   │   ├── middleware/    # Auth, uploads
│   │   ├── routes/        # Definición de endpoints
│   │   └── lib/           # Prisma client
│   └── uploads/      # Archivos subidos (audio, imágenes)
│
└── music_app/        # App Flutter (Dart)
    └── lib/
        ├── models/       # Modelos de datos
        ├── providers/    # State management (Provider)
        ├── screens/      # Pantallas de la app
        └── services/     # Servicios (API, biometría, GPS, shake)
```

---

## 🛠️ Stack Tecnológico

### Backend
| Herramienta | Uso |
|-------------|-----|
| **Node.js + Express** | Servidor HTTP y API REST |
| **TypeScript** | Tipado estático |
| **Prisma ORM** | Mapeo objeto-relacional, migraciones |
| **PostgreSQL** | Base de datos relacional |
| **JWT (jsonwebtoken)** | Autenticación por tokens |
| **bcryptjs** | Hashing de contraseñas |
| **Multer** | Subida de archivos multipart |
| **dotenv** | Variables de entorno |

### Frontend (Flutter)
| Herramienta | Uso |
|-------------|-----|
| **Flutter 3.x** | Framework UI multiplataforma |
| **Dart 3.x** | Lenguaje de programación |
| **Provider** | State management |
| **just_audio** | Reproductor de audio |
| **fl_chart** | Gráficos y métricas |
| **local_auth** | Autenticación biométrica (huella, PIN, patrón) |
| **geolocator** | Geolocalización GPS |
| **sensors_plus** | Detección de sacudidas (shake) |
| **image_picker** | Selección de imágenes |
| **file_picker** | Selección de archivos |
| **http** | Cliente HTTP |
| **shared_preferences** | Persistencia local |
| **cached_network_image** | Caché de imágenes |
| **timeago** | Formato relativo de fechas |
| **intl** | Internacionalización |

---

## 📦 Modelo de Datos (Prisma)

### Tablas principales:

| Modelo | Descripción |
|--------|-------------|
| **User** | Usuarios (email, username, password, country, creator) |
| **ArtistProfile** | Perfil de creador (nombre artístico, bio, género, redes) |
| **Song** | Canciones (título, archivo, cover, plays, género) |
| **Album** | Álbumes |
| **Playlist** | Playlists de usuarios |
| **PlaylistSong** | Relación muchos-a-muchos playlist-canción |
| **LikedSong** | Canciones que le gustan a un usuario |
| **StreamRecord** | Registro de cada reproducción (IP, país, hora) |
| **Conversation** | Chat entre 2 usuarios |
| **Message** | Mensajes dentro de una conversación |

---

## 🔌 Endpoints de la API

> Base URL: `http://<host>:3000/api`

### 🔐 Autenticación
| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/auth/register` | Registro de usuario |
| POST | `/auth/login` | Inicio de sesión |
| GET | `/auth/me` | Perfil del usuario autenticado |

### 👤 Usuarios
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/users/liked-songs` | Canciones favoritas |
| POST | `/users/like/:songId` | Dar/quitar like |

### 🎤 Artistas
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/artists` | Listar artistas |
| GET | `/artists/:id` | Perfil de artista |
| GET | `/artists/me` | Mi perfil de artista |
| POST | `/artists/register` | Registrarse como creador |

### 🎵 Canciones
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/songs` | Listar canciones (filtros: género, búsqueda, orden) |
| GET | `/songs/:id` | Detalle de canción |
| GET | `/songs/my-songs` | Mis canciones subidas |
| POST | `/songs/upload` | Subir canción (multipart) |
| PUT | `/songs/:id` | Editar canción |
| DELETE | `/songs/:id` | Eliminar canción |
| POST | `/songs/:id/play` | Registrar reproducción |

### 📊 Analytics
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/analytics/creator` | Métricas del creador (vistas, países, horarios, etc.) |

### 💬 Chat
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/chat/conversations` | Mis conversaciones |
| GET | `/chat/conversations/:id/messages` | Mensajes de una conversación |
| POST | `/chat/messages` | Enviar mensaje |
| GET | `/chat/search?q=` | Buscar usuarios |

---

## 🎯 Funcionalidades Principales

### Para Usuarios
- ✅ Registro con detección automática de país por **GPS**
- ✅ Login con JWT
- ✅ Explorar canciones por género, búsqueda
- ✅ Dar like a canciones
- ✅ Reproducir audio en streaming con `just_audio`
- ✅ Mini player persistente
- ✅ **Chat** en tiempo real entre usuarios (identificados por username)
- ✅ **Badge de notificaciones** en chats no leídos
- ✅ **Shake to report**: agitar el dispositivo muestra diálogo de reporte de bugs
- ✅ Cerrar sesión redirige automáticamente al login

### Para Creadores
- ✅ Registro como creador con **autenticación biométrica** (huella, PIN o patrón)
- ✅ Subir canciones con portada
- ✅ Eliminar canciones con **confirmación biométrica**
- ✅ Panel de **métricas** avanzadas:
  - 📊 Vistas diarias (gráfico de barras - últimos 30 días)
  - 🏆 Top canciones por plays
  - 🥧 Porcentaje de vistas por canción (gráfico de pastel)
  - 🕐 Streams por hora del día (gráfico de línea)
  - 📅 Streams por día de la semana
  - 🌎 Oyentes por país con ranking

### Técnicas
- ✅ Persistencia de sesión con `SharedPreferences`
- ✅ Protección de rutas con middleware JWT
- ✅ Subida de archivos con Multer
- ✅ Registro de streams con IP, User-Agent y país
- ✅ Base de datos PostgreSQL con migraciones Prisma

---

## 🚀 Instalación y Ejecución

### Requisitos
- Node.js 18+
- PostgreSQL 14+
- Flutter SDK 3.x
- Android Studio / Xcode

### Backend

```bash
cd backend
npm install
# Configurar .env con DATABASE_URL
npx prisma migrate dev
npm run dev
```

### Frontend

```bash
cd music_app
flutter pub get
flutter run
```

---

## 📱 Capturas de Pantalla

| Inicio | Chat | Métricas | Perfil Creador |
|--------|------|----------|----------------|
| Home con secciones | Conversaciones en tiempo real | Gráficos de rendimiento | Gestión de canciones |

---

Desarrollado con ❤️ usando Flutter & Node.js