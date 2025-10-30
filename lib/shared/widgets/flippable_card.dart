// lib/shared/widgets/flippable_card.dart
import 'dart:math';
import 'package:flutter/material.dart' hide Card;
import 'package:cached_network_image/cached_network_image.dart';
// Asegúrate de que esta ruta a tu modelo Card sea correcta
import 'package:yugioh_scanner/models/card_model.dart'; 

class FlippableCard extends StatefulWidget {
  final String imageUrl;
  final String cardBackAsset;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final Card? cardData; // Datos dinámicos de la carta

  const FlippableCard({
    super.key,
    required this.imageUrl,
    this.cardBackAsset = 'assets/back-card.png',
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(10.0)),
    this.cardData,
  });

  @override
  State<FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<FlippableCard> {
  bool _hasFlippedOnLoad = false;
  bool _isFlipped = false;
  bool _showShine = false;

  @override
  void didUpdateWidget(covariant FlippableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl && widget.imageUrl.isNotEmpty) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _hasFlippedOnLoad = false;
            _isFlipped = false;
            _showShine = false;
          });
        }
      });
    }
  }

  void _flipCard() {
    if (mounted && !_hasFlippedOnLoad) {
      setState(() {
        _isFlipped = true;
        _hasFlippedOnLoad = true;
      });

      // Activa el brillo tras el volteo
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _showShine = true);

        // Desactiva el brillo tras su animación
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _showShine = false);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: _buildFrontCardContent(),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        final rotateAnim = Tween<double>(begin: 0.0, end: pi).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        );

        return AnimatedBuilder(
          animation: rotateAnim,
          builder: (context, _) {
            final isFirstHalf = rotateAnim.value < (pi / 2);
            final angle = rotateAnim.value;

            final Widget current = isFirstHalf
                ? _buildFrontCard()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildBackCard(),
                  );

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: current,
            );
          },
        );
      },
      child: _isFlipped ? _buildBackCard() : _buildFrontCard(),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            ...previousChildren.map((c) => Positioned.fill(child: c)),
            if (currentChild != null) Positioned.fill(child: currentChild),
          ],
        );
      },
    );
  }

  Widget _buildFrontCardContent() => Image.asset(
        widget.cardBackAsset,
        fit: widget.fit,
        key: const ValueKey('front-content'),
      );

  Widget _buildFrontCard() => ClipRRect(
        key: const ValueKey('front'),
        borderRadius: widget.borderRadius,
        child: _buildFrontCardContent(),
      );

  Widget _buildBackCard() {
    return ClipRRect(
      key: const ValueKey('back'),
      borderRadius: widget.borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: widget.fit,
            imageBuilder: (context, provider) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _flipCard();
              });
              return Image(image: provider, fit: widget.fit);
            },
            placeholder: (context, url) =>
                Image.asset(widget.cardBackAsset, fit: widget.fit),
            errorWidget: (context, url, error) =>
                Image.asset(widget.cardBackAsset, fit: widget.fit),
          ),
          _buildShineEffect(), // Brillo encima
        ],
      ),
    );
  }

