// lib/models/card_filters.dart (or your path)

// --- ENUM DEFINITIONS ---
enum SortBy { name, cardType, atk, def, level, rank, link, pendulum }
enum SortDirection { asc, desc }

// Helper typedef for copyWith nullability
typedef ValueGetter<T> = T Function();

class CardFilters {
  final String search;
  final List<String> cardTypes;
  final List<String> attributes;
  final List<String> monsterTypes;
  final List<String> spellTrapIcons;
  final List<String> subtypes;
  final String? minAtk;
  final String? minDef;

  // Constructor constante
  const CardFilters({
    this.search = '',
    this.cardTypes = const [],
    this.attributes = const [],
    this.monsterTypes = const [],
    this.spellTrapIcons = const [],
    this.subtypes = const [],
    this.minAtk,
    this.minDef,
  });

  // --- copyWith MEJORADO ---
  CardFilters copyWith({
    String? search,
    List<String>? cardTypes,
    List<String>? attributes,
    List<String>? monsterTypes,
    List<String>? spellTrapIcons,
    List<String>? subtypes,
    ValueGetter<String?>? minAtk, // <-- Usa ValueGetter
    ValueGetter<String?>? minDef, // <-- Usa ValueGetter
  }) {
    return CardFilters(
      search: search ?? this.search,
      cardTypes: cardTypes ?? this.cardTypes,
      attributes: attributes ?? this.attributes,
      monsterTypes: monsterTypes ?? this.monsterTypes,
      spellTrapIcons: spellTrapIcons ?? this.spellTrapIcons,
      subtypes: subtypes ?? this.subtypes,
      // Allows passing null explicitly: copyWith(minAtk: () => null)
      minAtk: minAtk != null ? minAtk() : this.minAtk,
      minDef: minDef != null ? minDef() : this.minDef,
    );
  }

  // --- MÉTODO clear() ELIMINADO ---
}