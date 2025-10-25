import 'card_model.dart'; // Import your existing Card model.

// --- Added Typedef ---
/// Helper for copyWith to allow explicitly setting fields to null.
/// Usage: copyWith(notes: () => null)
typedef ValueGetter<T> = T Function();

/// Represents a card within a user's collection.
/// Contains both the card details (from 'Cartas')
/// and the user's collection metadata (from 'user_cards').
class UserCard {
  // --- Marked properties as final ---
  final String userCardId; // The UUID from the 'user_cards' table entry
  final int quantity;
  final String condition;
  final String? notes;
  final DateTime? acquiredDate;
  final Card cardDetails; // Nested object with all card details.

  // --- Made constructor const ---
  const UserCard({
    required this.userCardId,
    required this.quantity,
    required this.condition,
    this.notes,
    this.acquiredDate,
    required this.cardDetails,
  });

  /// Factory constructor to create a UserCard instance from JSON.
  /// This JSON is the result of the JOIN query in SupabaseService.
  factory UserCard.fromJson(Map<String, dynamic> json) {
    // Basic validation
    if (json['id'] == null) {
      throw Exception('Field id is required in UserCard');
    }
    if (json['Cartas'] == null || json['Cartas'] is! Map<String, dynamic>) {
       print('❌ Field "Cartas" is null or not a map in UserCard.fromJson');
       print('❌ Received data: $json');
       // Handle this case - maybe throw, maybe return a default Card?
       // Throwing is often better to catch data integrity issues early.
       throw Exception('Field "Cartas" is missing or invalid in UserCard data');
    }


    try {
      return UserCard(
        userCardId: json['id']?.toString() ?? '',
        quantity: json['cantidad'] as int? ?? 1,
        condition: json['condition']?.toString() ?? 'mint',
        notes: json['notes']?.toString(),
        acquiredDate: json['acquired_date'] != null
            ? DateTime.tryParse(json['acquired_date'].toString())
            : null,
        // Use the Card.fromJson factory for the nested 'Cartas' object.
        cardDetails: Card.fromJson(json['Cartas'] as Map<String, dynamic>),
      );
    } catch (e) {
       print('❌ Error during UserCard.fromJson parsing: $e');
       print('❌ Problematic JSON: $json');
       // Rethrow or handle error appropriately
       rethrow;
    }
  }

  // --- Added copyWith method ---
  UserCard copyWith({
    String? userCardId,
    int? quantity,
    String? condition,
    ValueGetter<String?>? notes, // Use ValueGetter to allow setting null
    ValueGetter<DateTime?>? acquiredDate, // Use ValueGetter to allow setting null
    Card? cardDetails,
  }) {
    return UserCard(
      userCardId: userCardId ?? this.userCardId,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      // If notes() is provided, use its result (which could be null), otherwise keep the current notes
      notes: notes != null ? notes() : this.notes,
      // If acquiredDate() is provided, use its result, otherwise keep the current date
      acquiredDate: acquiredDate != null ? acquiredDate() : this.acquiredDate,
      cardDetails: cardDetails ?? this.cardDetails,
    );
  }
}