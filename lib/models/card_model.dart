import 'dart:convert'; // Necesario para decodificar JSON
import 'package:flutter/foundation.dart';

@immutable
class Card {
  // ... (las propiedades de la clase no cambian)
  final String idCarta;
  final int cantidad;
  final String nombre;
  final String? imagen;
  final String? marcoCarta;
  final String? tipo;
  final List<String> subtipo;
  final String? atributo;
  final Map<String, dynamic>? descripcion;
  final String? atk;
  final String? def;
  final int? nivelRankLink;
  final List<String> rareza;
  final String? setExpansion;
  final String? iconoCarta;

  const Card({
    required this.idCarta,
    required this.cantidad,
    required this.nombre,
    this.imagen,
    this.marcoCarta,
    this.tipo,
    required this.subtipo,
    this.atributo,
    this.descripcion,
    this.atk,
    this.def,
    this.nivelRankLink,
    required this.rareza,
    this.setExpansion,
    this.iconoCarta,
  });

  /// Este constructor ahora es "a prueba de balas" contra errores de tipo.
  factory Card.fromJson(Map<String, dynamic> json) {
    // --- NUEVA FUNCIÓN DE AYUDA SÚPER SEGURA ---
    // Parsea un campo que debería ser un Mapa, pero podría venir como String.
    Map<String, dynamic>? _parseJsonMap(dynamic value) {
      if (value is Map) {
        // Si ya es un Mapa, perfecto.
        return Map<String, dynamic>.from(value);
      }
      if (value is String) {
        // Si es un String, intentamos decodificarlo como JSON.
        try {
          return jsonDecode(value) as Map<String, dynamic>;
        } catch (e) {
          return null; // Si no es un JSON válido, devolvemos null.
        }
      }
      return null;
    }

    List<String> _splitString(dynamic value, String separator) {
      if (value is List) return value.map((item) => item.toString()).toList();
      if (value is String)
        return value.split(separator).map((item) => item.trim()).toList();
      return [];
    }

    return Card(
      idCarta: json['ID_Carta']?.toString() ?? '',
      cantidad: json['Cantidad'] as int? ?? 0,
      nombre: json['Nombre'] as String? ?? 'Sin Nombre',
      imagen: json['Imagen'] as String?,
      marcoCarta: json['Marco_Carta'] as String?,
      tipo: json['Tipo'] as String?,
      subtipo: _splitString(json['Subtipo'], '/'),
      atributo: json['Atributo'] as String?,

      // Usamos nuestra nueva función segura para parsear la descripción.
      descripcion: _parseJsonMap(json['Descripcion']),

      atk: json['ATK']?.toString(),
      def: json['DEF']?.toString(),
      nivelRankLink: json['Nivel_Rank_Link'] as int?,
      rareza: _splitString(json['Rareza'], ','),
      setExpansion: json['Set_Expansion'] as String?,
      iconoCarta: json['Icono Carta'] as String?,
    );
  }
}
