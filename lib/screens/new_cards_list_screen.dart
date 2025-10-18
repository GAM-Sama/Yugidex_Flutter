import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../core/theme/app_theme.dart';
import '../models/card_model.dart';
import '../services/supabase_service.dart';
import '../view_models/processed_cards_view_model.dart';

// Clase auxiliar para devolver un par de colores (fondo y texto)
class CardFrameColors {
  final Color backgroundColor;
  final Color textColor;
  CardFrameColors(this.backgroundColor, this.textColor);
}

class NewCardsListScreen extends StatefulWidget {
  final String jobId;

  const NewCardsListScreen({super.key, required this.jobId});

  @override
  State<NewCardsListScreen> createState() => _NewCardsListScreenState();
}

class _NewCardsListScreenState extends State<NewCardsListScreen> {
  @override
  void initState() {
    super.initState();
    print('🔥 NewCardsListScreen initState - jobId: ${widget.jobId}');

    // Inicializar inmediatamente después de que el widget se monte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewModel();
    });
  }

  void _initializeViewModel() async {
    print('🔥 NewCardsListScreen - _initializeViewModel iniciado');

    try {
      final viewModel = Provider.of<ProcessedCardsViewModel>(
        context,
        listen: false,
      );
      print('🔥 NewCardsListScreen - Provider obtenido: ${viewModel.runtimeType}');
      print('🔥 NewCardsListScreen - Estado inicial del ViewModel:');
      print('   - isLoading: ${viewModel.isLoading}');
      print('   - cards.length: ${viewModel.cards.length}');

      final supabaseService = Provider.of<SupabaseService>(context, listen: false);
      viewModel.initialize(supabaseService);
      print('🔥 NewCardsListScreen - ViewModel inicializado');

      // El estado ya debería estar en loading desde el constructor
      print('🔥 NewCardsListScreen - Estado después de inicializar:');
      print('   - isLoading: ${viewModel.isLoading}');

      await viewModel.fetchCardsByJobId(widget.jobId);
      print('🔥 NewCardsListScreen - fetchCardsByJobId completado');

    } catch (e) {
      print('❌ NewCardsListScreen - Error en inicialización: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- FUNCIÓN PARA OBTENER LOS COLORES DE LA CARTA ---
  CardFrameColors _getCardFrameColors(Card card) {
    // Primero intentar usar marcoCarta para determinar el tipo
    String? cardType;
    if (card.marcoCarta != null) {
      final marcoLower = card.marcoCarta!.toLowerCase();
      if (marcoLower.contains('monstruo') || marcoLower.contains('monster')) {
        cardType = 'monstruo';
      } else if (marcoLower.contains('magia') || marcoLower.contains('spell')) {
        cardType = 'magia';
      } else if (marcoLower.contains('trampa') || marcoLower.contains('trap')) {
        cardType = 'trampa';
      }
    }

    // Si no tenemos marcoCarta o no coincide, usar el tipo como fallback
    if (cardType == null && card.tipo != null) {
      final tipoLower = card.tipo!.toLowerCase();
      if (tipoLower.contains('monstruo') || tipoLower.contains('monster')) {
        cardType = 'monstruo';
      } else if (tipoLower.contains('magia') || tipoLower.contains('spell')) {
        cardType = 'magia';
      } else if (tipoLower.contains('trampa') || tipoLower.contains('trap')) {
        cardType = 'trampa';
      }
    }

    // Primero, buscamos en los subtipos, que son más específicos (Fusion, Xyz, etc.)
    final subtypes = (card.subtipo ?? []).map((s) => s.toLowerCase()).toList();

    // Prioridad para monstruos de efecto y normales si están en subtipos
    if (subtypes.contains('normal')) return CardFrameColors(const Color(0xFFFDE68A), Colors.black); // Amarillo
    if (subtypes.contains('efecto') || subtypes.contains('effect')) return CardFrameColors(const Color(0xFFC07B41), Colors.white); // Marrón anaranjado

    // Resto de subtipos
    for (var subtype in subtypes) {
      switch (subtype) {
        case 'fusión':
        case 'fusion':
          return CardFrameColors(const Color(0xFFA086B7), Colors.white); // Lila
        case 'xyz':
          return CardFrameColors(const Color(0xFF222222), Colors.white); // Negro
        case 'sincronía':
        case 'synchro':
          return CardFrameColors(const Color(0xFFF0F0F0), Colors.black); // Blanco
        case 'link':
          return CardFrameColors(const Color(0xFF0077CC), Colors.white); // Azul oscuro
        case 'ritual':
          return CardFrameColors(const Color(0xFF9DB5CC), Colors.white); // Azul claro
      }
    }

    // Si no se encuentra un subtipo de monstruo, usamos el tipo principal (Magia, Trampa, Monstruo)
    switch (cardType) {
      case 'magia':
      case 'spell':
      case 'spell card':
      case 'magic':
        return CardFrameColors(const Color(0xFF1D9E74), Colors.white); // Verde
      case 'trampa':
      case 'trap':
      case 'trap card':
        return CardFrameColors(const Color(0xFFBC5A84), Colors.white); // Rosáceo
      case 'monstruo':
      case 'monster':
        // Para monstruos sin subtipo específico, usar color genérico
        return CardFrameColors(const Color(0xFF6B5B95), Colors.white); // Púrpura genérico
    }

    // Color por defecto si no coincide nada
    return CardFrameColors(Colors.grey.shade700, Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ProcessedCardsViewModel>(
          builder: (context, viewModel, child) {
            print('🔥 NewCardsListScreen - BUILD llamado - Estado: Loading=${viewModel.isLoading}, Cartas=${viewModel.cards.length}, Error=${viewModel.errorMessage != null}');

            if (viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando cartas procesadas...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.errorMessage != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar resultados',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (viewModel.cards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No se procesaron cartas',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No se pudo procesar ninguna carta válida',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                _buildLeftPanel(viewModel.selectedCard),
                Container(width: 1, color: AppColors.surface),
                _buildRightPanel(viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeftPanel(Card? selectedCard) {
    return Expanded(
      flex: 3,
      child: Container(
        color: AppColors.cardBackground,
        padding: const EdgeInsets.all(16.0),
        child: selectedCard == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona una carta procesada',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Haz clic en una carta de la derecha para ver sus detalles',
                      style: TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCard.nombre ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTagsSection(selectedCard),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 150, maxHeight: 208),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: selectedCard.imagen != null
                            ? CachedNetworkImage(
                                imageUrl: selectedCard.imagen ?? '',
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Container(color: AppColors.surface),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
                              )
                            : Container(color: AppColors.surface),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCardSpecificDetails(selectedCard),
                    const SizedBox(height: 16),
                    // Set de expansión - SIEMPRE visible
                    if (selectedCard.setExpansion != null && selectedCard.setExpansion!.isNotEmpty && selectedCard.setExpansion != 'null')
                      _buildDetailRow('Set:', selectedCard.setExpansion),
                    const SizedBox(height: 16),
                    // Descripción - SIEMPRE visible abajo del todo
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descripción:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getDescriptionText(selectedCard.descripcion),
                          softWrap: true,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRightPanel(ProcessedCardsViewModel viewModel) {
    const int columnCount = 6;
    return Expanded(
      flex: 5,
      child: Column(
        children: [
          // Header con texto de cartas añadidas
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Volver',
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        () {
                          final totalCards = viewModel.cards.length;
                          final failedCards = viewModel.cards.where((card) => card.nombre == null || card.nombre!.isEmpty || card.nombre == 'null').length;
                          final successfulCards = totalCards - failedCards;

                          if (failedCards > 0) {
                            return 'Cartas que se han añadido ($successfulCards de $totalCards)';
                          } else {
                            return 'Cartas que se han añadido ($totalCards)';
                          }
                        }(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.sort, color: AppColors.textPrimary),
                  onPressed: _showSortDialog,
                  tooltip: 'Ordenar',
                ),
                IconButton(
                  icon: Icon(Icons.filter_list, color: AppColors.textPrimary),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filtros',
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimationLimiter(
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: viewModel.cards.length,
                itemBuilder: (context, index) {
                  final card = viewModel.cards[index];
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: columnCount,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () => viewModel.selectCard(card),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: viewModel.selectedCard?.idCarta == card.idCarta
                                    ? AppColors.accent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: CachedNetworkImage(
                                imageUrl: card.imagen ?? '',
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(color: AppColors.surface),
                                errorWidget: (c, u, e) => const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(Card card) {
    final colors = _getCardFrameColors(card);
    List<Widget> tags = [];

    // Usar marcoCarta para determinar el tipo principal (para colores y lógica)
    String? cardTypeForColors;
    if (card.marcoCarta != null) {
      final marcoLower = card.marcoCarta!.toLowerCase();
      if (marcoLower.contains('monstruo') || marcoLower.contains('monster')) {
        cardTypeForColors = 'monstruo';
      } else if (marcoLower.contains('magia') || marcoLower.contains('spell')) {
        cardTypeForColors = 'magia';
      } else if (marcoLower.contains('trampa') || marcoLower.contains('trap')) {
        cardTypeForColors = 'trampa';
      }
    }

    // Si no tenemos marcoCarta o no coincide, usar el tipo como fallback para colores
    if (cardTypeForColors == null && card.tipo != null) {
      final tipoLower = card.tipo!.toLowerCase();
      if (tipoLower.contains('monstruo') || tipoLower.contains('monster')) {
        cardTypeForColors = 'monstruo';
      } else if (tipoLower.contains('magia') || tipoLower.contains('spell')) {
        cardTypeForColors = 'magia';
      } else if (tipoLower.contains('trampa') || tipoLower.contains('trap')) {
        cardTypeForColors = 'trampa';
      }
    }

    // Mostrar el tipo específico (Machine, Dragon, etc.) SIEMPRE si existe
    if (card.tipo != null && card.tipo!.isNotEmpty && card.tipo != 'null') {
      tags.add(_buildTag(card.tipo!, colors.backgroundColor, colors.textColor));
    }

    // Mostrar el marco de carta (Monster, Magia, Trampa) SIEMPRE si existe
    if (card.marcoCarta != null && card.marcoCarta!.isNotEmpty && card.marcoCarta != 'null') {
      final marcoLower = card.marcoCarta!.toLowerCase();
      String marcoDisplay;

      if (marcoLower.contains('monstruo') || marcoLower.contains('monster')) {
        marcoDisplay = 'Monstruo';
      } else if (marcoLower.contains('magia') || marcoLower.contains('spell')) {
        marcoDisplay = 'Magia';
      } else if (marcoLower.contains('trampa') || marcoLower.contains('trap')) {
        marcoDisplay = 'Trampa';
      } else {
        marcoDisplay = card.marcoCarta!;
      }

      tags.add(_buildTag(marcoDisplay, colors.backgroundColor, colors.textColor));
    }

    // Mostrar los subtipos/iconos SIEMPRE junto con el tipo
    if (card.subtipo != null) {
      for (var s in card.subtipo!) {
        if (s.isNotEmpty) {
          tags.add(_buildTag(s, colors.backgroundColor, colors.textColor));
        }
      }
    }

    // Si no hay subtipos pero hay iconoCarta, mostrarlo
    if ((card.subtipo == null || card.subtipo!.isEmpty) && card.iconoCarta != null && card.iconoCarta!.isNotEmpty && card.iconoCarta != 'null') {
      tags.add(_buildTag(card.iconoCarta!, colors.backgroundColor, colors.textColor));
    }

    // La rareza tiene un estilo neutral diferente y llamativo
    if (card.rareza != null) {
      for (var r in card.rareza!) {
        if (r.isNotEmpty && r != 'null') tags.add(_buildTag(r, Colors.grey.shade800, Colors.yellow.shade200));
      }
    }

    return Wrap(spacing: 6.0, runSpacing: 6.0, children: tags);
  }

  Widget _buildTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.5), width: 1),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            TextSpan(text: value, style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // --- FUNCIÓN CORREGIDA ---
  // =M======================================================================

  Widget _buildCardSpecificDetails(Card card) {
    // --- LA CORRECCIÓN ESTÁ AQUÍ ---
    // Usamos marcoCarta para saber la categoría principal de la carta
    final marcoLower = card.marcoCarta?.toLowerCase() ?? '';
    final isMonster = marcoLower.contains('monstruo') || marcoLower.contains('monster');
    final isMagic = marcoLower.contains('magia') || marcoLower.contains('spell');
    final isTrap = marcoLower.contains('trampa') || marcoLower.contains('trap');
    // --- FIN DE LA CORRECCIÓN ---

    if (isMonster) {
      // Esta lógica interna ya estaba bien.
      // Ahora sí se ejecutará para todos los monstruos.
      final hasXyzSubtypes = card.subtipo?.any((subtype) =>
          subtype.toLowerCase().contains('xyz') ||
          subtype.toLowerCase().contains('xiez')) ?? false;

      final hasLinkSubtypes = card.subtipo?.any((subtype) =>
          subtype.toLowerCase().contains('link')) ?? false;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Atributo:', card.atributo),
                // Mostrar Nivel, Rango o Link según el tipo
                if (hasLinkSubtypes && card.nivelRankLink != null)
                  _buildDetailRow('Link:', card.nivelRankLink?.toString())
                else if (hasXyzSubtypes && card.nivelRankLink != null)
                  _buildDetailRow('Rango:', card.nivelRankLink?.toString())
                else if (card.nivelRankLink != null)
                  _buildDetailRow('Nivel:', card.nivelRankLink?.toString()),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar ATK/DEF solo si existe alguno de los dos
                if (card.atk != null || card.def != null)
                  _buildDetailRow(
                    'ATK/DEF:',
                    // Para monstruos Link, la defensa es nula, así que mostramos '-'
                    hasLinkSubtypes 
                      ? '${card.atk ?? '?'}/-' 
                      : '${card.atk ?? '?'}/${card.def ?? '?'}',
                  ),
              ],
            ),
          ),
        ],
      );
    } else if (isMagic || isTrap) {
      // Para magia y trampa no hay detalles específicos que mostrar aquí
      return const SizedBox.shrink();
    } else {
      // Fallback por si acaso
      return const SizedBox.shrink();
    }
  }
  
  // =======================================================================
  // --- FIN DE LA FUNCIÓN CORREGIDA ---
  // =======================================================================

  String _getDescriptionText(Map<String, dynamic>? descripcion) {
    // Si descripción es null, retornar mensaje estándar
    if (descripcion == null || descripcion.isEmpty) {
      return 'Descripción no disponible';
    }

    // Si es un mapa con clave 'texto', devolver ese valor directamente
    if (descripcion.containsKey('texto') && descripcion['texto'] != null) {
      return descripcion['texto'].toString();
    }

    // Intentar diferentes formatos comunes de descripción
    String? extractDescription() {
      // Formato directo: {'es': 'texto', 'en': 'texto'}
      if (descripcion.containsKey('es') && descripcion['es'] != null) {
        return descripcion['es'].toString();
      }
      if (descripcion.containsKey('ES') && descripcion['ES'] != null) {
        return descripcion['ES'].toString();
      }
      if (descripcion.containsKey('en') && descripcion['en'] != null) {
        return descripcion['en'].toString();
      }
      if (descripcion.containsKey('EN') && descripcion['EN'] != null) {
        return descripcion['EN'].toString();
      }

      // Si no hay claves estándar, tomar cualquier valor no vacío
      for (var value in descripcion.values) {
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }

      return null;
    }

    final description = extractDescription();
    return description ?? 'Descripción no disponible';
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ordenar por'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Nombre (A-Z)'),
                leading: Radio<String>(
                  value: 'name_asc',
                  groupValue: 'name_asc',
                  onChanged: (value) {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ListTile(
                title: const Text('Nombre (Z-A)'),
                leading: Radio<String>(
                  value: 'name_desc',
                  groupValue: 'name_asc',
                  onChanged: (value) {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtros'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Éxito'),
                leading: Checkbox(
                  value: true,
                  onChanged: (value) {},
                ),
              ),
              ListTile(
                title: const Text('Fallo'),
                leading: Checkbox(
                  value: false,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aplicar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}