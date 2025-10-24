import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpinningFlipCardWidget extends StatefulWidget {
  final ImageProvider frontImage;
  final double cardAspectRatio;
  final Duration rotationDuration;

  const SpinningFlipCardWidget({
    super.key,
    required this.frontImage,
    this.cardAspectRatio = 59 / 86,
    this.rotationDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<SpinningFlipCardWidget> createState() => _SpinningFlipCardWidgetState();
}

class _SpinningFlipCardWidgetState extends State<SpinningFlipCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Imagen actual visible (anverso)
  late ImageProvider _currentFront;

  // Imagen pendiente
  ImageProvider? _pendingFront;
  bool _pendingLoaded = false;

  @override
  void initState() {
    super.initState();

    _currentFront = widget.frontImage;

    _controller = AnimationController(
      vsync: this,
      duration: widget.rotationDuration,
    )..addListener(_onRotate)
     ..repeat(); // Giro infinito
  }

  @override
  void didUpdateWidget(covariant SpinningFlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frontImage != oldWidget.frontImage) {
      _loadPending(widget.frontImage);
    }
  }

  Future<void> _loadPending(ImageProvider newImage) async {
    _pendingFront = newImage;
    _pendingLoaded = false;
    try {
      await precacheImage(newImage, context);
      if (mounted) setState(() => _pendingLoaded = true);
    } catch (_) {
      // Si falla la carga, no cambiamos la imagen
      _pendingFront = null;
      _pendingLoaded = false;
    }
  }

  void _onRotate() {
    // 0 → 1 equivale a 0° → 360°
    final value = _controller.value;
    final double angle = value * 2 * math.pi;

    // Detectar el momento exacto en el que la carta está de espaldas (~180°)
    // Y la nueva imagen ya está cargada
    if (_pendingFront != null &&
        _pendingLoaded &&
        (angle % (2 * math.pi)) > math.pi - 0.05 &&
        (angle % (2 * math.pi)) < math.pi + 0.05) {
      setState(() {
        _currentFront = _pendingFront!;
        _pendingFront = null;
        _pendingLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onRotate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backCard = Image.asset(
      'lib/assets/back-card.png',
      fit: BoxFit.cover,
    );

    final frontCard = Image(
      image: _currentFront,
      fit: BoxFit.cover,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double angle = _controller.value * 2 * math.pi;
        final double rotation = angle % (2 * math.pi);

        // Si está mostrando el dorso o el anverso
        final bool isShowingBack = rotation > math.pi / 2 && rotation < 3 * math.pi / 2;

        Widget cardFace;
        if (isShowingBack) {
          // Parte trasera
          cardFace = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(math.pi),
            child: backCard,
          );
        } else {
          // Parte frontal
          cardFace = frontCard;
        }

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotation),
          child: AspectRatio(
            aspectRatio: widget.cardAspectRatio,
            child: cardFace,
          ),
        );
      },
    );
  }
}
