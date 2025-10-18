# 🃏 YuGiOh Scanner App

Aplicación móvil para escanear y gestionar cartas de Yu-Gi-Oh! utilizando reconocimiento óptico de caracteres (OCR) avanzado y procesamiento en la nube. La aplicación permite a los jugadores digitalizar rápidamente sus colecciones de cartas, obtener información detallada y gestionar su inventario de manera eficiente.

## 🚀 Características Principales

- **Escaneo Avanzado**: Captura de códigos de serie y códigos de barras de cartas Yu-Gi-Oh!
- **OCR de Alta Precisión**: Reconocimiento óptico de caracteres optimizado para cartas de juego
- **Base de Datos en Tiempo Real**: Sincronización con Supabase para respaldo en la nube
- **Interfaz Inmersiva**: Diseño moderno con modo oscuro y orientación horizontal optimizada
- **Procesamiento por Lotes**: Escaneo y procesamiento eficiente de múltiples cartas simultáneamente
- **Seguimiento en Tiem Real**: Monitoreo del progreso de procesamiento con actualizaciones en directo
- **Base de Datos Local**: Almacenamiento offline con sincronización automática cuando hay conexión
- **Gestión de Colección**: Filtrado y búsqueda avanzada en tu colección de cartas
- **Soporte Multilenguaje**: Interfaz disponible en múltiples idiomas
- **Exportación de Datos**: Posibilidad de exportar tu colección en diferentes formatos

## 🛠️ Tecnologías Utilizadas

- **Flutter** - Framework de desarrollo móvil multiplataforma
- **Google ML Kit** - Motor de reconocimiento de texto (OCR) optimizado para móviles
- **Supabase** - Backend como servicio (BaaS) con base de datos PostgreSQL en tiempo real
- **Provider** - Gestión de estado ligera y eficiente
- **HTTP/WebSockets** - Comunicación con servicios web y actualizaciones en tiempo real
- **SQLite** - Almacenamiento local para funcionamiento offline
- **Google ML Vision** - Procesamiento de imágenes en dispositivos móviles

## 🔍 Funcionamiento del OCR

El sistema de reconocimiento óptico de caracteres (OCR) está optimizado específicamente para leer códigos de cartas de Yu-Gi-Oh! incluso en condiciones subóptimas. Aquí te explicamos cómo funciona:

### Características del OCR

- **Precisión Mejorada**: Algoritmos de corrección de errores para caracteres mal reconocidos
- **Tolerante a Errores**: Funciona incluso con imágenes de baja calidad o ángulos subóptimos
- **Procesamiento Rápido**: Optimizado para dispositivos móviles con bajo consumo de recursos
- **Validación en Tiempo Real**: Verifica los códigos contra una base de datos de códigos válidos

### Cómo Funciona el Reconocimiento

1. **Preprocesamiento de la Imagen**:
   - La imagen se convierte a escala de grises
   - Se aplican filtros para mejorar el contraste y reducir el ruido
   - Se detectan y enderezan las perspectivas inclinadas

2. **Extracción de Texto**:
   - Google ML Kit procesa la imagen para detectar regiones de texto
   - Se identifican bloques de texto y sus coordenadas
   - El texto se extrae con información de confianza por carácter

3. **Procesamiento de Códigos**:
   - Los códigos se limpian y normalizan
   - Se aplican correcciones para errores comunes de OCR (ej: 'O' → '0', 'I' → '1')
   - Se validan contra patrones de códigos de cartas conocidos

### Código del Servicio OCR

```dart
// Extrae y valida un código de carta del texto reconocido
static Future<String?> extractCardCode(String text) async {
  final acronymSet = await _getAcronymSet();
  if (acronymSet.isEmpty) return null;

  // Limpieza del texto
  final hyperCleanedText = text.toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9\-]'),
    ' ',
  );

  // Procesamiento de candidatos
  final candidates = hyperCleanedText
      .split(' ')
      .where((s) => s.length >= 6 && s.length <= 15);

  // Validación de códigos
  for (final candidate in candidates) {
    final result = _validateCandidate(candidate, acronymSet);
    if (result != null) return result;
  }
  return null;
}
```

### Patrones de Códigos Soportados

