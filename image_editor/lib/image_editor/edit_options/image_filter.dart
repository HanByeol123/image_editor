// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/image_editor/image_editor_plus.dart';
import 'package:screenshot/screenshot.dart';

class ImageFilters extends StatefulWidget {
  final Uint8List image;

  /// apply each filter to given image in background and cache it to improve UX
  final bool useCache;

  const ImageFilters({
    super.key,
    required this.image,
    this.useCache = true,
  });

  @override
  createState() => _ImageFiltersState();
}

class _ImageFiltersState extends State<ImageFilters> {
  late img.Image decodedImage;
  ColorFilterGenerator selectedFilter = PresetFilters.none;
  Uint8List resizedImage = Uint8List.fromList([]);
  double filterOpacity = 1;
  Uint8List? filterAppliedImage;
  ScreenshotController screenshotController = ScreenshotController();
  late List<ColorFilterGenerator> filters;

  @override
  void initState() {
    filters = [
      PresetFilters.none,
      PresetFilters.addictiveBlue,
      PresetFilters.addictiveRed,
      PresetFilters.aden,
      PresetFilters.amaro,
      PresetFilters.ashby,
      PresetFilters.brannan,
      PresetFilters.brooklyn,
      PresetFilters.charmes,
      PresetFilters.clarendon,
      PresetFilters.crema,
      PresetFilters.dogpatch,
      PresetFilters.earlybird,
      PresetFilters.f1977,
      PresetFilters.gingham,
      PresetFilters.ginza,
      PresetFilters.hefe,
      PresetFilters.helena,
      PresetFilters.hudson,
      PresetFilters.inkwell,
      PresetFilters.juno,
      PresetFilters.kelvin,
      PresetFilters.lark,
      PresetFilters.loFi,
      PresetFilters.ludwig,
      PresetFilters.maven,
      PresetFilters.mayfair,
      PresetFilters.moon,
      PresetFilters.nashville,
      PresetFilters.perpetua,
      PresetFilters.reyes,
      PresetFilters.rise,
      PresetFilters.sierra,
      PresetFilters.skyline,
      PresetFilters.slumber,
      PresetFilters.stinson,
      PresetFilters.sutro,
      PresetFilters.toaster,
      PresetFilters.valencia,
      PresetFilters.vesper,
      PresetFilters.walden,
      PresetFilters.willow,
      PresetFilters.xProII,
    ];

    // decodedImage = img.decodeImage(widget.image)!;
    // resizedImage = img.copyResize(decodedImage, height: 64).getBytes();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.check),
              onPressed: () async {
                // var loadingScreen = showLoadingScreen(context);
                // var data = await screenshotController.capture();
                // loadingScreen.hide();

                if (mounted) Navigator.pop(context, selectedFilter);
              },
            ),
          ],
        ),
        body: Center(
          child: Screenshot(
            controller: screenshotController,
            child: Stack(
              children: [
                Image.memory(
                  widget.image,
                  fit: BoxFit.cover,
                ),
                FilterAppliedImage(
                  key: Key('selectedFilter:${selectedFilter.name}'),
                  image: widget.image,
                  filter: selectedFilter,
                  fit: BoxFit.cover,
                  opacity: filterOpacity,
                  // onProcess: (img) {
                  //   print('processing done');
                  //   filterAppliedImage = img;
                  // },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: SizedBox(
            height: 160,
            child: Column(children: [
              SizedBox(
                height: 40,
                child: selectedFilter == PresetFilters.none
                    ? Container()
                    : selectedFilter.build(
                        Slider(
                          min: 0,
                          max: 1,
                          divisions: 100,
                          value: filterOpacity,
                          onChanged: (value) {
                            filterOpacity = value;
                            setState(() {});
                          },
                        ),
                      ),
              ),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var filter in filters)
                      GestureDetector(
                        onTap: () {
                          selectedFilter = filter;
                          setState(() {});
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 64,
                              width: 64,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(48),
                                border: Border.all(
                                  color: selectedFilter == filter ? Colors.white : Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48),
                                child: FilterAppliedImage(
                                  key: Key('filterPreviewButton:${filter.name}'),
                                  image: widget.image,
                                  filter: filter,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Text(
                              filter.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class FilterAppliedImage extends StatefulWidget {
  final Uint8List image;
  final ColorFilterGenerator filter;
  final BoxFit? fit;
  final Function(Uint8List)? onProcess;
  final double opacity;

  const FilterAppliedImage({
    super.key,
    required this.image,
    required this.filter,
    this.fit,
    this.onProcess,
    this.opacity = 1,
  });

  @override
  State<FilterAppliedImage> createState() => _FilterAppliedImageState();
}

class _FilterAppliedImageState extends State<FilterAppliedImage> {
  @override
  initState() {
    super.initState();

    // process filter in background
    if (widget.onProcess != null) {
      // no filter supplied
      if (widget.filter.filters.isEmpty) {
        widget.onProcess!(widget.image);
        return;
      }

      var filterTask = img.Command();
      filterTask.decodeImage(widget.image);

      var matrix = widget.filter.matrix;

      filterTask.filter((image) {
        for (final pixel in image) {
          pixel.r = matrix[0] * pixel.r + matrix[1] * pixel.g + matrix[2] * pixel.b + matrix[3] * pixel.a + matrix[4];

          pixel.g = matrix[5] * pixel.r + matrix[6] * pixel.g + matrix[7] * pixel.b + matrix[8] * pixel.a + matrix[9];

          pixel.b = matrix[10] * pixel.r + matrix[11] * pixel.g + matrix[12] * pixel.b + matrix[13] * pixel.a + matrix[14];

          pixel.a = matrix[15] * pixel.r + matrix[16] * pixel.g + matrix[17] * pixel.b + matrix[18] * pixel.a + matrix[19];
        }

        return image;
      });

      filterTask.getBytesThread().then((result) {
        if (widget.onProcess != null && result != null) {
          widget.onProcess!(result);
        }
      }).catchError((err, stack) {
        // print(err);
        // print(stack);
      });

      // final image_editor.ImageEditorOption option =
      //     image_editor.ImageEditorOption();

      // option.addOption(image_editor.ColorOption(matrix: filter.matrix));

      // image_editor.ImageEditor.editImage(
      //   image: image,
      //   imageEditorOption: option,
      // ).then((result) {
      //   if (result != null) {
      //     onProcess!(result);
      //   }
      // }).catchError((err, stack) {
      //   // print(err);
      //   // print(stack);
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filter.filters.isEmpty) {
      return Image.memory(
        widget.image,
        fit: widget.fit,
      );
    }

    return Opacity(
      opacity: widget.opacity,
      child: widget.filter.build(
        Image.memory(
          widget.image,
          fit: widget.fit,
        ),
      ),
    );
  }
}

// class ColorFilter {
//   static ColorFilterGenerator amaro = ColorFilterGenerator(
//     name: "Amaro",
//     filters: [
//       ColorFilterAddons.saturation(0.3),
//       ColorFilterAddons.brightness(0.15),
//     ],
//   );
// }
