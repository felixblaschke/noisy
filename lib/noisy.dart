library noisy;

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
class Noisy extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NoisePainter(
        seed: seed,
        color: color,
        intensity: intensity,
        scale: scale,
        type: noiseType,
      ),
      child: child,
    );
  }
}

class NoisePainter extends CustomPainter {
  final int seed;
  final double scale;
  final Color color;
  final double intensity;
  final NoiseType type;

  const NoisePainter({
    required this.seed,
    required this.color,
    required this.intensity,
    required this.scale,
    required this.type,
  });

  @override
  void paint(Canvas canvas, Size size) {
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
            value =
                whiteNoise.getWhiteNoise2(xDouble ~/ scale, yDouble ~/ scale);
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

  @override
  bool shouldRepaint(covariant NoisePainter old) =>
      old.seed != seed ||
      old.color != color ||
      old.intensity != intensity ||
      old.scale != scale ||
      old.type != type;
}

enum NoiseType {
  /// pixelated noise
  pixel,

  /// white noise
  white,

  /// cellular noise
  cell
}
