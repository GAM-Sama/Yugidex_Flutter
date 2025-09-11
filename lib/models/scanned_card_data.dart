import 'package:flutter/foundation.dart';

@immutable
class ScannedCardData {
  final String name;
  final String code;

  const ScannedCardData({required this.name, required this.code});

  // Método para convertir nuestro objeto a un mapa (JSON)
  Map<String, dynamic> toJson() {
    return {'name': name, 'code': code};
  }
}
