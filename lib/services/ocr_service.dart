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
      final acronyms =
          LineSplitter()
              .convert(fileContent)
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toSet();

      _cachedAcronymSet = acronyms;
      debugPrint('✅ Fichero de acrónimos cargado: ${acronyms.length} códigos.');

      return acronyms;
    } catch (e) {
      debugPrint('❌ Error al cargar el fichero de acrónimos: $e');
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

  static String? _findValidPrefix(String prefix, Set<String> acronymSet) {
    final variants = _generatePermutations(prefix);
    for (final variant in variants) {
      if (acronymSet.contains(variant)) return variant;
    }
    return null;
  }

  /// Normaliza sufijos sospechosos del OCR (ej. EN0334 -> EN033).
  static String _normalizeSuffix(String suffix) {
    final match = RegExp(r'^(.*[A-Z])(\d{4})$').firstMatch(suffix);
    if (match != null) {
      final base = match.group(1)!;
      final digits = match.group(2)!;
      return '$base${digits.substring(0, 3)}';
    }
    return suffix;
  }

  static String? _findValidSuffix(String suffix) {
    suffix = _normalizeSuffix(suffix);
    final variants = _generatePermutations(suffix);

    String? bestMatch;
    int maxDigits = -1;

    for (final variant in variants) {
      for (final pattern in _suffixPatterns) {
        if (pattern.hasMatch(variant)) {
          final digitCount = variant.replaceAll(RegExp(r'[^0-9]'), '').length;
          if (digitCount > maxDigits) {
            maxDigits = digitCount;
            bestMatch = variant;
          }
        }
      }
    }

    return bestMatch;
  }

  static String? _validateCandidate(String candidate, Set<String> acronymSet) {
    if (candidate.contains('-')) {
      final parts = candidate.split('-');
      if (parts.length < 2) return null;
      final prefixCandidate = parts.first;
      final suffixCandidate = parts.sublist(1).join('-');
      final validPrefix = _findValidPrefix(prefixCandidate, acronymSet);
      if (validPrefix == null) return null;
      final validSuffix = _findValidSuffix(suffixCandidate);
      if (validSuffix == null) return null;
      return '$validPrefix-$validSuffix';
    } else {
      for (int i = 3; i < candidate.length - 2; i++) {
        final prefixCandidate = candidate.substring(0, i);
        final suffixCandidate = candidate.substring(i);
        final validPrefix = _findValidPrefix(prefixCandidate, acronymSet);
        if (validPrefix != null) {
          final validSuffix = _findValidSuffix(suffixCandidate);
          if (validSuffix != null) {
            return '$validPrefix-$validSuffix';
          }
        }
      }
    }
    return null;
  }

  static Future<String?> extractCardCode(String text) async {
    final acronymSet = await _getAcronymSet();
    if (acronymSet.isEmpty) return null;

    final hyperCleanedText = text.toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9\-]'),
      ' ',
    );

    final candidates = hyperCleanedText
        .split(' ')
        .where((s) => s.length >= 6 && s.length <= 15);

    for (final candidate in candidates) {
      final result = _validateCandidate(candidate, acronymSet);
      if (result != null) return result;
    }

    return null;
  }
}
