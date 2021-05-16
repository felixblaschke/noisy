library noisy;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:fast_noise/fast_noise.dart';
import 'package:flutter/material.dart';

/// Widgets that renders a noise texture
///
/// The type of noise can be picked from [noiseType]. You can adjust the noise
/// by setting
///
/// - [color]
/// - [intensity] (0.0 ... 1.0)
/// - [scale] (0.001 ... 10)
/// - [seed] (initializer for random number generator)
///
class Noisy extends StatefulWidget {
  final Widget? child;
  final int seed;
  final double scale;
  final Color color;
  final double intensity;
  final NoiseType noiseType;

  const Noisy({
    Key? key,
    this.seed = 0,
    this.scale = 1.0,
    this.color = Colors.black,
    this.intensity = 0.08,
    this.noiseType = NoiseType.white,
    this.child,
  }) : super(key: key);

  @override
  _NoisyState createState() => _NoisyState();
}

class _NoisyState extends State<Noisy> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return NoisyRenderer(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        seed: widget.seed,
        scale: widget.scale,
        color: widget.color,
        intensity: widget.intensity,
        noiseType: widget.noiseType,
      );
    });
  }
}

class NoisyRenderer extends StatefulWidget {
  final Size size;
  final Widget? child;
  final int seed;
  final double scale;
  final Color color;
  final double intensity;
  final NoiseType noiseType;

  const NoisyRenderer({
    Key? key,
    required this.size,
    required this.seed,
    required this.scale,
    required this.color,
    required this.intensity,
    required this.noiseType,
    this.child,
  }) : super(key: key);

  @override
  _NoisyRendererState createState() => _NoisyRendererState();
}

class _NoisyRendererState extends State<NoisyRenderer> {
  MemoryImage? memoryImage;

  @override
  void didUpdateWidget(covariant NoisyRenderer old) {
    _computeImage();
    super.didUpdateWidget(old);
  }

  Future<void> _computeImage() async {
    var size = widget.size;
    final cullRect = Rect.fromLTRB(0, 0, size.width, size.height);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, cullRect);
    _paintNoise(canvas, size, widget.seed, widget.scale, widget.color,
        widget.intensity, widget.noiseType);

    var painting = recorder.endRecording();
    var image = await painting.toImage(size.width.round(), size.height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    setState(() {
      memoryImage = MemoryImage(bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (memoryImage != null) {
      return Image(image: memoryImage!);
    }
    return Container();
  }
}

void _paintNoise(
  Canvas canvas,
  Size size,
  int seed,
  double scale,
  Color color,
  double intensity,
  NoiseType type,
) {
  late SimplexNoise simplexNoise;
  late WhiteNoise whiteNoise;
  late CellularNoise cellNoise;

  /// Initialize noise generator
  switch (type) {
    case NoiseType.pixel:
      simplexNoise = SimplexNoise(seed: seed, frequency: 0.1);
      break;
    case NoiseType.white:
      whiteNoise = WhiteNoise(seed: seed);
      break;
    case NoiseType.cell:
      cellNoise = CellularNoise(seed: seed, frequency: 0.1);
      break;
  }

  /// Compute noise value for each pixel
  for (var y = 0; y < size.height; y++) {
    for (var x = 0; x < size.width; x++) {
      late double value;
      var xDouble = x.toDouble();
      var yDouble = y.toDouble();

      switch (type) {
        case NoiseType.pixel:
          value = simplexNoise.getSimplex2(xDouble / scale, yDouble / scale);
          break;
        case NoiseType.white:
          value = whiteNoise.getWhiteNoise2(xDouble ~/ scale, yDouble ~/ scale);
          break;
        case NoiseType.cell:
          value = cellNoise.getCellular2(xDouble / scale, yDouble / scale);
          break;
      }

      /// Normalize generated value. Generators will provide values from -1.0 .. 1.0
      value = (1 + value) / 2.0;

      final paint = Paint()..color = color.withOpacity(intensity * value);
      canvas.drawRect(Rect.fromLTWH(xDouble, yDouble, 1, 1), paint);
    }
  }
}

enum NoiseType {
  /// pixelated noise
  pixel,

  /// white noise
  white,

  /// cellular noise
  cell
}
