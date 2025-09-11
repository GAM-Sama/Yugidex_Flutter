import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/card_model.dart';
import '../view_models/card_list_view_model.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  State<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CardListViewModel>(context, listen: false).fetchCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Colección de Cartas'),
        backgroundColor: Colors.grey[900],
      ),
      body: Consumer<CardListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error al cargar las cartas:\n${viewModel.errorMessage}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => viewModel.fetchCards(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.cards.isEmpty) {
            return const Center(
              child: Text(
                'No tienes ninguna carta en tu colección.\n¡Empieza a escanear para añadir cartas!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ), // Blanco suave para el texto si no hay cartas
              ),
            );
          }

          return Row(
            children: [
              _buildLeftPanel(viewModel.selectedCard),
              const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
              _buildRightPanel(viewModel),
            ],
          );
        },
      ),
    );
  }

  /// Construye el panel izquierdo que muestra la imagen y los detalles.
  Widget _buildLeftPanel(Card? selectedCard) {
    return Expanded(
      flex: 3,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        padding: const EdgeInsets.all(16.0),
        child:
            selectedCard == null
                ? const Center(
                  child: Text(
                    'Selecciona una carta de la lista para ver sus detalles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                    ), // Blanco suave para el texto
                  ),
                )
                : Column(
                  children: [
                    // --- IMAGEN DE LA CARTA SELECCIONADA ---
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child:
                            (selectedCard.imagen == null)
                                ? Image.asset('packcodes/card_placeholder.png')
                                : CachedNetworkImage(
                                  key: ValueKey(selectedCard.idCarta),
                                  imageUrl: selectedCard.imagen!,
                                  fit: BoxFit.contain,
                                  placeholder:
                                      (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ), // Spinner blanco
                                  errorWidget:
                                      (context, url, error) => Image.asset(
                                        'packcodes/card_placeholder.png',
                                      ),
                                ),
                      ),
                    ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Colors.white38,
                    ), // Divisor más sutil
                    // --- DETALLES DE LA CARTA (SCROLLABLE) ---
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCardDetails(selectedCard),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  /// Widget que construye la lista de detalles de la carta seleccionada.
  Widget _buildCardDetails(Card card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- NOMBRE (MÁS GRANDE Y BLANCO) ---
          _buildDetailRow(
            'Nombre:',
            card.nombre,
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            valueStyle: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8), // Espacio entre nombre y el resto

          _buildDetailRow(
            'Código:',
            card.idCarta,
            valueStyle: const TextStyle(color: Colors.white70),
          ),
          if (card.tipo != null)
            _buildDetailRow(
              'Tipo:',
              card.tipo!,
              valueStyle: const TextStyle(color: Colors.white70),
            ),
          if (card.marcoCarta != null)
            _buildDetailRow(
              'Marco:',
              card.marcoCarta!,
              valueStyle: const TextStyle(color: Colors.white70),
            ),
          if (card.subtipo.isNotEmpty)
            _buildDetailRow(
              'Subtipo:',
              card.subtipo.join(' / '),
              valueStyle: const TextStyle(color: Colors.white70),
            ),
          if (card.atributo != null)
            _buildDetailRow(
              'Atributo:',
              card.atributo!,
              valueStyle: const TextStyle(color: Colors.white70),
            ),
          if (card.nivelRankLink != null)
            _buildDetailRow(
              'Nivel/Rango/Link:',
              card.nivelRankLink.toString(),
              valueStyle: const TextStyle(color: Colors.white70),
            ),
          if (card.atk != null)
            _buildDetailRow(
              'ATK/DEF:',
              '${card.atk}/${card.def ?? '?'}',
              valueStyle: const TextStyle(color: Colors.white70),
            ),
          if (card.rareza.isNotEmpty)
            _buildDetailRow(
              'Rareza:',
              card.rareza.join(', '),
              valueStyle: const TextStyle(color: Colors.white70),
            ),
          if (card.setExpansion != null)
            _buildDetailRow(
              'Set:',
              card.setExpansion!,
              valueStyle: const TextStyle(color: Colors.white70),
            ),

          // Bloque de descripción corregido y con estilos blancos
          if (card.descripcion != null && card.descripcion!['es'] != null)
            Padding(
              padding: const EdgeInsets.only(
                top: 16.0,
              ), // Más espacio antes de la descripción
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ), // Espacio entre título y texto de descripción
                  Text(
                    card.descripcion!['es']!.toString(),
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ), // Texto de descripción más pequeño y blanco
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20), // Espacio final
        ],
      ),
    );
  }

  /// Función de ayuda mejorada para no repetir código al crear las filas de detalles.
  Widget _buildDetailRow(
    String label,
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    // Si el valor está vacío, no mostramos la fila
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          // Estilo base para el texto, si no se especifica uno más concreto
          style: const TextStyle(color: Colors.white, fontSize: 14),
          children: [
            TextSpan(
              text: '$label ',
              style:
                  labelStyle ??
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            TextSpan(
              text: value,
              style: valueStyle ?? const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// Panel derecho que muestra la colección con animaciones y el indicador de cantidad.
  Widget _buildRightPanel(CardListViewModel viewModel) {
    const int columnCount = 5;

    return Expanded(
      flex: 5,
      child: AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Fondo negro para rellenar los huecos
                          Container(color: Colors.black),
                          // Imagen de la carta
                          if (card.imagen != null)
                            CachedNetworkImage(
                              imageUrl: card.imagen!,
                              fit: BoxFit.contain,
                              placeholder:
                                  (context, url) =>
                                      Container(color: Colors.grey[800]),
                              errorWidget:
                                  (context, url, error) => Image.asset(
                                    'packcodes/card_placeholder.png',
                                  ),
                            ),
                          // Indicador de cantidad
                          if (card.cantidad > 1)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'x${card.cantidad}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
