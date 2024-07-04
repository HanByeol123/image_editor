// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

library image_editor_plus;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor/edit_options/options.dart';
import 'package:image_editor/image_editor/multi_image_editor.dart';
import 'package:image_editor/image_editor/single_image_editor.dart';
// import 'package:image_editor_plus/options.dart' as o;

// import 'modules/colors_picker.dart';

late Size viewportSize;
double viewportRatio = 1;

String i18n(String sourceString) => sourceString;

/// Set custom theme properties default is dark theme with white text
ThemeData theme = ThemeData(
  scaffoldBackgroundColor: Colors.black,
  colorScheme: const ColorScheme.dark(
    surface: Colors.black,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black87,
    iconTheme: IconThemeData(color: Colors.white),
    systemOverlayStyle: SystemUiOverlayStyle.light,
    toolbarTextStyle: TextStyle(color: Colors.white),
    titleTextStyle: TextStyle(color: Colors.white),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
  ),
);

/// Single endpoint for MultiImageEditor & SingleImageEditor
class ImageEditor extends StatelessWidget {
  final dynamic image;
  final List? images;
  final String? savePath;
  final OutputFormat outputFormat;
  final bool? isCoverImg;

  final ImagePickerOption imagePickerOption;

  const ImageEditor({
    super.key,
    this.image,
    this.images,
    this.savePath,
    this.imagePickerOption = const ImagePickerOption(),
    this.outputFormat = OutputFormat.jpeg,
    this.isCoverImg = false,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null && images == null && !imagePickerOption.captureFromCamera && !imagePickerOption.pickFromGallery) {
      throw Exception('No image to work with, provide an image or allow the image picker.');
    }

    if (image != null) {
      return SingleImageEditor(
        image: image,
        imagePickerOption: imagePickerOption,
        outputFormat: outputFormat,
      );
    } else {
      return MultiImageEditor(
        images: images ?? [],
        imagePickerOption: imagePickerOption,
      );
    }
  }
}

class ColorButton extends StatelessWidget {
  final Color color;
  final Function(Color) onTap;
  final bool isSelected;

  const ColorButton({
    super.key,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap(color);
      },
      child: Container(
        height: 34,
        width: 34,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 23),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white54,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
