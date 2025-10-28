// lib/models/card_model.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

@immutable
class Card {
  final String idCarta;
  final int cantidad; // Aunque este modelo es de 'Card', mantenemos 'cantidad' por si viene en el JSON base
  final String? nombre;
  final String? imagen;
  final String? marcoCarta;
  final String? tipo;
  final List<String>? subtipo;
  final String? atributo;
  final String? clasificacion; // <-- ¡AÑADIDO AQUÍ!
  final Map<String, dynamic>? descripcion;
  final String? atk;
  final String? def;
  final int? nivelRankLink;
  final int? ratioEnlace;
  final int? escalaPendulo;
  final List<String>? rareza;
  final String? setExpansion;
  final String? iconoCarta;

  const Card({
    required this.idCarta,
    required this.cantidad,
    this.nombre,
    this.imagen,
    this.marcoCarta,
    this.tipo,
    this.subtipo,
    this.atributo,
    this.clasificacion, // <-- ¡AÑADIDO AQUÍ!
    this.descripcion,
    this.atk,
    this.def,
    this.nivelRankLink,
    this.ratioEnlace,
    this.escalaPendulo,
    this.rareza,
    this.setExpansion,
    this.iconoCarta,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    // Función auxiliar para convertir valores a string de manera segura
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) return value.isNotEmpty ? value.first.toString() : null;
      return value.toString();
    }

    // Función auxiliar para convertir valores a int de manera segura
    int? safeInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Función auxiliar para convertir listas de manera segura
    List<String>? safeStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) return value.map((item) => item.toString()).toList();
      if (value is String) return value.split(',').map((item) => item.trim()).toList();
      return [value.toString()];
    }

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

    final card = Card(
      idCarta: json['ID_Carta']?.toString() ?? '',
      // Mantenemos cantidad aquí por si el JSON base lo incluye, aunque UserCard lo sobrescribirá
      cantidad: json['Cantidad'] as int? ?? 1, 
      nombre: safeString(json['Nombre']) ?? safeString(json['nombre']),
      imagen: safeString(json['Imagen']) ?? safeString(json['imagen']),
      marcoCarta: safeString(json['Marco_Carta']) ?? safeString(json['marco_carta']),
      tipo: safeString(json['Tipo']) ?? safeString(json['tipo']),
      subtipo: safeStringList(json['Subtipo']) ?? safeStringList(json['subtipo']),
      atributo: safeString(json['Atributo']) ?? safeString(json['atributo']),
      // --- ¡AÑADIDO AQUÍ! ---
      // Leemos 'Clasificacion' o 'clasificacion'
      clasificacion: safeString(json['Clasificacion']) ?? safeString(json['clasificacion']),
      // --- FIN DEL AÑADIDO ---
      descripcion: parseJsonMap(json['Descripcion']) ?? parseJsonMap(json['descripcion']) ??
                       (json['Descripcion'] != null ? {'texto': json['Descripcion'].toString()} : null),
      atk: safeString(json['ATK']) ?? safeString(json['atk']),
      def: safeString(json['DEF']) ?? safeString(json['def']),
      nivelRankLink: safeInt(json['Nivel_Rank_Link']) ?? safeInt(json['nivel_rank_link']) ?? safeInt(json['Nivel']) ?? safeInt(json['nivel']),
      ratioEnlace: safeInt(json['ratio_enlace']) ?? safeInt(json['Ratio_Enlace']),
      escalaPendulo: safeInt(json['escala_pendulo']) ?? safeInt(json['Escala_Pendulo']),
      rareza: safeStringList(json['Rareza']) ?? safeStringList(json['rareza']),
      setExpansion: safeString(json['Set_Expansion']) ?? safeString(json['set_expansion']),
      iconoCarta: safeString(json['Icono Carta']) ?? safeString(json['icono_carta']) ?? safeString(json['IconoCarta']),
    );

    return card;
  }
}