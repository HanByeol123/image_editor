// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'dart:async';
import 'dart:math' as math;

import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/home.dart';
// import 'package:image_editor/home.dart';
import 'package:image_editor/image_editor/edit_options/image_crop.dart';
import 'package:image_editor/image_editor/edit_options/image_filter.dart';
import 'package:image_editor/image_editor/edit_options/options.dart';
import 'package:image_editor/image_editor/image_editor_plus.dart';
import 'package:image_editor/image_editor/layers_overlay.dart';
import 'package:image_editor/image_editor/layers_viewer/layers_viewer.dart';
import 'package:image_editor_plus/data/image_item.dart';
import 'package:image_editor_plus/data/layer.dart';
import 'package:image_editor_plus/loading_screen.dart';
import 'package:image_editor_plus/modules/all_emojies.dart';
import 'package:image_editor_plus/modules/text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

class SingleImageEditor extends StatefulWidget {
  final dynamic image;
  final OutputFormat outputFormat;
  final ImagePickerOption imagePickerOption;

  const SingleImageEditor({
    super.key,
    this.image,
    this.outputFormat = OutputFormat.jpeg,
    this.imagePickerOption = const ImagePickerOption(),
  });

  @override
  createState() => _SingleImageEditorState();
}

class _SingleImageEditorState extends State<SingleImageEditor> with WidgetsBindingObserver {
  late bool _isLoading = true;

  final picker = ImagePicker();

  ImageItem currentImage = ImageItem();

  ScreenshotController screenshotController = ScreenshotController();

  PermissionStatus galleryPermission = PermissionStatus.permanentlyDenied, cameraPermission = PermissionStatus.permanentlyDenied;

  double x = 0;
  double y = 0;
  double z = 0;

  double lastScaleFactor = 1, scaleFactor = 1;
  double pixelRatio = 1, rotateValue = 0.0, flipValue = 0.0;

  int duration = 1;
  late int index;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // if (userInfoProvider.layers[index].isNotEmpty) {
    //   loadImages();
    // } else if (widget.image != null) {
    loadImage();
    // }