Widget _buildShineEffect() {
  // Obtener los colores basados en el tipo de carta
  final Map<String, Color> glowColors = _getGlowColors(widget.cardData!);
  final Color baseGlowColor = glowColors['glow'] ?? Colors.white;
  final Color baseHotspotColor = glowColors['hotspot'] ?? Colors.white;

  // Depuración: Mostrar información sobre la carta
  debugPrint('=== INFORMACIÓN DE LA CARTA ===');
  debugPrint('Nombre: ${widget.cardData!.nombre}');
  debugPrint('Tipo: ${widget.cardData!.tipo ?? "N/A"}');
  debugPrint('Marco: ${widget.cardData!.marcoCarta ?? "N/A"}');
  debugPrint('Subtipo: ${widget.cardData!.subtipo?.join(', ') ?? "Ninguno"}');
  debugPrint('Clasificación: ${widget.cardData!.clasificacion ?? "N/A"}');
  debugPrint('Color de brillo: $baseGlowColor');
  debugPrint('Color de punto caliente: $baseHotspotColor');
  debugPrint('================================');

  final double shineOpacity = _showShine ? 1.0 : 0.0;

  return IgnorePointer(
    child: AnimatedOpacity(
      opacity: shineOpacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: _showShine ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final double h = constraints.maxHeight;

            if (w == 0 || h == 0) return const SizedBox.shrink();

            // Calculate the diagonal length of the card with extra padding to cover corners
            final double diagonal = sqrt(w * w + h * h);
            final double padding = max(w, h) * 0.5; // Extra padding to ensure full coverage
            
            // Create a gradient that's at a 45-degree angle
            return SizedBox(
              width: w,
              height: h,
              child: OverflowBox(
                maxWidth: w + padding * 2,
                maxHeight: h + padding * 2,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main shine effect
                    Transform.rotate(
                      angle: -pi / 4, // 45 degrees in radians
                      child: Transform.translate(
                        // Animate from top-left to bottom-right with extra padding
                        offset: Offset(
                          -diagonal + (2 * diagonal * value) - (w / 2) + (h / 2) - padding,
                          0,
                        ),
                        child: Container(
                          width: diagonal * 2 + padding * 2,
                          height: diagonal * 2 + padding * 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.0, 0.0),
                          end: Alignment(1.0, 0.0),
                          colors: [
                            Colors.transparent,
                            baseGlowColor.withAlpha(25), // 0.1 * 255 ≈ 25
                            baseHotspotColor.withAlpha(178), // 0.7 * 255 ≈ 178
                            baseGlowColor.withAlpha(25), // 0.1 * 255 ≈ 25
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                      ),
                        ),
                      ),
                    ),
                    
                    // Subtle overlay for better blending
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              baseGlowColor.withAlpha(51), // 0.2 * 255 ≈ 51
                              Colors.transparent,
                              Colors.transparent,
                              baseGlowColor.withAlpha(51), // 0.2 * 255 ≈ 51
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    ),
  );
}

  /// Colores base según el tipo de carta
  Map<String, Color> _getGlowColors(Card card) {
    // Obtener valores con manejo de nulos
    final marco = card.marcoCarta?.toLowerCase() ?? '';
    final tipo = card.tipo?.toLowerCase() ?? '';
    final clasificacion = card.clasificacion?.toLowerCase() ?? '';
    
    // Manejar subtipos de forma segura
    final subtipos = (card.subtipo ?? [])
        .whereType<String>()
        .map((s) => s.toLowerCase())
        .toList();

    // 1. Verificar si es una carta mágica
    if (marco.contains('spell') || marco.contains('magia') || tipo.contains('spell')) {
      return {
        'glow': const Color(0xE600FF9D), // Verde brillante con opacidad 0.9
        'hotspot': Colors.white
      };
    } 
    
    // 2. Verificar si es una carta de trampa
    if (marco.contains('trap') || marco.contains('trampa') || tipo.contains('trap')) {
      return {
        'glow': const Color(0xE6FF2D95), // Rosa fluorescente con opacidad 0.9
        'hotspot': Colors.white
      };
    }

    // 3. Si no es mágica ni trampa, asumimos que es un monstruo
    
    // 3.1 Verificar subtipos especiales
    if (subtipos.any((sub) => sub.contains('fusion'))) {
      return {
        'glow': const Color(0xE6FF00FF), // Magenta brillante con opacidad 0.9
        'hotspot': Colors.white
      };
    }
    
    if (subtipos.any((sub) => sub.contains('synchro'))) {
      return {
        'glow': const Color(0xE6FFFFFF), // Blanco puro con opacidad 0.9
        'hotspot': Colors.white
      };
    }
    
    if (subtipos.any((sub) => sub.contains('xyz'))) {
      return {
        'glow': const Color(0xE6000000), // Negro puro con opacidad 0.9
        'hotspot': Colors.white
      };
    }
    
    if (subtipos.any((sub) => sub.contains('link'))) {
      return {
        'glow': const Color(0xE600A8FF), // Azul brillante con opacidad 0.9
        'hotspot': Colors.white
      };
    }
    
    if (subtipos.any((sub) => sub.contains('ritual'))) {
      return {
        'glow': const Color(0xE600FFFF), // Cian brillante con opacidad 0.9
        'hotspot': Colors.white
      };
    }
    
    // 3.2 Verificar si es un monstruo normal
    if (clasificacion == 'normal' || subtipos.any((sub) => sub.contains('normal'))) {
      return {
        'glow': const Color(0xE6FFFF00), // Amarillo brillante con opacidad 0.9
        'hotspot': Colors.white
      };
    }
    
    // 4. Monstruo de efecto por defecto
    return {
      'glow': const Color(0xE6FF8000), // Naranja brillante con opacidad 0.9
      'hotspot': Colors.white
    };
  }
}