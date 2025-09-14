import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/card_model.dart';
import '../view_models/card_list_view_model.dart';

// NUEVO: Importamos la home_screen para poder navegar a ella.
import 'home_screen.dart';

// MODIFICADO: Renombramos la clase y la hacemos Stateful
class NewCardsListScreen extends StatefulWidget {
  // 1. Recibimos el jobId desde la pantalla de progreso
  final String jobId;

  const NewCardsListScreen({super.key, required this.jobId});

  @override
  State<NewCardsListScreen> createState() => _NewCardsListScreenState();
}

class _NewCardsListScreenState extends State<NewCardsListScreen> {
  @override
  void initState() {
    super.initState();
    // 2. Llamamos a un nuevo método en el ViewModel para cargar las cartas por jobId
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CardListViewModel>(
        context,
        listen: false,
      ).fetchCardsByJobId(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // MODIFICADO: Título más apropiado y sin botón de "atrás" automático
        title: const Text('Cartas Recién Añadidas'),
        automaticallyImplyLeading: false, // Ocultamos la flecha de volver
        backgroundColor: Colors.grey[900],
      ),
      // MEJORA: Añadimos un botón flotante para una acción principal clara
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navegamos a la pantalla de inicio, reemplazando la actual.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) =>
                false, // Elimina todas las rutas anteriores
          );
        },
        icon: const Icon(Icons.home),
        label: const Text('Finalizar'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Consumer<CardListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            // ... (la gestión de errores se queda igual)
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          if (viewModel.cards.isEmpty) {
            // MODIFICADO: Mensaje de "vacío" más adecuado al contexto
            return const Center(
              child: Text(
                'No se ha añadido ninguna carta nueva en este lote.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // La estructura de dos paneles se mantiene, ¡es genial!
          return Column(
            children: [
              // MEJORA: Un encabezado que resume el resultado
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '¡Se han añadido ${viewModel.cards.length} cartas nuevas a tu colección!',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.grey, height: 1),
              Expanded(
                child: Row(
                  children: [
                    _buildLeftPanel(viewModel.selectedCard),
                    const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                    _buildRightPanel(viewModel),
                  ],
                ),
              ),
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
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                : Column(
                  children: [
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
                                      ),
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
                    ),
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
          const SizedBox(height: 8),
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
          // ... (resto de los _buildDetailRow)
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Función de ayuda para las filas de detalles.
  Widget _buildDetailRow(
    String label,
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    // ... (Copiado de tu código original)
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
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

  /// Panel derecho que muestra la colección.
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
                          Container(color: Colors.black),
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
