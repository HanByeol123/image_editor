// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor/edit_options/image_crop.dart';
import 'package:image_editor/image_editor/layers_viewer/emoji_layer_overlay.dart';
import 'package:image_editor/image_editor/layers_viewer/image_layer_overlay.dart';
import 'package:image_editor/image_editor/layers_viewer/text_layer_overlay.dart';
import 'package:image_editor/image_editor/single_image_editor.dart';
import 'package:image_editor_plus/data/layer.dart';
import 'package:image_editor_plus/loading_screen.dart';
import 'package:reorderables/reorderables.dart';

class ManageLayersOverlay extends StatefulWidget {
  final List<Layer> layers;
  final Function onUpdate;
  final bool isCrop;
  final List<int>? newIndex;
  // final List<AspectRatio>? availableRatios;
  final bool? reversible;

  const ManageLayersOverlay({
    super.key,
    required this.layers,
    required this.onUpdate,
    this.isCrop = false,
    this.newIndex,
    // this.availableRatios,
    this.reversible,
  });

  @override
  createState() => _ManageLayersOverlayState();
}

class _ManageLayersOverlayState extends State<ManageLayersOverlay> {
  var scrollController = ScrollController();
  late final List<Layer> _layers = widget.layers;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
      ),
      child: widget.isCrop
          ? ListView.builder(
              itemCount: _layers.length,
              itemBuilder: (context, index) {
                var layer = _layers.reversed.toList()[index];
                return GestureDetector(
                  key: Key('${_layers.indexOf(layer)}:${layer.runtimeType}'),
                  onTap: () {
                    if (layer is BackgroundLayerData) return;

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
                        if (layer is ImageLayerData) {
                          return ImageLayerOverlay(
                            index: _layers.indexOf(layer),
                            layerData: layer,
                            onUpdate: () {
                              widget.onUpdate();
                              setState(() {});
                            },
                          );
                        }

                        return Container();
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Center(
                            child: layer is ImageLayerData
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      layer.image.bytes,
                                      fit: BoxFit.cover,
                                      width: 40,
                                      height: 40,
                                    ),
                                  )
                                : layer is BackgroundLayerData
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          layer.image.bytes,
                                          fit: BoxFit.cover,
                                          width: 40,
                                          height: 40,
                                        ))
                                    : const Text(
                                        '',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 92 - 64,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                layer.runtimeType.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            Uint8List? image;
                            bool isBackground = false;
                            var loadingScreen = showLoadingScreen(context);

                            if (layer is BackgroundLayerData) {
                              image = layer.image.bytes;
                              isBackground = true;
                            } else if (layer is ImageLayerData) {
                              image = layer.image.bytes;
                              isBackground = false;
                            }

                            loadingScreen.hide();

                            if (!mounted) return;

                            Uint8List? croppedImage = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImageCropper(
                                  image: image!,
                                  // availableRatios: availableRatios,
                                ),
                              ),
                            );

                            if (croppedImage == null) return;
                            Navigator.pop(context, [croppedImage, layer, isBackground]);
                          },
                          icon: const Icon(
                            Icons.crop,
                            size: 22,
                            color: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            )
          : ReorderableColumn(
              onReorder: (oldIndex, newIndex) {
                int oi = _layers.length - 1 - oldIndex;
                int ni = _layers.length - 1 - newIndex;

                if (oi == 0 || ni == 0) {
                  return;
                }

                _layers.insert(ni, _layers.removeAt(oi));
                widget.onUpdate();
                setState(() {});
              },
              draggedItemBuilder: (context, index) {
                var layer = _layers[_layers.length - 1 - index];

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xff111111),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Center(
                          child: layer is TextLayerData || layer is EmojiLayerData
                              ? Text(
                                  layer is TextLayerData ? 'T' : (layer as EmojiLayerData).text,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w100,
                                  ),
                                )
                              : _buildImageLayerWidget(layer),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 92 - 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (layer is TextLayerData)
                              Text(
                                layer.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              )
                            else
                              Text(
                                layer.runtimeType.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (layer is! BackgroundLayerData)
                        IconButton(
                          onPressed: () {
                            _layers.remove(layer);
                            widget.onUpdate();
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete, size: 22, color: Colors.red),
                        )
                    ],
                  ),
                );
              },
              children: [
                for (var layer in _layers.reversed)
                  GestureDetector(
                    key: Key('${_layers.indexOf(layer)}:${layer.runtimeType}'),
                    onTap: () {
                      // 백그라운드와 필터는 수정 사항이 없으므로 바로 리턴
                      if (layer is BackgroundLayerData || layer is FilterLayerData) return;

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
                          if (layer is EmojiLayerData) {
                            // 이모티콘
                            return EmojiLayerOverlay(
                              index: _layers.indexOf(layer),
                              layer: layer,
                              onUpdate: () {
                                widget.onUpdate();
                                setState(() {});
                              },
                            );
                          }

                          if (layer is ImageLayerData) {
                            // 사진
                            return ImageLayerOverlay(
                              index: _layers.indexOf(layer),
                              layerData: layer,
                              onUpdate: () {
                                widget.onUpdate();
                                setState(() {});
                              },
                            );
                          }

                          if (layer is TextLayerData) {
                            // 텍스트
                            return TextLayerOverlay(
                              index: _layers.indexOf(layer),
                              layer: layer,
                              onUpdate: () {
                                widget.onUpdate();
                                setState(() {});
                              },
                            );
                          }

                          return Container();
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: Center(
                              child: layer is TextLayerData || layer is EmojiLayerData
                                  ? Text(
                                      layer is TextLayerData ? 'T' : (layer as EmojiLayerData).text,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w100,
                                      ),
                                    )
                                  : _buildImageLayerWidget(layer),
                            ),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 92 - 64,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (layer is LinkLayerData)
                                  Text(
                                    layer.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  )
                                else if (layer is TextLayerData)
                                  Text(
                                    layer.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  Text(
                                    layer.runtimeType.toString().replaceAll('LayerData', ''),
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (layer is! BackgroundLayerData) ...[
                            // 백그라운드를 제외한 나머지 레이어 삭제 기능
                            IconButton(
                              onPressed: () {
                                _layers.remove(layer);
                                widget.onUpdate();
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.delete,
                                size: 22,
                                color: Colors.red,
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildImageLayerWidget(dynamic layer) {
    if (layer is ImageLayerData || layer is BackgroundLayerData) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          layer.image.bytes,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
        ),
      );
    } else if (layer is FilterLayerData) {
      return const Icon(
        Icons.color_lens,
        color: Colors.white,
        size: 32,
      );
    } else {
      return const Text(
        '',
        style: TextStyle(
          color: Colors.white,
        ),
      );
    }
  }
}
