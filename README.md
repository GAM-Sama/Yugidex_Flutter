# Yugidex

Aplicación móvil desarrollada en Flutter para escanear, procesar y gestionar colecciones de cartas Yu-Gi-Oh! utilizando tecnología avanzada de reconocimiento óptico de caracteres (OCR) y procesamiento en la nube. Esta herramienta permite a los jugadores digitalizar rápidamente sus colecciones, obtener información detallada de cada carta y gestionar su inventario de manera eficiente y profesional.

## Características Principales

### Escaneo y Procesamiento Avanzado
- **Reconocimiento Óptico de Caracteres (OCR)**: Tecnología Google ML Kit optimizada específicamente para códigos de cartas Yu-Gi-Oh!
- **Procesamiento por Lotes**: Escaneo eficiente de múltiples cartas con seguimiento en tiempo real
- **Validación Robusta**: Sistema de corrección automática para códigos mal reconocidos
- **Procesamiento en la Nube**: Backend dedicado que enriquece la información de las cartas

### Gestión de Colección
- **Base de Datos Personal**: Almacenamiento seguro en Supabase con sincronización en tiempo real
- **Sistema de Cantidades**: Seguimiento preciso de múltiples copias de la misma carta
- **Gestión de Inventario**: Añadir, eliminar y modificar cantidades con validaciones automáticas
- **Búsqueda y Filtrado Avanzado**: Múltiples criterios de filtrado y ordenación inteligente

### Interfaz de Usuario
- **Diseño Moderno**: Tema oscuro elegante con colores azul marino y acentos dorados
- **Orientación Horizontal**: Optimizada para una experiencia de escaneo natural
- **Animaciones Fluidas**: Transiciones suaves y feedback visual en todas las interacciones
- **Indicadores Visuales**: Badges de cantidad, estados de selección y progreso de operaciones

## Funcionalidades Detalladas

### Sistema de Escaneo
El escáner utiliza Google ML Kit para reconocer códigos de cartas con una precisión superior al 95% en condiciones normales. El sistema incluye:

- **Corrección Automática**: Transformación inteligente de caracteres similares (O→0, I→1, etc.)
- **Validación Cruzada**: Verificación contra base de datos de más de 600 códigos de expansión
- **Procesamiento Inteligente**: Normalización de sufijos y corrección de errores comunes
- **Feedback en Tiempo Real**: Círculo de enfoque dinámico y contador de códigos detectados

### Gestión de Cartas
La aplicación ofrece un sistema completo de gestión de colecciones:

- **Panel de Detalles**: Información completa de cada carta con formato específico por tipo
- **Sistema de Filtros**: Filtrado por marco, atributo, tipo, subtipo y estadísticas
- **Ordenación Inteligente**: Múltiples criterios con agrupación automática por tipo de carta
- **Búsqueda Avanzada**: Búsqueda por nombre o código de carta con resultados instantáneos

### Tipos de Carta Soportados
- **Monstruos**: Normal, Effect, Fusion, Synchro, Xyz, Link, Pendulum, Ritual
- **Cartas Mágicas**: Normal, Field, Equip, Continuous, Quick-Play, Ritual
- **Trampas**: Normal, Continuous, Counter

## Tecnologías Utilizadas

### Framework y Lenguajes
- **Flutter 3.16.0+**: Framework principal para desarrollo multiplataforma
- **Dart 3.2.0+**: Lenguaje de programación moderno y eficiente

### Inteligencia Artificial y Visión
- **Google ML Kit Text Recognition 0.15.0**: Motor OCR de vanguardia
- **Camera 0.11.0**: Control avanzado de cámara con enfoque automático
- **Image Processing**: Algoritmos personalizados para optimización de imágenes

### Base de Datos y Backend
- **Supabase 2.5.0**: Plataforma backend-as-a-service con PostgreSQL
- **Autenticación Segura**: Sistema de usuarios con JWT tokens
- **Sincronización en Tiempo Real**: Actualizaciones automáticas entre dispositivos

### Gestión de Estado
- **Provider 6.1.2**: Manejo de estado reactivo y eficiente
- **ViewModels Especializados**: Arquitectura MVVM para separación de responsabilidades

### UI/UX y Utilidades
- **Google Fonts**: Tipografía Poppins para interfaz moderna
- **Cached Network Images**: Carga optimizada de imágenes de cartas
- **Staggered Animations**: Animaciones fluidas en listas y grids
- **Custom Theme System**: Paleta de colores y espaciado consistente

## Instalación y Configuración

### Requisitos del Sistema
- **Android**: API Level 21+ (Android 5.0)
- **iOS**: iOS 12.0+
- **Memoria**: Mínimo 100MB disponibles
- **Cámara**: Dispositivo con cámara y enfoque automático

### Pasos de Instalación

1. **Clonar el Repositorio**
   ```bash
   git clone <url_del_repositorio>
   cd yugioh_scanner
   ```

