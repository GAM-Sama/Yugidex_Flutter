import 'dart:convert'; // Importar para usar LineSplitter

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Un servicio de OCR optimizado para extraer códigos de cartas de Yu-Gi-Oh!.
///
/// Esta versión es extremadamente robusta. Utiliza una limpieza de texto agresiva
/// y una lógica de validación modular para funcionar incluso con resultados de OCR
/// de baja calidad y con texto adicional en la imagen.
class OcrService {
  static Set<String>? _cachedAcronymSet;

  /// Patrones de sufijos válidos después del guion en los códigos de carta.
  static final List<RegExp> _suffixPatterns = [
    RegExp(r'^[A-Z]{2}\d{3}$'), // EN027, FR001, SP004
    RegExp(r'^[A-Z]{3}\d{2,3}$'), // ENG46, ENC17
    RegExp(r'^[A-Z]{1,2}\d{2,3}$'), // S01, E001, etc.
    RegExp(r'^[A-Z]{4}\d{1,2}$'), // ENSE2
    RegExp(r'^\d{3}$'), // Antiguo 001
    RegExp(r'^[A-Z]?\d{3}$'), // E001, S001
    RegExp(r'^JP\d{3}$'), // Japonés OCG: JP001
  ];

  /// Correcciones de OCR comunes (solo letras → números, no al revés).
  static const _correctionMap = {
    'O': '0',
    'I': '1',
    'Z': '2',
    'S': '5',
    'B': '8',
  };

  static Future<Set<String>> _getAcronymSet() async {
    if (_cachedAcronymSet != null) return _cachedAcronymSet!;
    try {
      final fileContent = await rootBundle.loadString(
        'packcodes/card_codes.txt',
      );
      
      final lines = LineSplitter().convert(fileContent);
      final acronyms = <String>{};
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          final upper = trimmed.toUpperCase();
          if (kDebugMode && upper != trimmed) {
            debugPrint('⚠️ Código convertido a mayúsculas: "$trimmed" -> "$upper"');
          }
          acronyms.add(upper);
        }
      }

      _cachedAcronymSet = acronyms;
      debugPrint('✅ Fichero de acrónimos cargado: ${acronyms.length} códigos.');
      
      // Verificar si LDD está en la lista
      if (kDebugMode) {
        if (acronyms.contains('LDD')) {
          debugPrint('✅ Código LDD encontrado en la lista de acrónimos');
        } else {
          debugPrint('❌ Código LDD NO encontrado en la lista de acrónimos');
          // Imprimir algunos códigos para diagnóstico
          final sample = acronyms.take(5).toList();
          debugPrint('   Muestra de códigos cargados: $sample...');
        }
      }

