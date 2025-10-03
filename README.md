# YuGiOh Scanner App

Aplicación móvil para escanear y gestionar cartas de Yu-Gi-Oh! utilizando reconocimiento óptico de caracteres (OCR) y procesamiento en la nube.

## 🚀 Características

- Escaneo de códigos de barras y códigos de serie de cartas Yu-Gi-Oh!
- Reconocimiento óptico de caracteres (OCR) integrado
- Sincronización con base de datos en la nube (Supabase)
- Interfaz de usuario intuitiva y moderna
- Seguimiento en tiempo real del estado del procesamiento
- Almacenamiento local de cartas escaneadas
- Compatibilidad con múltiples plataformas (iOS, Android, Web)

## 🛠️ Tecnologías Utilizadas

- **Flutter** - Framework de desarrollo móvil multiplataforma
- **Google ML Kit** - Para el reconocimiento de texto (OCR)
- **Supabase** - Backend como servicio (BaaS) para base de datos
- **Provider** - Gestión de estado
- **HTTP** - Comunicación con servicios web

## 📱 Pantallas Principales

1. **Inicio** - Menú principal con opciones para escanear nuevas cartas o ver la colección
2. **Escáner** - Interfaz de cámara para escanear códigos de cartas
3. **Procesando** - Muestra el progreso del escaneo y procesamiento
4. **Nuevas Cartas** - Muestra las cartas recién escaneadas
5. **Lista de Cartas** - Muestra todas las cartas guardadas en la colección

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada de la aplicación
├── models/               # Modelos de datos
│   ├── card_model.dart
│   └── scanned_card_data.dart
├── screens/              # Pantallas de la aplicación
│   ├── home_screen.dart
│   ├── card_code_scanner_screen.dart
│   ├── processing_screen.dart
│   ├── new_cards_list_screen.dart
│   └── card_list_screen.dart
├── services/             # Servicios externos
│   ├── ocr_service.dart
│   ├── supabase_service.dart
│   └── webhook_service.dart
├── utils/                # Utilidades y constantes
│   └── utils/
│       └── card_constants.dart
└── view_models/          # Lógica de negocio
    ├── card_scanner_view_model.dart
    └── card_list_view_model.dart
```

## ⚙️ Configuración

1. Clona el repositorio
2. Instala las dependencias:
   ```bash
   flutter pub get
   ```
3. Configura las variables de entorno necesarias (ver `.env.example`)
4. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## 📦 Dependencias Principales

- `google_mlkit_text_recognition`: Para reconocimiento de texto en imágenes
- `supabase_flutter`: Cliente para Supabase
- `provider`: Para gestión de estado
- `http`: Para peticiones HTTP
- `camera`: Para el acceso a la cámara
- `shared_preferences`: Para almacenamiento local

## 🔒 Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```
SUPABASE_URL=tu_url_de_supabase
SUPABASE_KEY=tu_clave_de_supabase
WEBHOOK_URL=url_de_tu_webhook
```

## 📝 Notas de Desarrollo

- La aplicación está optimizada para funcionar en modo horizontal
- Se recomienda probar en dispositivos físicos para mejor rendimiento del OCR
- El procesamiento de imágenes se realiza en lotes para mejorar la eficiencia

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## ✨ Contribuciones

Las contribuciones son bienvenidas. Por favor, lee las pautas de contribución antes de enviar un pull request.

---

Desarrollado con ❤️ para los amantes de Yu-Gi-Oh!
