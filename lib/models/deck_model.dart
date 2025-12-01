class Deck {
  final String id;
  final String name;
  final String userId;
  final int color;
  final int cardCount;
  final DateTime updatedAt;
  
  // 🔥 NUEVO: Las listas de contenido
  final List<DeckItem> mainDeckList;
  final List<DeckItem> extraDeckList;
  final List<DeckItem> sideDeckList;

  Deck({
    required this.id,
    required this.name,
    required this.userId,
    required this.color,
    required this.cardCount,
    required this.updatedAt,
    required this.mainDeckList,
    required this.extraDeckList,
    required this.sideDeckList,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    // Helper para convertir el JSONB en lista de objetos Dart
    List<DeckItem> parseList(dynamic list) {
      if (list is List) {
        return list.map((x) => DeckItem.fromJson(x)).toList();
      }
      return [];
    }

    final main = parseList(json['main_deck']);
    final extra = parseList(json['extra_deck']);
    final side = parseList(json['side_deck']);

    // Helper para contar total
    int countTotal(List<DeckItem> list) => list.fold(0, (sum, item) => sum + item.quantity);

    return Deck(
      id: json['id'],
      name: json['name'] ?? 'Sin Nombre',
      userId: json['user_id'] ?? '',
      color: json['color'] != null ? (json['color'] as num).toInt() : 0xFF455A64,
      cardCount: countTotal(main) + countTotal(extra) + countTotal(side),
      updatedAt: DateTime.parse(json['updated_at']),
      mainDeckList: main,
      extraDeckList: extra,
      sideDeckList: side,
    );
  }
}

// Clase sencilla para guardar { "card_id": "LOB-001", "quantity": 3 }
class DeckItem {
  final String cardId;
  final int quantity;

  DeckItem({required this.cardId, required this.quantity});

  factory DeckItem.fromJson(Map<String, dynamic> json) {
    return DeckItem(
      cardId: json['card_id'] ?? '',
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'card_id': cardId,
    'quantity': quantity,
  };
}