      return acronyms;
    } catch (e) {
      debugPrint('❌ Error al cargar el fichero de acrónimos: $e');
      if (kDebugMode) {
        debugPrint('   Ruta del archivo: packcodes/card_codes.txt');
      }
      return {};
    }
  }

  static Set<String> _generatePermutations(String token) {
    if (token.length > 10) return {token};
    if (token.isEmpty) return {""};
    final firstChar = token[0];
    final restOfToken = token.substring(1);
    final permsOfRest = _generatePermutations(restOfToken);
    final possibleFirstChars =
        {firstChar, _correctionMap[firstChar]}.whereType<String>();
    final result = <String>{};
    for (final char in possibleFirstChars) {
      for (final perm in permsOfRest) {
        result.add(char + perm);
      }
    }
    return result;
  }


  /// Normaliza sufijos sospechosos del OCR (ej. EN0334 -> EN033).
  static String _normalizeSuffix(String suffix) {
    // Normalizar sufijos que comienzan con S seguido de dígitos
    if (suffix.startsWith('S') && suffix.length > 1) {
      final numberPart = suffix.substring(1);
      if (RegExp(r'^[0-9OIlZSB]+$').hasMatch(numberPart)) {
        // Reemplazar caracteres que podrían ser números
        final normalizedNumber = numberPart
            .replaceAll('O', '0')
            .replaceAll('I', '1')
            .replaceAll('l', '1')
            .replaceAll('Z', '2')
            .replaceAll('S', '5')
            .replaceAll('B', '8');
        
        // Asegurarse de que después de S solo hay números
        if (RegExp(r'^\d+$').hasMatch(normalizedNumber)) {
          return 'S$normalizedNumber';
        }
      }
    }
    
    // Normalizar sufijos con demasiados dígitos
    final match = RegExp(r'^([A-Z]*)(\d{4,})$').firstMatch(suffix);
    if (match != null) {
      final base = match.group(1)!;
      final digits = match.group(2)!;
      // Mantener solo los primeros 3 dígitos si hay más de 3
      return '$base${digits.substring(0, 3)}';
    }
    
    return suffix;
  }

  static String? _findValidSuffix(String suffix) {
    // Primero intentamos normalizar el sufijo
    suffix = _normalizeSuffix(suffix);
    
    // Si el sufijo comienza con 'S' seguido de dígitos, asegurarse de que sea un número
    if (suffix.startsWith('S') && suffix.length > 1) {
      final numberPart = suffix.substring(1);
      if (RegExp(r'^\d+$').hasMatch(numberPart)) {
        // Si es un número válido, devolverlo como está
        if (kDebugMode) {
          debugPrint('✅ Sufijo con prefijo S y número válido: $suffix');
        }
        return suffix;
      } else {
        // Si no es un número, intentar corregir caracteres que podrían ser números
        final correctedNumber = numberPart
            .replaceAll('O', '0')
            .replaceAll('I', '1')
            .replaceAll('l', '1')
            .replaceAll('Z', '2')
            .replaceAll('S', '5')
            .replaceAll('B', '8');
            
        if (RegExp(r'^\d+$').hasMatch(correctedNumber)) {
          final correctedSuffix = 'S$correctedNumber';
          if (kDebugMode) {
            debugPrint('✅ Sufijo corregido de $suffix a $correctedSuffix');
          }
          return correctedSuffix;
        }
      }
    }
    
    // Si el sufijo ya coincide con algún patrón, devolverlo directamente
    for (final pattern in _suffixPatterns) {
      if (pattern.hasMatch(suffix)) {
        if (kDebugMode) {
          debugPrint('✅ Sufijo válido sin permutaciones: $suffix');
        }
        return suffix;
      }
    }
    
    // Si no coincide, generar permutaciones
    final variants = _generatePermutations(suffix);
    if (kDebugMode) {
      debugPrint('🔍 Probando variantes de sufijo para: $suffix');
    }

    String? bestMatch;
    int maxDigits = -1;
    int maxLength = -1;

    for (final variant in variants) {
      for (final pattern in _suffixPatterns) {
        if (pattern.hasMatch(variant)) {
          final digitCount = variant.replaceAll(RegExp(r'[^0-9]'), '').length;
          final variantLength = variant.length;
          
          // Preferir la coincidencia con más dígitos, y en caso de empate, la más larga
          if (digitCount > maxDigits || (digitCount == maxDigits && variantLength > maxLength)) {
            maxDigits = digitCount;
            maxLength = variantLength;
            bestMatch = variant;
            
            if (kDebugMode) {
              debugPrint('   ✅ Variante válida: $variant (dígitos: $digitCount, longitud: $variantLength)');
            }
          }
        }
      }
    }

    if (kDebugMode && bestMatch != null) {
      debugPrint('   🏆 Mejor coincidencia: $bestMatch');
    } else if (kDebugMode) {
      debugPrint('   ❌ Ninguna variante válida para: $suffix');
    }

    return bestMatch;
  }

  static String? _validateCandidate(String candidate, Set<String> acronymSet) {
    debugPrint('\n🔍 VALIDANDO CANDIDATO: "$candidate"');
    
    // 1. Intentar dividir por guion si existe
    if (candidate.contains('-')) {
      debugPrint('   🔄 Probando como código con guion...');
      final parts = candidate.split('-');
      
      if (parts.length < 2) {
        debugPrint('   ❌ No hay suficientes partes después de dividir por guion');
        return null;
      }
      
      // Unir todas las partes después del primer guion (por si hay múltiples guiones)
      final prefixCandidate = parts.first;
      final suffixCandidate = parts.sublist(1).join(''); // Unir sin guiones adicionales
      
      debugPrint('   - Prefijo: "$prefixCandidate"');
      debugPrint('   - Sufijo: "$suffixCandidate"');
      
      // Verificar si el prefijo está en la lista de acrónimos
      if (acronymSet.contains(prefixCandidate)) {
        debugPrint('   ✅ Prefijo válido encontrado en la lista: $prefixCandidate');
        
        // Verificar el sufijo
        final validSuffix = _findValidSuffix(suffixCandidate);
        if (validSuffix != null) {
          final result = '$prefixCandidate-$validSuffix';
          debugPrint('   🎯 SUFIJOS VÁLIDO: $validSuffix');
          debugPrint('   🎯 CÓDIGO VÁLIDO: $result');
          return result;
        } else {
          debugPrint('   ❌ El sufijo "$suffixCandidate" no es válido');
        }
      } else {
        debugPrint('   ❌ El prefijo "$prefixCandidate" no está en la lista de acrónimos');
        
        // Verificar si el prefijo está en mayúsculas
        if (prefixCandidate != prefixCandidate.toUpperCase()) {
          debugPrint('   ℹ️  El prefijo no está en mayúsculas, intentando con mayúsculas...');
          final upperPrefix = prefixCandidate.toUpperCase();
          if (acronymSet.contains(upperPrefix)) {
            debugPrint('   ✅ Prefijo válido después de convertir a mayúsculas: $upperPrefix');
            final validSuffix = _findValidSuffix(suffixCandidate);
            if (validSuffix != null) {
              final result = '$upperPrefix-$validSuffix';
              debugPrint('   🎯 CÓDIGO VÁLIDO (después de mayúsculas): $result');
              return result;
            }
          }
        }
      }
      
      // Si llegamos aquí, intentar sin guiones
      final combined = candidate.replaceAll('-', '');
      debugPrint('   🔄 Probando combinación sin guiones: "$combined"');
      
      // Verificar si el candidato completo es un prefijo válido (sin sufijo)
      if (acronymSet.contains(combined)) {
        debugPrint('   ℹ️  El código completo es un prefijo válido (sin sufijo): $combined');
        // No devolvemos todavía, seguimos buscando un código completo
      }
      
      // Intentar dividir en todas las posiciones posibles
      for (int i = 3; i <= combined.length - 2; i++) {
        final prefixCandidate = combined.substring(0, i);
        final suffixCandidate = combined.substring(i);
        
        // Solo mostrar los primeros 3 intentos para no saturar los logs
        if (i <= 5) {
          debugPrint('   - Probando división: "$prefixCandidate" + "$suffixCandidate"');
        } else if (i == 6) {
          debugPrint('   - ... y más combinaciones ...');
        }
        
        if (acronymSet.contains(prefixCandidate)) {
          final validSuffix = _findValidSuffix(suffixCandidate);
          if (validSuffix != null) {
            final result = '$prefixCandidate-$validSuffix';
            debugPrint('   🎯 CÓDIGO VÁLIDO ENCONTRADO: $result');
            return result;
          }
        }
      }
    } 
    // 2. Si no tiene guion, probar todas las divisiones posibles
    else {
      debugPrint('   🔄 Probando como código sin guion...');
      
      // Verificar si el candidato completo es un prefijo válido (sin sufijo)
      if (acronymSet.contains(candidate)) {
        debugPrint('   ℹ️  El código completo es un prefijo válido (sin sufijo): $candidate');
        // No devolvemos todavía, seguimos buscando un código completo
      }
      
      // Intentar dividir en todas las posiciones posibles
      for (int i = 3; i <= candidate.length - 2; i++) {
        final prefixCandidate = candidate.substring(0, i);
        final suffixCandidate = candidate.substring(i);
        
        // Solo mostrar los primeros 3 intentos para no saturar los logs
        if (i <= 5) {
          debugPrint('   - Probando división: "$prefixCandidate" + "$suffixCandidate"');
        } else if (i == 6) {
          debugPrint('   - ... y más combinaciones ...');
        }
        
        if (acronymSet.contains(prefixCandidate)) {
          debugPrint('      ✅ Prefijo válido: $prefixCandidate');
          final validSuffix = _findValidSuffix(suffixCandidate);
          if (validSuffix != null) {
            final result = '$prefixCandidate-$validSuffix';
            debugPrint('      🎯 SUFIJO VÁLIDO: $validSuffix');
            debugPrint('      🎯 CÓDIGO VÁLIDO: $result');
            return result;
          } else {
            debugPrint('      ❌ El sufijo "$suffixCandidate" no es válido');
          }
        }
      }
    }
    
    debugPrint('   ❌ No se encontró una combinación válida para: $candidate');
    return null;
  }

  /// Normaliza el texto antes del procesamiento OCR.
  /// Reemplaza guiones raros, normaliza espacios y corrige errores comunes de OCR.
  static String _preNormalize(String input) {
    var s = input.trim();

    // Normaliza distintos tipos de guion a ASCII '-'
    s = s.replaceAll('–', '-').replaceAll('—', '-');

    // Normaliza barras, comas raras, etc. a guion si procede
    s = s.replaceAll('/', '-').replaceAll('\\', '-');

    // Quita múltiples espacios
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    return s;
  }

  static Future<String?> extractCardCode(String text) async {
    debugPrint('\n🔍 INICIO DE ANÁLISIS OCR 🔍');
    debugPrint('📝 Texto recibido: "$text"');
    
    final acronymSet = await _getAcronymSet();
    if (acronymSet.isEmpty) {
      debugPrint('❌ ERROR: No se pudo cargar el conjunto de acrónimos');
      return null;
    }

    // 1. Pre-normalización
    final raw = _preNormalize(text).toUpperCase();
    debugPrint('🔄 Texto pre-normalizado: "$raw"');
    
    // 2. Limpieza del texto
    final hyperCleanedText = raw.replaceAll(RegExp(r'[^A-Z0-9\- ]'), ' ');
    debugPrint('🧹 Texto limpiado: "$hyperCleanedText"');

    // 3. Tokenización
    final tokens = hyperCleanedText.split(' ').where((s) => s.isNotEmpty).toList();
    debugPrint('🔤 Tokens extraídos: $tokens');

    // 4. Generación de candidatos
    final candidates = <String>{};
    
    // a) Tokens individuales
    for (final t in tokens) {
      if (t.length >= 3 && t.length <= 15) { // Reducido el mínimo a 3 para prefijos cortos
        candidates.add(t);
      }
    }
    
    // b) Combinaciones de tokens adyacentes
    for (int i = 0; i < tokens.length - 1; i++) {
      final a = tokens[i];
      final b = tokens[i + 1];
      
      // Comprobar si el primer token es un prefijo conocido
      if (acronymSet.contains(a)) {
        debugPrint('   ✅ Prefijo conocido detectado: $a');
        // Si el primer token es un prefijo conocido, añadimos combinaciones con y sin guion
        candidates.add('$a-$b');
        candidates.add('$a$b');
      }
      
      // Comprobar si el segundo token es un sufijo conocido (por si acaso)
      if (_isPotentialSuffix(b)) {
        debugPrint('   ✅ Sufijo potencial detectado: $b');
        candidates.add('$a-$b');
        candidates.add('$a$b');
      }
      
      // Añadir combinaciones en cualquier caso
      if (a.isNotEmpty && b.isNotEmpty) {
        candidates.add('$a-$b');
        candidates.add('$a$b');
      }
    }

    // Mostrar candidatos generados
    debugPrint('🎯 Candidatos generados (${candidates.length}):');
    for (final c in candidates) {
      debugPrint('   - "$c"');
    }

    // 5. Validación de candidatos
    debugPrint('\n🔍 Validando candidatos...');
    for (final candidate in candidates) {
      debugPrint('\n🔄 Procesando candidato: "$candidate"');
      final result = _validateCandidate(candidate, acronymSet);
      if (result != null) {
        debugPrint('✅✅✅ CÓDIGO VÁLIDO ENCONTRADO: $result ✅✅✅');
        return result;
      }
    }

    debugPrint('❌❌❌ NO SE ENCONTRÓ NINGÚN CÓDIGO VÁLIDO');
    return null;
  }
  
  // Función auxiliar para detectar si un token podría ser un sufijo
  static bool _isPotentialSuffix(String token) {
    if (token.isEmpty) return false;
    
    // Un sufijo típico tiene al menos un número o comienza con S seguido de números
    if (!RegExp(r'\d').hasMatch(token) && !token.startsWith('S')) {
      return false;
    }
    
    // Si comienza con S, verificar que el resto sean números o caracteres que podrían ser números
    if (token.startsWith('S') && token.length > 1) {
      final remaining = token.substring(1);
      return RegExp(r'^[0-9OIlZSB]+$').hasMatch(remaining);
    }
    
    // Verificar patrones de sufijos comunes
    return _suffixPatterns.any((pattern) => pattern.hasMatch(token));
  }
}
