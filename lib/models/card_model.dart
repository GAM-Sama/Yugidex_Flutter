import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class Card {
  final String idCarta;
  final int cantidad;
  final String? nombre; // MODIFICADO: Ahora puede ser nulo
  final String? imagen;
  final String? marcoCarta;
  final String? tipo;
  final List<String>? subtipo; // MODIFICADO: Ahora puede ser nulo
  final String? atributo;
  final Map<String, dynamic>? descripcion;
  final String? atk;
  final String? def;
  final int? nivelRankLink;
  final List<String>? rareza; // MODIFICADO: Ahora puede ser nulo
  final String? setExpansion;
  final String? iconoCarta;

  const Card({
    required this.idCarta,
    required this.cantidad,
    this.nombre, // MODIFICADO: Ya no es 'required'
    this.imagen,
    this.marcoCarta,
    this.tipo,
    this.subtipo, // MODIFICADO: Ya no es 'required'
    this.atributo,
    this.descripcion,
    this.atk,
    this.def,
    this.nivelRankLink,
    this.rareza, // MODIFICADO: Ya no es 'required'
    this.setExpansion,
    this.iconoCarta,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    // Las funciones de ayuda se mantienen, ¡son muy útiles!
    Map<String, dynamic>? parseJsonMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String) {
        try {
          return jsonDecode(value) as Map<String, dynamic>;
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    List<String> splitString(dynamic value, String separator) {
      if (value is List) return value.map((item) => item.toString()).toList();
      if (value is String) {
        return value.split(separator).map((item) => item.trim()).toList();
      }
      return [];
    }

    return Card(
      idCarta: json['ID_Carta']?.toString() ?? '',
      cantidad:
          json['Cantidad'] as int? ?? 1, // Asumimos 1 si no viene cantidad
      // MODIFICADO: Eliminamos el valor por defecto 'Sin Nombre'.
      // Si json['Nombre'] es nulo, this.nombre será nulo. ¡Justo lo que necesitamos!
      nombre: json['Nombre'] as String?,

      imagen: json['Imagen'] as String?,
      marcoCarta: json['Marco_Carta'] as String?,
      tipo: json['Tipo'] as String?,

      // MODIFICADO: Comprobamos si el campo existe antes de procesarlo
      subtipo:
          json['Subtipo'] != null ? splitString(json['Subtipo'], '/') : null,

      atributo: json['Atributo'] as String?,
      descripcion: parseJsonMap(json['Descripcion']),
      atk: json['ATK']?.toString(),
      def: json['DEF']?.toString(),
      nivelRankLink: json['Nivel_Rank_Link'] as int?,

      // MODIFICADO: Comprobamos si el campo existe antes de procesarlo
      rareza: json['Rareza'] != null ? splitString(json['Rareza'], ',') : null,

      setExpansion: json['Set_Expansion'] as String?,
      iconoCarta: json['Icono Carta'] as String?,
    );
  }
}
