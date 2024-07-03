import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:flutter/material.dart';

enum OutputFormat {
  /// merge all layers and return jpeg encoded bytes
  jpeg,

  /// convert all layers into json and return the list
  json,

  /// merge all layers and return png encoded bytes
  png
}

class Ratio {
  final String title;
  final double? ratio;

  const Ratio({required this.title, this.ratio});
}

class CropOption {
  final bool reversible;

  /// List of availble ratios
  final List<Ratio> ratios;

  const CropOption({
    this.reversible = true,
    this.ratios = const [
      Ratio(title: 'Freeform'),
      // Ratio(title: 'radius', ratio: 0),
      Ratio(title: '1:1', ratio: 1),
      Ratio(title: '4:3', ratio: 4 / 3),
      Ratio(title: '5:4', ratio: 5 / 4),
      Ratio(title: '7:5', ratio: 7 / 5),
      Ratio(title: '16:9', ratio: 16 / 9),
    ],
  });
}

class BlurOption {
  const BlurOption();
}

class BrushOption {
  /// show background image on draw screen
  final bool showBackground;

  /// User will able to move, zoom drawn image
  /// Note: Layer may not be placed precisely
  final bool translatable;
  final List<BrushColor> colors;

  const BrushOption({
    this.showBackground = true,
    this.translatable = false,
    this.colors = const [
      BrushColor(color: Colors.black, background: Colors.white),
      BrushColor(color: Colors.white),
      BrushColor(color: Colors.blue),
      BrushColor(color: Colors.green),
      BrushColor(color: Colors.pink),
      BrushColor(color: Colors.purple),
      BrushColor(color: Colors.brown),
      BrushColor(color: Colors.indigo),
    ],
  });
}

class BrushColor {
  /// Color of brush
  final Color color;

  /// Background color while brush is active only be used when showBackground is false
  final Color background;

  const BrushColor({
    required this.color,
    this.background = Colors.black,
  });
}

class EmojiOption {
  const EmojiOption();
}

class FiltersOption {
  final List<ColorFilterGenerator>? filters;
  const FiltersOption({this.filters});
}

class FlipOption {
  const FlipOption();
}

class RotateOption {
  const RotateOption();
}

class TextOption {
  const TextOption();
}

class ImagePickerOption {
  final bool pickFromGallery, captureFromCamera;
  final int maxLength;

  const ImagePickerOption({
    this.pickFromGallery = false,
    this.captureFromCamera = false,
    this.maxLength = 99,
  });
}
