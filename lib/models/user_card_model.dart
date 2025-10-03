import 'card_model.dart'; // Importamos tu modelo de carta existente.

/// Representa una carta dentro de la colección de un usuario.
/// Contiene tanto los datos de la carta en sí (desde la tabla 'Cartas')
/// como los metadatos de la colección del usuario (desde 'user_cards').
class UserCard {
  final String userCardId; // El UUID de la entrada en la tabla 'user_cards'
  final int quantity;
  final String condition;
  final String? notes;
  final DateTime? acquiredDate;
  final Card cardDetails; // Objeto anidado con todos los detalles de la carta.

  UserCard({
    required this.userCardId,
    required this.quantity,
    required this.condition,
    this.notes,
    this.acquiredDate,
    required this.cardDetails,
  });

  /// Factory constructor para crear una instancia de UserCard desde un JSON.
  /// Este JSON es el resultado de la consulta con JOIN que hicimos en SupabaseService.
  factory UserCard.fromJson(Map<String, dynamic> json) {
    // El JSON tiene esta estructura:
    // {
    //   "id": "...",
    //   "cantidad": 1,
    //   "condition": "mint",
    //   "notes": null,
    //   "acquired_date": "...",
    //   "Cartas": { ...objeto completo de la carta... }
    // }
    return UserCard(
      userCardId: json['id'] as String,
      quantity: json['cantidad'] as int,
      condition: json['condition'] as String,
      notes: json['notes'] as String?,
      acquiredDate: json['acquired_date'] != null
          ? DateTime.parse(json['acquired_date'] as String)
          : null,
      // Aquí está la magia: usamos el fromJson de tu modelo Card existente
      // para parsear el objeto anidado 'Cartas'.
      cardDetails: Card.fromJson(json['Cartas'] as Map<String, dynamic>),
    );
  }
}
