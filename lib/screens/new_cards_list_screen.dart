import 'package:flutter/material.dart' hide Card;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/card_model.dart';
import '../view_models/card_list_view_model.dart';
import 'home_screen.dart';

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
        title: const Text('Resultados del Escaneo'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[900],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
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
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          if (viewModel.cards.isEmpty) {
            return const Center(
              child: Text(
                'No se ha añadido ninguna carta en este lote.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          // --- MEJORA: CONTADOR INTELIGENTE ---
          final successCount =
              viewModel.cards.where((c) => c.nombre != null).length;
          final failureCount = viewModel.cards.length - successCount;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Roboto',
                    ), // Asegura una fuente consistente
                    children: [
                      const TextSpan(text: 'Proceso finalizado: '),
                      TextSpan(
                        text: '$successCount cartas añadidas',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (failureCount > 0)
                        TextSpan(
                          text: ' y $failureCount códigos no encontrados.',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const TextSpan(text: '.'),
                    ],
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

  // MODIFICADO: Ahora el panel izquierdo también sabe mostrar un error
  Widget _buildLeftPanel(Card? selectedCard) {
    Widget content;

    if (selectedCard == null) {
      content = const Center(
        child: Text(
          'Selecciona una carta de la lista',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      );
    } else if (selectedCard.nombre == null) {
      // Si la carta seleccionada es una fallida, mostramos un mensaje de error claro
      content = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            const Text(
              "No se encontraron datos para el código:",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              selectedCard.idCarta,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Si es una carta válida, mostramos los detalles como antes
      content = Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: CachedNetworkImage(
                key: ValueKey(selectedCard.idCarta),
                imageUrl: selectedCard.imagen ?? '',
                fit: BoxFit.contain,
                placeholder:
                    (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                errorWidget:
                    (context, url, error) =>
                        Image.asset('packcodes/card_placeholder.png'),
              ),
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Colors.white38),
          Expanded(
            child: SingleChildScrollView(
              child: _buildCardDetails(selectedCard),
            ),
          ),
        ],
      );
    }

    return Expanded(
      flex: 3,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }

  // MODIFICADO: El GridView ahora diferencia entre éxito y fallo
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

            Widget cardWidget;
            // --- LA LÓGICA CLAVE ESTÁ AQUÍ ---
            if (card.nombre == null) {
              // Si no tiene nombre, es una carta fallida
              cardWidget = FailedCardPlaceholder(cardCode: card.idCarta);
            } else {
              // Si tiene nombre, es una carta válida
              cardWidget = ClipRRect(
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
                            (context, url, error) =>
                                Image.asset('packcodes/card_placeholder.png'),
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
              );
            }

            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: columnCount,
              child: ScaleAnimation(
                child: FadeInAnimation(
                  child: GestureDetector(
                    onTap: () => viewModel.selectCard(card),
                    child: cardWidget,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- VERSIÓN DEFINITIVA Y ROBUSTA DE LAS FUNCIONES DE AYUDA ---

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
          _buildDetailRow('Código:', card.idCarta),
          _buildDetailRow('Tipo:', card.tipo),
          _buildDetailRow('Marco:', card.marcoCarta),
          _buildDetailRow('Subtipo:', card.subtipo?.join(' / ')),
          _buildDetailRow('Atributo:', card.atributo),
          _buildDetailRow('Nivel/Rango/Link:', card.nivelRankLink?.toString()),
          _buildDetailRow(
            'ATK/DEF:',
            card.atk != null ? '${card.atk}/${card.def ?? '?'}' : null,
          ),
          _buildDetailRow('Rareza:', card.rareza?.join(', ')),
          _buildDetailRow('Set:', card.setExpansion),
          if (card.descripcion != null && card.descripcion!['es'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
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
                  const SizedBox(height: 8),
                  Text(
                    card.descripcion!['es']!.toString(),
                    softWrap: true,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Función de ayuda universal para no repetir código al crear las filas de detalles.
  Widget _buildDetailRow(
    String label,
    String? value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }
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
}

// --- WIDGET PARA MOSTRAR ERRORES ---
class FailedCardPlaceholder extends StatelessWidget {
  final String cardCode;
  const FailedCardPlaceholder({super.key, required this.cardCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade400.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade300,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            "Fallo al buscar:",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cardCode,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