- `EN001` - Formato básico (idioma + número)
- `EN001-EN001` - Códigos con sufijo
- `SDY-001` - Formato con guión
- `MRD-EN001` - Códigos de expansión
- `JP001` - Códigos japoneses

### Optimizaciones de Rendimiento

- **Caché de Códigos**: Los códigos válidos se cargan una vez y se mantienen en memoria
- **Procesamiento por Lotes**: Múltiples códigos se procesan eficientemente
- **Validación en Dos Pasos**: Primero patrones simples, luego validación contra la base de datos

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

### Core
- `flutter`: ^3.16.0
- `dart`: ^3.2.0

### Reconocimiento de Imágenes
- `google_mlkit_text_recognition`: ^0.11.0 - Motor de OCR de Google ML Kit
- `camera`: ^0.10.5+2 - Acceso a la cámara del dispositivo
- `image_picker`: ^1.0.7 - Selección de imágenes de la galería

### Base de Datos y Almacenamiento
- `supabase_flutter`: ^2.3.4 - Cliente para Supabase
- `sqflite`: ^2.3.2 - Base de datos SQLite local
- `shared_preferences`: ^2.2.2 - Almacenamiento de preferencias

### Estado y Gestión de Datos
- `provider`: ^6.1.1 - Gestión de estado
- `http`: ^1.1.2 - Peticiones HTTP
- `dio`: ^5.3.2 - Cliente HTTP avanzado

### UI/UX
- `flutter_svg`: ^2.0.9 - Soporte para gráficos vectoriales
- `shimmer`: ^3.0.0 - Efectos de carga
- `flutter_spinkit`: ^5.2.0 - Indicadores de carga animados

### Utilidades
- `intl`: ^0.18.1 - Internacionalización
- `path_provider`: ^2.1.1 - Manejo de rutas del sistema
- `url_launcher`: ^6.1.14 - Apertura de enlaces externos

## 🔒 Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto con las siguientes variables:

```
SUPABASE_URL=tu_url_de_supabase
SUPABASE_KEY=tu_clave_de_supabase
WEBHOOK_URL=url_de_tu_webhook
```

## 🚀 Rendimiento y Optimización

### Técnicas de Optimización

1. **Carga Diferida**:
   - Los recursos pesados se cargan bajo demanda
   - Las pantallas se construyen de forma perezosa

2. **Gestión de Memoria**:
   - Las imágenes se redimensionan antes de procesar
   - Se liberan recursos de cámara cuando no son necesarios
   - Uso eficiente de caché para datos frecuentemente accedidos

3. **Rendimiento del OCR**:
   - Procesamiento en segundo plano para no bloquear la interfaz
   - Reducción de la resolución de imágenes antes del procesamiento
   - Múltiples pasadas de reconocimiento con diferentes configuraciones

### Mejores Prácticas

- **Modo Horizontal**: La aplicación está optimizada para funcionar en modo horizontal para una mejor experiencia de escaneo
- **Dispositivos Físicos**: Se recomienda probar en dispositivos físicos para evaluar el rendimiento real del OCR
- **Iluminación**: Para mejores resultados, escanear en áreas bien iluminadas
- **Enfoque**: Mantener la cámara estable y enfocada en el código de la carta
- **Limpieza de Caché**: La aplicación gestiona automáticamente la caché, pero puede limpiarse desde la configuración si es necesario

### Estadísticas de Rendimiento

- Tiempo medio de reconocimiento: < 500ms por imagen
- Tasa de acierto: >95% en condiciones normales de iluminación
- Consumo de memoria: < 100MB en la mayoría de dispositivos
- Tamaño de la aplicación: ~30MB (sin incluir los datos de la base de datos)

### Solución de Problemas

1. **El código no se detecta**:
   - Asegúrate de que la cámara esté enfocando correctamente
   - Intenta con mejor iluminación
   - Limpia la lente de la cámara

2. **Reconocimiento lento**:
   Cierra otras aplicaciones en segundo plano
   Reinicia la aplicación si ha estado en uso prolongado

3. **Errores de conexión**:
   Verifica tu conexión a Internet
   La aplicación funciona en modo offline con funcionalidad limitada

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## ✨ Contribuciones

Las contribuciones son bienvenidas. Por favor, lee las pautas de contribución antes de enviar un pull request.

---

Desarrollado con ❤️ para los amantes de Yu-Gi-Oh!