    _isLoading = false;
    setState(() {});
    checkPermissions();
  }

  checkPermissions() async {
    if (widget.imagePickerOption.pickFromGallery) {
      galleryPermission = await Permission.photos.status;
    }

    if (widget.imagePickerOption.captureFromCamera) {
      cameraPermission = await Permission.camera.status;
    }

    if (widget.imagePickerOption.pickFromGallery || widget.imagePickerOption.captureFromCamera) {
      setState(() {});
    }
  }

  // Future<void> loadImages() async {
  //   await currentImage.load((userInfoProvider.layers[index].first as BackgroundLayerData).image.bytes);

  //   if (userInfoProvider.imageWidth[index] != 0 || userInfoProvider.imageHeight[index] != 0 || userInfoProvider.rotateValue[index] != 0) {
  //     currentImage.width = userInfoProvider.imageWidth[index];
  //     currentImage.height = userInfoProvider.imageHeight[index];
  //     rotateValue = userInfoProvider.rotateValue[index];
  //   }

  //   if (userInfoProvider.flipValue[index] != 0) flipValue = userInfoProvider.flipValue[index];

  //   for (int i = 0; i < userInfoProvider.layers[index].length; i++) {
  //     if (i == 0) {
  //       layers.clear();
  //       // tempLayers.clear();
  //     }
  //     switch (userInfoProvider.layers[index][i].runtimeType) {
  //       case BackgroundLayerData:
  //         layers.add(BackgroundLayerData(image: currentImage));
  //         // tempLayers.add(BackgroundLayerData(image: currentImage));
  //         break;
  //       case FilterLayerData:
  //         userInfoProvider.selectedFilterColor[index] = (userInfoProvider.layers[index][i] as FilterLayerData).filterColor;

  //         layers.add(
  //           FilterLayerData(
  //             image: currentImage,
  //             filterColor: (userInfoProvider.layers[index][i] as FilterLayerData).filterColor,
  //           ),
  //         );
  //         // tempLayers.add(FilterLayerData(image: currentImage));
  //         break;
  //       case ImageLayerData:
  //         final layerData = (userInfoProvider.layers[index][i] as ImageLayerData);
  //         var imageItem = ImageItem(layerData.image.bytes);
  //         await imageItem.loader.future;
  //         ImageLayerData layer = ImageLayerData(
  //           image: imageItem,
  //           size: layerData.size,
  //           scale: layerData.scale,
  //           rotation: layerData.rotation,
  //           offset: layerData.offset,
  //           opacity: layerData.opacity,
  //         );

  //         layers.add(layer);
  //         // tempLayers.add(layer);
  //         break;
  //       case TextLayerData:
  //         final layerData = (userInfoProvider.layers[index][i] as TextLayerData);
  //         TextLayerData layer = TextLayerData(
  //           text: layerData.text,
  //           align: layerData.align,
  //           background: layerData.background,
  //           backgroundOpacity: layerData.backgroundOpacity,
  //           color: layerData.color,
  //           offset: layerData.offset,
  //           opacity: layerData.opacity,
  //           rotation: layerData.rotation,
  //           scale: layerData.scale,
  //           size: layerData.size,
  //         );
  //         layers.add(layer);
  //         // tempLayers.add(layer);
  //         break;
  //       case EmojiLayerData:
  //         final layerData = (userInfoProvider.layers[index][i] as EmojiLayerData);
  //         EmojiLayerData layer = EmojiLayerData(
  //           text: layerData.text,
  //           size: layerData.size,
  //           scale: layerData.scale,
  //           rotation: layerData.rotation,
  //           offset: layerData.offset,
  //           opacity: layerData.opacity,
  //         );
  //         layers.add(layer);
  //         // tempLayers.add(layer);
  //         break;
  //     }
  //   }
  //   userInfoProvider.noti();
  //   setState(() {});
  // }

  Future<void> loadImage() async {
    await currentImage.load(widget.image!);
    layers.clear();
    layers.add(BackgroundLayerData(image: currentImage));
    setState(() {});
  }

  resetTransformation() {
    scaleFactor = 1;
    x = 0;
    y = 0;
    setState(() {});
  }

  /// obtain image Uint8List by merging layers
  Future<Uint8List?> getMergedImage([
    OutputFormat format = OutputFormat.png,
  ]) async {
    Uint8List? image;

    if (layers.length > 1) {
      if (format == OutputFormat.jpeg) {
        image = await screenshotController.capture(pixelRatio: pixelRatio);
      }
    } else if (layers.length == 1) {
      image = (layers.first as BackgroundLayerData).image.bytes;
    }

    // conversion for non-png
    if (image != null && format == OutputFormat.jpeg) {
      var decodedImage = img.decodeImage(image);

      if (decodedImage == null) {
        throw Exception('Unable to decode image for conversion.');
      }

      return img.encodeJpg(decodedImage);
    }

    return image;
  }

  initLayer(layer) {
    undoLayers.clear();

    layers.add(layer);
    // tempLayers.add(layer);

    setState(() {});
  }

  BoxDecoration _decoration(bool left) {
    return BoxDecoration(
      color: Colors.grey.withOpacity(0.3),
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(left ? 0 : 19),
        bottomRight: Radius.circular(left ? 0 : 19),
        topLeft: Radius.circular(left ? 19 : 0),
        bottomLeft: Radius.circular(left ? 19 : 0),
      ),
    );
  }

  removeTextField() {
    if (layers.last is TextFieldLayerData) {
      layers.removeLast();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            centerTitle: false,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black,
            surfaceTintColor: Colors.white,
            elevation: 0,
            toolbarHeight: 56,
            iconTheme: const IconThemeData(
              color: Colors.black,
            ),
            titleSpacing: 0,
            title: (layers.isEmpty || layers.last is! TextFieldLayerData) ? appBarTitle() : textFieldAppBar(),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator.adaptive(),
                )
              : Stack(
                  children: [
                    GestureDetector(
                      onScaleUpdate: (details) {
                        // move
                        if (details.pointerCount == 1) {
                          x += details.focalPointDelta.dx;
                          y += details.focalPointDelta.dy;
                          setState(() {});
                        }

                        if (details.pointerCount == 2) {
                          if (details.horizontalScale != 1) {
                            scaleFactor = lastScaleFactor * math.min(details.horizontalScale, details.verticalScale);
                            setState(() {});
                          }
                        }
                      },
                      onScaleEnd: (details) {
                        lastScaleFactor = scaleFactor;
                      },
                      child: Center(
                        child: AnimatedContainer(
                          width: currentImage.width / pixelRatio,
                          height: currentImage.height / pixelRatio,
                          duration: Duration(milliseconds: duration),
                          child: Screenshot(
                            controller: screenshotController,
                            child: AnimatedRotation(
                              turns: rotateValue,
                              duration: Duration(milliseconds: duration),
                              child: Transform(
                                transform: Matrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, 0, 1 / scaleFactor)..rotateY(flipValue),
                                alignment: FractionalOffset.center,
                                child: LayersViewer(
                                  layers: layers,
                                  onUpdate: () {
                                    setState(() {});
                                  },
                                  editable: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (layers.length > 1)
                      Positioned(
                        bottom: 64,
                        left: 0,
                        child: Container(
                          height: 48,
                          width: 48,
                          alignment: Alignment.center,
                          decoration: _decoration(false),
                          child: IconButton(
                            iconSize: 20,
                            onPressed: () {
                              showModalBottomSheet(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10),
                                    topLeft: Radius.circular(10),
                                  ),
                                ),
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => SafeArea(
                                  child: ManageLayersOverlay(
                                    layers: layers,
                                    onUpdate: () => setState(() {}),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.layers),
                          ),
                        ),
                      ),
                    if (scaleFactor != 1)
                      Positioned(
                        bottom: 64,
                        right: 0,
                        child: Container(
                          height: 48,
                          width: 48,
                          alignment: Alignment.center,
                          decoration: _decoration(true),
                          child: IconButton(
                            iconSize: 20,
                            onPressed: () {
                              resetTransformation();
                            },
                            icon: Icon(
                              scaleFactor > 1 ? Icons.zoom_in_map : Icons.zoom_out_map,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
          bottomNavigationBar: Container(
            alignment: Alignment.bottomCenter,
            height: 86 + MediaQuery.of(context).padding.bottom,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.rectangle,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ############# 자르기 #############
                  BottomButton(
                    icon: Icons.crop,
                    text: i18n('자르기'),
                    onTap: () async {
                      removeTextField();

                      List<Layer> newLayers = [];
                      List<int> newIndex = [];

                      if (layers.length > 1) {
                        newLayers.add(layers.first);
                        for (int i = 0; i < layers.length; i++) {
                          if (layers[i] is ImageLayerData) {
                            newLayers.add(layers[i]);
                            newIndex.add(i);
                          }
                        }
                      }
                      if (newLayers.length > 1) {
                        showModalBottomSheet(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              topLeft: Radius.circular(10),
                            ),
                          ),
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SafeArea(
                            child: ManageLayersOverlay(
                              layers: newLayers,
                              isCrop: true,
                              newIndex: newIndex,
                              onUpdate: () => setState(() {}),
                            ),
                          ),
                        ).then(
                          (value) async {
                            if (value != null) {
                              // userInfoProvider.flipValue[index] = 0;
                              // userInfoProvider.rotateValue[index] = 0;

                              var imageItem = ImageItem(value[0]);
                              await imageItem.loader.future;

                              int layerIndex = layers.indexOf(value[1]);

                              layers[layerIndex] = value[2] ? BackgroundLayerData(image: imageItem) : ImageLayerData(image: imageItem);
                              setState(() {});
                            }
                          },
                        );
                      } else {
                        resetTransformation();
                        var loadingScreen = showLoadingScreen(context);
                        // var mergedImage = await getMergedImage();
                        loadingScreen.hide();

                        if (!mounted) return;

                        Uint8List? croppedImage = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageCropper(
                              image: (layers.first as BackgroundLayerData).image.bytes,
                            ),
                          ),
                        );

                        if (croppedImage == null) return;

                        // userInfoProvider.flipValue[index] = 0;
                        // userInfoProvider.rotateValue[index] = 0;

                        await currentImage.load(croppedImage);
                        setState(() {});
                      }
                    },
                  ),
                  // ############# 텍스트 #############
                  BottomButton(
                    icon: Icons.text_fields,
                    text: i18n('텍스트'),
                    onTap: () async {
                      TextLayerData? layer = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TextEditorImage(),
                        ),
                      );

                      if (layer == null) return;
                      initLayer(layer);
                    },
                  ),
                  // ############# 반전 #############
                  BottomButton(
                    icon: Icons.flip,
                    text: i18n('반전'),
                    onTap: () {
                      flipValue = flipValue == 0 ? math.pi : 0;
                      setState(() {});
                    },
                  ),
                  // ############# 회전 #############
                  BottomButton(
                    icon: Icons.rotate_left,
                    text: i18n('회전'),
                    onTap: () {
                      duration = 400;
                      var t = currentImage.width;
                      currentImage.width = currentImage.height;
                      currentImage.height = t;

                      rotateValue -= 1.0 / 4.0;
                      setState(() {});
                    },
                  ),
                  // ############# 회전 #############
                  BottomButton(
                    icon: Icons.rotate_right,
                    text: i18n('회전'),
                    onTap: () {
                      duration = 400;
                      var t = currentImage.width;
                      currentImage.width = currentImage.height;
                      currentImage.height = t;

                      rotateValue += 1.0 / 4.0;
                      setState(() {});
                    },
                  ),
                  // ############# 필터 #############
                  BottomButton(
                    icon: Icons.color_lens,
                    text: i18n('필터'),
                    onTap: () async {
                      removeTextField();
                      resetTransformation();

                      var loadingScreen = showLoadingScreen(context); // 로딩 ON
                      var mergedImage = await getMergedImage(); // overlay된 이미지들 병합

                      int filterIndex = -1;

                      // 이미 적용한 필터가 있는지 확인 (* 있다면 layers의 몇번째에 있는지 index 추출)
                      bool hasFilterLayer = layers.any((layer) {
                        bool isFilter = layer.runtimeType == FilterLayerData;
                        if (isFilter) {
                          filterIndex = layers.indexOf(layer);
                        }
                        return isFilter;
                      });

                      if (!mounted) return;

                      // 필터 적용 화면으로 이동 (적용한 필터를 return 받음, 없다면 null)
                      ColorFilterGenerator? filter = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageFilters(
                            image: mergedImage!,
                          ),
                        ),
                      );
                      loadingScreen.hide(); // 로딩 OFF

                      // 적용한 필터가 있으면
                      if (filter != null) {
                        // 필터 적용

                        // 이전에 적용했던 필더가 있으면 삭제 후 다시 추가
                        if (hasFilterLayer) {
                          layers.removeAt(filterIndex);
                        }
                        layers.add(
                          FilterLayerData(
                            image: currentImage,
                            filterColor: filter,
                          ),
                        );
                      }
                    },
                  ),
                  // ############# 이모지 #############
                  BottomButton(
                    icon: FontAwesomeIcons.faceSmile,
                    text: i18n('이모지'),
                    onTap: () async {
                      removeTextField();

                      EmojiLayerData? layer = await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.black,
                        builder: (BuildContext context) {
                          return const Emojies();
                        },
                      );

                      if (layer == null) return;

                      initLayer(layer);
                    },
                  ),
                  // ############# 사진 #############
                  BottomButton(
                    icon: FontAwesomeIcons.image,
                    text: i18n('사진'),
                    // icon: const Icon(Icons.photo, color: Colors.white),
                    onTap: () async {
                      removeTextField();

                      if (await Permission.photos.isPermanentlyDenied) {
                        openAppSettings();
                      }

                      var image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image == null) return;

                      // loadImage(image);

                      var imageItem = ImageItem(image);
                      await imageItem.loader.future;

                      layers.add(ImageLayerData(image: imageItem));
                      // tempLayers.add(ImageLayerData(image: imageItem));
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget appBarTitle() {
    return Row(
      children: [
        Row(
          children: [
            const SizedBox(width: 11),
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                Navigator.pop(context);
              },
              child: SizedBox(
                height: 34,
                child: Row(
                  children: [
                    const SizedBox(width: 5),
                    Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
                      child: Image.asset(
                        'assets/travel/backButton.png',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            )
          ],
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width - 48,
          child: SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  icon: Icon(Icons.undo, color: layers.length > 1 ? Colors.white : Colors.grey),
                  onPressed: () {
                    if (layers.length <= 1) return; // do not remove image layer
                    Layer removedLayer = layers.removeLast();

                    undoLayers.add(removedLayer);

                    setState(() {});
                  },
                ),
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  icon: Icon(Icons.redo, color: undoLayers.isNotEmpty ? Colors.white : Colors.grey),
                  onPressed: () {
                    if (undoLayers.isEmpty) return;
                    Layer redoLayer = undoLayers.removeLast();

                    layers.add(redoLayer);

                    setState(() {});
                  },
                ),
                Opacity(
                  opacity: 1,
                  child: IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: const Icon(Icons.refresh_outlined, color: Colors.white),
                    onPressed: () async {
                      // DialogComponent.dialogComponent(
                      //   context,
                      //   Text(style: TextStyle(fontSize: ),
                      //     '사진 초기화'.,
                      //     17,
                      //     fontWeight: FontWeight.w500,
                      //     textAlign: TextAlign.left,
                      //   ),
                      //   Padding(
                      //     padding: const EdgeInsets.only(left: 25, right: 25),
                      //     child: Text(style: TextStyle(fontSize: ),
                      //       '사진을 초기화하고 다시 선택하시겠습니까?'.,
                      //       14,
                      //       fontWeight: FontWeight.w500,
                      //       textAlign: TextAlign.left,
                      //     ),
                      //   ),
                      //   false,
                      //   [() => Navigator.pop(context), '아니오', Colors.red],
                      //   [
                      //     () async {
                      //       Navigator.pop(context);
                      //       getImage();
                      //     },
                      //     '예',
                      //     Colors.blue
                      //   ],
                      // );
                    },
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: () async {
                    resetTransformation();
                    setState(() {});

                    var loadingScreen = showLoadingScreen(context);

                    var editedImageBytes = await getMergedImage(widget.outputFormat);

                    loadingScreen.hide();

                    if (mounted) Navigator.pop(context, editedImageBytes);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget textFieldAppBar() {
    return Row(
      children: [
        const SizedBox(width: 11),
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            Navigator.pop(context);
          },
          child: SizedBox(
            height: 34,
            child: Row(
              children: [
                const SizedBox(width: 5),
                Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
                  child: Image.asset(
                    'assets/travel/backButton.png',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
        Expanded(child: Container()),
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            // Navigator.pop(context);
            layers.last = TextLayerData(
              text: (layers.last as TextFieldLayerData).controller.text,
              background: Colors.transparent,
              color: Colors.white,
              size: 32,
              align: TextAlign.left,
            );
            setState(() {});
          },
          child: const SizedBox(
            height: 34,
            child: Row(
              children: [
                SizedBox(width: 5),
                Text(
                  '완료',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 5),
              ],
            ),
          ),
        ),
        const SizedBox(width: 11),
      ],
    );
  }

  Future<void> getImage() async {
    // 갤러리로 연결
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    // 영상을 선택하지 않고 나왔을 경우
    if (pickedFile == null) return;

    if (mounted) {
      layers.clear();
      // tempLayers.clear();
      undoLayers.clear();

      rotateValue = 0;
      flipValue = 0;
      resetTransformation();

      var data = await rootBundle.load(pickedFile.path);
      await currentImage.load(data.buffer.asUint8List());
      layers.add(BackgroundLayerData(image: currentImage));
      // tempLayers.add(BackgroundLayerData(image: currentImage));
      setState(() {});
    }
  }
}

class FilterLayerData extends Layer {
  ImageItem image;
  ColorFilterGenerator filterColor;

  FilterLayerData({
    required this.image,
    required this.filterColor,
  });

  static FilterLayerData fromJson(Map json) {
    return FilterLayerData(
      image: ImageItem.fromJson(json['image']),
      filterColor: json['filter'],
    );
  }

  @override
  Map toJson() {
    return {
      'type': 'FilterLayer',
      'image': image.toJson(),
      'filter': filterColor,
    };
  }
}

class TextFieldLayerData extends Layer {
  TextEditingController controller;
  FocusNode focusNode;
  double size;
  double? imageWidth;

  TextFieldLayerData({
    required this.controller,
    required this.focusNode,
    required this.size,
    this.imageWidth,
  });
}
