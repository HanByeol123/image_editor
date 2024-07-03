// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/image_editor/edit_options/options.dart';
import 'package:image_editor/image_editor/image_editor_plus.dart';

class ImageCropper extends StatefulWidget {
  final Uint8List image;

  const ImageCropper({
    super.key,
    required this.image,
  });

  @override
  createState() => _ImageCropperState();
}

class _ImageCropperState extends State<ImageCropper> {
  final _controller = GlobalKey<ExtendedImageEditorState>();

  double? currentRatio;
  late double radius = 0;
  bool get isLandscape => currentRatio != null && currentRatio! > 1;
  int rotateAngle = 0;
  List<Ratio> availableRatios = [];
  late double width = 0;
  late double height = 0;

  // double slider = 0.0;
  double sliderValue = 0.0;

  @override
  void initState() {
    availableRatios = const CropOption().ratios;
    currentRatio = availableRatios.first.ratio;
    _controller.currentState?.rotate(right: true);

    super.initState();
  }

  customRound() {
    Rect rect = _controller.currentState!.getCropRect()!;
    width = rect.width;
    height = rect.height;

    int widthDecimalPart = ((width * 10) % 10).toInt();
    int heightDecimalPart = ((height * 10) % 10).toInt();

    if (widthDecimalPart >= 5) {
      width = width.ceilToDouble();
    } else {
      width = width.floorToDouble();
    }
    if (heightDecimalPart >= 5) {
      height = height.ceilToDouble();
    } else {
      height = height.floorToDouble();
    }
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
                var state = _controller.currentState;

                var data = await cropImageWithThread(
                  imageBytes: state!.rawImageData,
                  rect: state.getCropRect()!,
                );

                if (mounted) Navigator.pop(context, data);
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.black,
          child: ExtendedImage.memory(
            widget.image,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(radius),
            clipBehavior: Clip.hardEdge,
            cacheRawData: true,
            fit: BoxFit.contain,
            extendedImageEditorKey: _controller,
            mode: ExtendedImageMode.editor,
            initEditorConfigHandler: (state) {
              return EditorConfig(
                cropAspectRatio: currentRatio,
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: SizedBox(
            height: 80,
            child: Column(
              children: [
                Container(
                  height: 80,
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    // shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: availableRatios.length + 1,
                    itemBuilder: (context, index) {
                      var ratio = availableRatios[index == 0 ? index : index - 1];

                      return index == 1
                          ? TextButton(
                              onPressed: () async {
                                await customRound();

                                showModalBottomSheet(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      topLeft: Radius.circular(10),
                                    ),
                                  ),
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) {
                                    return StatefulBuilder(
                                      builder: (context, setStat2) {
                                        return Container(
                                          height: 200,
                                          decoration: const BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10)),
                                          ),
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 10),
                                              Center(
                                                child: Text(
                                                  'Radius: ${sliderValue.round()}%',
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ),
                                              Slider(
                                                  activeColor: Colors.white,
                                                  inactiveColor: Colors.grey,
                                                  value: sliderValue,
                                                  min: 0.0,
                                                  max: 100.0,
                                                  onChangeEnd: (v) {
                                                    if (width < height) {
                                                      radius = (width / 2) / 100 * sliderValue.round();
                                                    } else {
                                                      radius = (height / 2) / 100 * sliderValue.round();
                                                    }
                                                  },
                                                  onChanged: (v) {
                                                    setStat2(() {
                                                      // print(v.toDouble());
                                                      sliderValue = v.toDouble();
                                                    });
                                                  }),
                                              const SizedBox(height: 10),
                                              Row(children: [
                                                Expanded(
                                                  child: TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      'OK',
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ).then((value) => setState(() {}));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: const Text(
                                  'radius',
                                  style: TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: () async {
                                currentRatio = ratio.ratio;

                                Future.delayed(const Duration(milliseconds: 50), () {
                                  customRound();
                                  print(sliderValue);
                                  if (width < height) {
                                    radius = (width / 2) / 100 * sliderValue.round();
                                  } else {
                                    radius = (height / 2) / 100 * sliderValue.round();
                                  }
                                  print(radius);
                                });
                                setState(() {});
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    ratio.title,
                                    style: TextStyle(
                                      color: currentRatio == ratio.ratio ? Colors.white : Colors.grey,
                                    ),
                                  )),
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> cropImageWithThread({
    required Uint8List imageBytes,
    required Rect rect,
  }) async {
    img.Command cropTask = img.Command();
    cropTask.decodeImage(imageBytes);

    cropTask.copyCrop(
      x: rect.topLeft.dx.ceil(),
      y: rect.topLeft.dy.ceil(),
      height: rect.height.ceil(),
      width: rect.width.ceil(),
      radius: radius,
    );

    img.Command encodeTask = img.Command();
    encodeTask.subCommand = cropTask;
    encodeTask.encodeJpg();

    return encodeTask.getBytesThread();
  }
}
