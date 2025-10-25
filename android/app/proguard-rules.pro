# Mantener reglas para scripts de idioma de Google ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# Reglas adicionales para Google ML Kit Text Recognition
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.interfaces.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Mantener todas las clases del paquete google_mlkit_text_recognition
-keep class com.google_mlkit_text_recognition.** { *; }

# Reglas para Flutter Google ML Kit plugin
-keep class io.flutter.plugins.googlemlkit.** { *; }

# Mantener implementaciones específicas de TextRecognizer
-keep class com.google.mlkit.vision.text.TextRecognizer { *; }
-keep class com.google.mlkit.vision.text.TextRecognizerOptionsInterface { *; }

# Puedes añadir aquí otras reglas Proguard si las necesitas en el futuro
# Por ejemplo, las que Flutter añade por defecto (si no las tienes ya en build.gradle):
# -keep class io.flutter.app.** { *; }
# -keep class io.flutter.plugin.** { *; }
# -keep class io.flutter.util.** { *; }
# -keep class io.flutter.view.** { *; }
# -keep class io.flutter.** { *; }
# -keep class io.flutter.plugins.** { *; }
# -keep class com.google.firebase.** { *; } # Si usas Firebase
# -keep class com.google.android.gms.** { *; } # Si usas Google Play Services