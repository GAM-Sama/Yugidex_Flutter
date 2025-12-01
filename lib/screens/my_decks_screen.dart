import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'deck_editor_screen.dart';

import '../services/supabase_service.dart';
import '../models/deck_model.dart';
import '../core/theme/app_theme.dart';

class MyDecksScreen extends StatefulWidget {
  const MyDecksScreen({super.key});

  @override
  State<MyDecksScreen> createState() => _MyDecksScreenState();
}

class _MyDecksScreenState extends State<MyDecksScreen> {

  @override
  Widget build(BuildContext context) {
    final supabaseService = Provider.of<SupabaseService>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Decks'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          color: AppColors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Deck>>(
          stream: supabaseService.streamMyDecks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final decks = snapshot.data ?? [];

            return AnimationLimiter(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,      // 5 Columnas
                  childAspectRatio: 1.0,  // Cuadrado perfecto (Evita overflow)
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                // +1 para el botón de crear
                itemCount: decks.length + 1,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 5,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: index == 0
                            // 1. Botón CREAR (Primera posición)
                            ? _AddDeckButton(
                                onTap: () => _createNewDeck(context, supabaseService),
                              )
                            // 2. Mazos (Resto de posiciones)
                            : _DeckBoxCard(
                                deck: decks[index - 1],
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DeckEditorScreen(deckId: decks[index - 1].id),
                                    ),
                                  );
                                  // Si se recibió 'reload', forzar actualización
                                  if (result == 'reload') {
                                    // El StreamBuilder ya detectará los cambios automáticamente
                                    // pero podemos forzar un rebuild si es necesario
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                },
                                onDelete: () => supabaseService.deleteDeck(decks[index - 1].id),
                              ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // --- CREAR NUEVO MAZO DIRECTAMENTE ---
  void _createNewDeck(BuildContext context, SupabaseService service) async {
    try {
      // Generar nombre único automáticamente
      final uniqueName = await service.generateUniqueDeckName();
      
      // Navegar al editor con deckId null (indicando que es nuevo)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeckEditorScreen(deckId: null, deckName: uniqueName),
        ),
      );
      
      // Si se recibió 'reload', forzar actualización
      if (result == 'reload') {
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear deck: $e')),
        );
      }
    }
  }

  // --- DIÁLOGO CREAR MAZO (MANTENIDO POR COMPATIBILIDAD) ---
  void _showCreateDeckDialog(BuildContext context, SupabaseService service) {
    final nameController = TextEditingController();
    final List<Color> deckColors = [
      const Color(0xFFD32F2F), // Rojo
      const Color(0xFF1976D2), // Azul
      const Color(0xFF388E3C), // Verde
      const Color(0xFFF57C00), // Naranja
      const Color(0xFF7B1FA2), // Púrpura
      const Color(0xFF455A64), // Gris
      const Color(0xFF212121), // Negro
      const Color(0xFF5D4037), // Marrón
    ];
    Color selectedColor = deckColors[1];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            scrollable: true,
            title: const Text("Nuevo Mazo"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nombre",
                    hintText: "Ej: Blue-Eyes",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                ),
                const SizedBox(height: 16),
                const Text("Color de caja:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: deckColors.map((color) {
                      final isSelected = selectedColor == color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                              boxShadow: [if(isSelected) const BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await service.createDeck(nameController.text, selectedColor.value);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Crear"),
              ),
            ],
          );
        }
      ),
    );
  }
}

// --- WIDGET 1: BOTÓN AÑADIR ---
class _AddDeckButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddDeckButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Center(
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCCFF00), width: 3),
            ),
            child: const Icon(LucideIcons.plus, color: Color(0xFFCCFF00), size: 30),
          ),
        ),
      ),
    );
  }
}

// --- WIDGET 2: CAJA DE MAZO ---
class _DeckBoxCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeckBoxCard({required this.deck, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final deckColor = Color(deck.color);
    
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: Text("¿Borrar ${deck.name}?"),
          actions: [
            TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("No")),
            TextButton(onPressed: (){
              onDelete();
              Navigator.pop(context);
            }, child: const Text("Sí", style: TextStyle(color: Colors.red))),
          ],
        ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: deckColor,
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [deckColor, deckColor.withOpacity(0.7)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 3)),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Stack(
          children: [
            // Placeholder Icono
            Center(
              child: Icon(
                LucideIcons.sword, 
                size: 40,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            // Información
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    deck.name,
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${deck.cardCount}",
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Efecto Tapa
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}