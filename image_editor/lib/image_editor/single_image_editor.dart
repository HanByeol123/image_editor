// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously, type_literal_in_constant_pattern

import 'dart:async';
import 'dart:math' as math;

import 'package:colorfilter_generator/colorfilter_generator.dart';
import 'package:colorfilter_generator/presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_editor/image_editor/edit_options/image_crop.dart';
import 'package:image_editor/image_editor/edit_options/image_filter.dart';
import 'package:image_editor/image_editor/edit_options/options.dart';
import 'package:image_editor/image_editor/image_editor_plus.dart';
import 'package:image_editor/image_editor/layers_overlay.dart';
import 'package:image_editor/image_editor/layers_viewer/layers_viewer.dart';
import 'package:image_editor/main.dart';
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

    if (previousLayer.isNotEmpty) {
      // 이전에 저장한 레이어가 있을 경우
      loadImages();
    } else if (widget.image != null) {
      // 이전에 저장한 레이어가 없을 경우
      loadImage();
    }

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

  Future<void> loadImages() async {
    // currentImage.load: 초기 이미지를 설정해줘야 에러가 발생하지 않음
    // 백그라운드를 초기 이미지로 설정
    await currentImage.load((previousLayer.first as BackgroundLayerData).image.bytes);

    for (int i = 0; i < previousLayer.length; i++) {
      if (i == 0) {
        layers.clear();
      }
      // 레이어를 순차적으로 추가
      switch (previousLayer[i].runtimeType) {
        case BackgroundLayerData:
          layers.add(BackgroundLayerData(image: currentImage));
          break;
        case FilterLayerData:
          selectedFilterColor = (previousLayer[i] as FilterLayerData).filterColor;

          layers.add(
            FilterLayerData(
              image: currentImage,
              filterColor: (previousLayer[i] as FilterLayerData).filterColor, // 필터색
            ),
          );
          break;
        case ImageLayerData:
          final layerData = (previousLayer[i] as ImageLayerData);
          var imageItem = ImageItem(layerData.image.bytes);
          await imageItem.loader.future;
          ImageLayerData layer = ImageLayerData(
            image: imageItem, // 이미지
            size: layerData.size, // 이미지 사이즈
            scale: layerData.scale, // 이미지 규모
            rotation: layerData.rotation, // 회전된 방향
            offset: layerData.offset, // 위치
            opacity: layerData.opacity, // 투명도
          );

          layers.add(layer); // 이미지 레이터 추가
          break;
        case TextLayerData:
          final layerData = (previousLayer[i] as TextLayerData);
          TextLayerData layer = TextLayerData(
            text: layerData.text, // 입력된 텍스트
            align: layerData.align, // 텍스트 시작점
            background: layerData.background, // 배경색
            backgroundOpacity: layerData.backgroundOpacity, // 배경 투명도
            color: layerData.color, // 텍스트색
            offset: layerData.offset, // 위치
            opacity: layerData.opacity, // 투명도
            rotation: layerData.rotation, // 회전 방향
            scale: layerData.scale, // 규모
            size: layerData.size, // 크기
          );
          layers.add(layer); // 텍스트 레이어 추가
          break;
        case EmojiLayerData:
          final layerData = (previousLayer[i] as EmojiLayerData);
          EmojiLayerData layer = EmojiLayerData(
            text: layerData.text, // 이모티콘
            size: layerData.size, // 사이즈
            scale: layerData.scale, // 규모
            rotation: layerData.rotation, // 회전 방향
            offset: layerData.offset, // 위치
            opacity: layerData.opacity, // 투명도
          );
          layers.add(layer); // 이모티콘 레이어 추가
          break;
      }
    }
    setState(() {});
  }

  Future<void> loadImage() async {
    await currentImage.load(widget.image!);
    layers.clear();
    layers.add(BackgroundLayerData(image: currentImage));
    setState(() {});
  }

  // 확대 축소 초기화
  resetTransformation() {
    scaleFactor = 1;
    x = 0;
    y = 0;
    setState(() {});
  }

  // 이미지 병함
  Future<Uint8List?> getMergedImage([
    OutputFormat format = OutputFormat.png,
  ]) async {
    Uint8List? image;

    if (flipValue != 0 || rotateValue != 0 || layers.length > 1) {
      image = await screenshotController.capture(pixelRatio: pixelRatio);
    } else if (layers.length == 1) {
      if (layers.first is BackgroundLayerData) {
        image = (layers.first as BackgroundLayerData).image.bytes;
      } else if (layers.first is ImageLayerData) {
        image = (layers.first as ImageLayerData).image.bytes;
      }
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
            title: appBarTitle(),
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

                    // 추가한 레이어가 있으면
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
                              // 추가한 레이어 데이터 바텀시트
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

                    // 축소 확대 초기화
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
                  bottomButton(
                    Icons.crop,
                    i18n('자르기'),
                    () async {
                      List<Layer> newLayers = [];
                      List<int> newIndex = [];

                      // 백그라운드라 이미지 두 레이어를 제외한 나머지는 자르기 기능이 필요 없을거 같음
                      // 추가한 레이어가 있으면
                      if (layers.length > 1) {
                        // 첫번째는 무조건 백그라운드 이미지여서 고정적으로 add
                        newLayers.add(layers.first);
                        for (int i = 0; i < layers.length; i++) {
                          // 이후 이미지만 골라서 add
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
                            // 이미지를 자르고 나왔을 경우
                            if (value != null) {
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
                  bottomButton(
                    Icons.text_fields,
                    i18n('텍스트'),
                    () async {
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
                  bottomButton(
                    Icons.flip,
                    i18n('반전'),
                    () {
                      flipValue = flipValue == 0 ? math.pi : 0;
                      setState(() {});
                    },
                  ),
                  // ############# 회전 #############
                  bottomButton(
                    Icons.rotate_left,
                    i18n('회전'),
                    () {
                      duration = 400;
                      var t = currentImage.width;
                      currentImage.width = currentImage.height;
                      currentImage.height = t;

                      rotateValue -= 1.0 / 4.0;
                      setState(() {});
                    },
                  ),
                  // ############# 회전 #############
                  bottomButton(
                    Icons.rotate_right,
                    i18n('회전'),
                    () {
                      duration = 400;
                      var t = currentImage.width;
                      currentImage.width = currentImage.height;
                      currentImage.height = t;

                      rotateValue += 1.0 / 4.0;
                      setState(() {});
                    },
                  ),
                  // ############# 필터 #############
                  bottomButton(
                    Icons.color_lens,
                    i18n('필터'),
                    () async {
                      resetTransformation();

                      var loadingScreen = showLoadingScreen(context); // 로딩 ON
                      var mergedImage = await getMergedImage(); // overlay된 이미지들 병합

                      int filterIndex = -1;

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

                      // 이미 적용한 필터가 있는지 확인 (* 있다면 layers의 몇번째에 있는지 index 추출)
                      bool hasFilterLayer = layers.any((layer) {
                        bool isFilter = layer.runtimeType == FilterLayerData;
                        if (isFilter) {
                          filterIndex = layers.indexOf(layer);
                        }
                        return isFilter;
                      });

                      loadingScreen.hide(); // 로딩 OFF

                      // 적용한 필터가 있으면
                      if (filter != null) {
                        // 필터 적용
                        selectedFilterColor = filter;

                        final filterLayer = FilterLayerData(
                          image: currentImage,
                          filterColor: filter,
                        );

                        if (hasFilterLayer) {
                          // 이전에 적용했던 필더가 있으면 그 자리를 새로운 필터로 대체
                          layers[filterIndex] = filterLayer;
                        } else {
                          // 아니면 추가
                          layers.add(filterLayer);
                        }
                        setState(() {});
                      }
                    },
                  ),
                  // ############# 이모지 #############
                  bottomButton(
                    FontAwesomeIcons.faceSmile,
                    i18n('이모지'),
                    () async {
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
                  bottomButton(
                    FontAwesomeIcons.image,
                    i18n('사진'),
                    () async {
                      if (await Permission.photos.isPermanentlyDenied) {
                        openAppSettings();
                      }

                      var image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image == null) return;

                      var imageItem = ImageItem(image);
                      await imageItem.loader.future;

                      layers.add(ImageLayerData(image: imageItem));
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
        const BackButton(
          color: Colors.white,
        ),
        Expanded(child: Container()),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: Icon(Icons.undo, color: layers.length > 1 ? Colors.white : Colors.grey),
          onPressed: () {
            if (layers.length <= 1) return; // do not remove image layer
            Layer removedLayer = layers.removeLast();

            if (removedLayer is FilterLayerData) {
              undoFilterColor = selectedFilterColor;
              selectedFilterColor = PresetFilters.none;
              setState(() {});
            }

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

            if (redoLayer is FilterLayerData) {
              selectedFilterColor = undoFilterColor;
              undoFilterColor = PresetFilters.none;
            }

            layers.add(redoLayer);

            setState(() {});
          },
        ),
        IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          icon: const Icon(Icons.check, color: Colors.white),
          onPressed: () async {
            previousLayer = [];
            previousLayer = List.from(layers);
            resetTransformation();
            setState(() {});

            var loadingScreen = showLoadingScreen(context);

            var editedImageBytes = await getMergedImage(widget.outputFormat);

            loadingScreen.hide();

            if (mounted) Navigator.pop(context, editedImageBytes);
          },
        ),
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

  Widget bottomButton(IconData icon, String text, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