2. **Instalar Dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Variables de Entorno**
   Crear archivo `.env` en la raíz del proyecto:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-anon-key
   WEBHOOK_URL=https://your-webhook-url.com
   ```

4. **Ejecutar la Aplicación**
   ```bash
   flutter run
   ```

### Configuración de Supabase

1. **Crear Proyecto**: Configurar nuevo proyecto en [Supabase](https://supabase.com)
2. **Crear Tablas**:
   ```sql
   -- Tabla de cartas maestras
   CREATE TABLE Cartas (
     ID_Carta VARCHAR PRIMARY KEY,
     Nombre VARCHAR,
     Imagen TEXT,
     Marco_Carta VARCHAR,
     Tipo VARCHAR,
     Subtipo TEXT[],
     Atributo VARCHAR,
     Clasificacion VARCHAR,
     ATK VARCHAR,
     DEF VARCHAR,
     Nivel_Rank_Link INTEGER,
     ratio_enlace INTEGER,
     escala_pendulo INTEGER,
     Rareza TEXT[],
     Set_Expansion VARCHAR,
     Icono_Carta VARCHAR
   );

   -- Tabla de colección personal
   CREATE TABLE user_cards (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     user_id UUID REFERENCES auth.users(id),
     carta_id INTEGER REFERENCES Cartas(ID_Carta),
     cantidad INTEGER DEFAULT 1,
     condition VARCHAR DEFAULT 'mint',
     notes TEXT,
     acquired_date TIMESTAMP DEFAULT NOW()
   );
   ```

3. **Configurar RLS (Row Level Security)**
   ```sql
   ALTER TABLE user_cards ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Users can manage their own cards" ON user_cards
     FOR ALL USING (auth.uid() = user_id);
   ```

## Instrucciones de Uso

### Primeros Pasos
1. **Iniciar la Aplicación**: La app se abrirá en modo horizontal automáticamente
2. **Pantalla Principal**: Tres opciones principales:
   - **Escanear Cartas**: Digitalizar nuevas cartas
   - **Ver Mi Colección**: Gestionar cartas existentes
   - **Mi Perfil**: Configuración de cuenta

### Escaneo de Cartas
1. **Acceder al Escáner**: Presionar "Escanear Cartas"
2. **Enfocar Código**: Apuntar la cámara al código de la carta
3. **Captura Automática**: El sistema detectará y capturará automáticamente
4. **Procesamiento**: Los códigos se envían al backend para obtener información completa
5. **Resultados**: Revisar las cartas procesadas y añadir a la colección

### Gestión de Colección
1. **Visualización**: Grid de cartas con información visual
2. **Badge de Cantidad**: Las cartas con múltiples copias muestran "xN" en amarillo
3. **Filtrado**: Usar el botón de filtros para refinar la vista
4. **Ordenación**: Cambiar el orden por nombre, ataque, defensa, nivel, etc.
5. **Búsqueda**: Usar la barra de búsqueda para encontrar cartas específicas

### Panel de Detalles
- **Información Completa**: Todos los atributos de la carta
- **Estadísticas Específicas**: Formato adecuado según el tipo (Link, Xyz, etc.)
- **Gestión de Cantidad**: Botones para aumentar/disminuir copias
- **Eliminación**: Opción de remover cartas de la colección

## Estructura del Proyecto

```
yugioh_scanner/
├── lib/
│   ├── core/
│   │   ├── theme/              # Sistema de temas y colores
│   │   └── utils/              # Utilidades del núcleo
│   ├── features/
│   │   └── auth/               # Módulo de autenticación completo
│   ├── models/                 # Modelos de datos (Card, UserCard, etc.)
│   ├── screens/                # Pantallas principales
│   │   ├── auth/               # Pantallas de login/registro
│   │   ├── card_code_scanner_screen.dart    # Escáner OCR
│   │   ├── card_list_screen.dart            # Colección personal
│   │   ├── home_screen.dart                 # Menú principal
│   │   ├── new_cards_list_screen.dart       # Cartas procesadas
│   │   ├── processing_screen.dart           # Seguimiento de progreso
│   │   └── profile_screen.dart              # Perfil de usuario
│   ├── services/               # Servicios externos
│   │   ├── auth_service.dart                # Autenticación
│   │   ├── ocr_service.dart                 # Procesamiento OCR
│   │   ├── supabase_service.dart            # Base de datos
│   │   └── webhook_service.dart             # Comunicación backend
│   ├── shared/
│   │   └── widgets/            # Componentes reutilizables
│   ├── view_models/            # Lógica de estado (MVVM)
│   └── main.dart               # Punto de entrada
├── assets/                     # Recursos estáticos
├── android/                    # Configuración Android
├── ios/                        # Configuración iOS
└── pubspec.yaml               # Dependencias y configuración
```

## Funcionalidades Avanzadas

### Sistema de Filtrado
- **Filtros Múltiples**: Combinación de criterios sin límite
- **Filtros por Estadísticas**: Rango mínimo de ATK/DEF
- **Filtros por Atributos**: LIGHT, DARK, WATER, FIRE, EARTH, WIND, DIVINE
- **Filtros por Tipo**: Monstruos, Magias, Trampas con subtipos específicos
- **Búsqueda por Subtipos**: Effect, Fusion, Synchro, Xyz, Link, Pendulum, etc.

### Sistema de Ordenación
- **Ordenación Inteligente**: Algoritmo que prioriza tipos especiales
- **Agrupación Automática**: Monstruos especiales se agrupan por tipo
- **Múltiples Criterios**: Nombre, ataque, defensa, nivel, rango, link, escala
- **Dirección Configurable**: Ascendente y descendente

### Gestión de Cantidades
- **Badge Visual**: Indicador amarillo para cartas con múltiples copias
- **Oculto para Copia Única**: Solo muestra cantidad cuando > 1
- **Gestión en Tiempo Real**: Actualizaciones inmediatas en la interfaz
- **Validaciones**: Prevención de cantidades negativas

## Rendimiento y Optimización

### Técnicas Implementadas
- **Carga Diferida**: Recursos cargados bajo demanda
- **Caché Inteligente**: Datos frecuentemente usados en memoria
- **Procesamiento en Segundo Plano**: Operaciones pesadas sin bloquear UI
- **Optimización de Imágenes**: Redimensionamiento automático antes del procesamiento

### Métricas de Rendimiento
- **Tiempo de Reconocimiento**: < 500ms por imagen
- **Tasa de Éxito**: >95% en condiciones normales
- **Uso de Memoria**: < 100MB en dispositivos estándar
- **Tiempo de Respuesta**: < 200ms para operaciones locales

## Mejores Prácticas de Uso

### Condiciones Óptimas de Escaneo
- **Iluminación**: Áreas bien iluminadas con luz natural o artificial
- **Estabilidad**: Mantener la cámara estable durante el enfoque
- **Distancia**: 10-15 cm del código de la carta
- **Ángulo**: Mantener la cámara perpendicular al código

### Mantenimiento de Colección
- **Actualización Regular**: Sincronizar con la base de datos periódicamente
- **Limpieza de Duplicados**: Revisar y consolidar cartas duplicadas
- **Notas y Condición**: Documentar el estado de cartas valiosas
- **Backup**: La aplicación maneja respaldos automáticos en Supabase

## Solución de Problemas

### Problemas Comunes
1. **Códigos No Detectados**:
   - Verificar iluminación y enfoque
   - Limpiar la lente de la cámara
   - Asegurar que el código esté completo y legible

2. **Reconocimiento Lento**:
   - Cerrar aplicaciones en segundo plano
   - Reiniciar la aplicación si ha estado en uso prolongado
   - Verificar conexión a internet para procesamiento en la nube

3. **Errores de Sincronización**:
   - Verificar credenciales de Supabase
   - Comprobar conexión a internet
   - La aplicación funciona en modo offline con funcionalidad limitada

4. **Problemas de Interfaz**:
   - Reiniciar la aplicación para resetear el estado
   - Verificar que la orientación sea horizontal
   - Actualizar la aplicación a la versión más reciente

## Funcionalidades Recientes

### Badge de Cantidad (v2.1)
- **Indicador Visual**: Badge amarillo en esquina inferior derecha
- **Solo para Múltiples**: Solo se muestra cuando cantidad > 1
- **Diseño Elegante**: Bordes negros y texto negro para máximo contraste
- **Información Clara**: Formato "xN" para cantidad inmediata

### Sistema de Filtrado Mejorado (v2.0)
- **Filtros Avanzados**: Múltiples criterios combinables
- **Ordenación Inteligente**: Agrupación automática por tipo de carta
- **Interfaz Intuitiva**: Diálogos de filtros con categorías organizadas
- **Rendimiento Optimizado**: Filtrado en tiempo real sin bloqueos

### Panel de Detalles Corregido (v1.9)
- **Cartas Link**: Muestra "Link:" con ratioEnlace correcto
- **Cartas Xyz**: Muestra "Rango:" con nivelRankLink correcto
- **Formato ATK/DEF**: Cartas Link muestran "ATK/-" sin defensa
- **Detección Robusta**: Busca en múltiples campos para identificar tipos

## Contribuciones

Las contribuciones son bienvenidas. Se recomienda:

1. **Fork** el repositorio
2. **Crear** una rama para la nueva funcionalidad (`git checkout -b feature/nueva-funcionalidad`)
3. **Commit** los cambios (`git commit -m 'Añadir nueva funcionalidad'`)
4. **Push** a la rama (`git push origin feature/nueva-funcionalidad`)
5. **Crear** un Pull Request

### Pautas de Desarrollo
- Seguir las convenciones de código existentes
- Añadir pruebas unitarias para nuevas funcionalidades
- Documentar cambios significativos
- Mantener compatibilidad hacia atrás

## Licencia

Este proyecto está bajo la Licencia MIT. Consulte el archivo `LICENSE` para más detalles.

## Soporte y Contacto

Para soporte técnico, reportar errores o solicitar nuevas funcionalidades, por favor:

1. **Revisar** la documentación en este README
2. **Consultar** la sección de solución de problemas
3. **Crear** un issue en el repositorio de GitHub
4. **Proporcionar** información detallada del dispositivo y versión de la aplicación

---

**Desarrollado con dedicación para la comunidad de jugadores de Yu-Gi-Oh!**

*Versión 2.1 - Yugidex*
