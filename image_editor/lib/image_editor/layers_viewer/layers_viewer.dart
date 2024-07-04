import 'package:flutter/material.dart';
import 'package:image_editor/image_editor/layers_viewer/emoji_layer.dart';
import 'package:image_editor/image_editor/layers_viewer/image_layer.dart';
import 'package:image_editor/image_editor/layers_viewer/text_layer.dart';
import 'package:image_editor/image_editor/single_image_editor.dart';
import 'package:image_editor/main.dart';
import 'package:image_editor_plus/data/layer.dart';
import 'package:image_editor_plus/layers/background_layer.dart';

class LayersViewer extends StatelessWidget {
  final List<Layer> layers;
  final Function()? onUpdate;
  final bool editable;

  const LayersViewer({
    super.key,
    required this.layers,
    required this.editable,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: layers.map((layerItem) {
        // Background layer
        if (layerItem is BackgroundLayerData) {
          return selectedFilterColor.build(
            BackgroundLayer(
              layerData: layerItem,
              onUpdate: onUpdate,
              editable: editable,
            ),
          );
        }
        // if (layerItem is FilterLayerData) {
        //   return FilterLayer(
        //     layerData: layerItem,
        //     onUpdate: onUpdate,
        //     editable: editable,
        //   );
        // }

        // Image layer
        if (layerItem is ImageLayerData) {
          return ImageLayer(
            layerData: layerItem,
            onUpdate: onUpdate,
            editable: editable,
          );
        }

        // // Background blur layer
        // if (layerItem is BackgroundBlurLayerData && layerItem.radius > 0) {
        //   return BackgroundBlurLayer(
        //     layerData: layerItem,
        //     onUpdate: onUpdate,
        //     editable: editable,
        //   );
        // }

        // Emoji layer
        if (layerItem is EmojiLayerData) {
          return EmojiLayer(
            layerData: layerItem,
            onUpdate: onUpdate,
            editable: editable,
          );
        }

        // Text layer
        if (layerItem is TextLayerData) {
          return TextLayer(
            layerData: layerItem,
            onUpdate: onUpdate,
            editable: editable,
          );
        }

        // // Link layer
        // if (layerItem is LinkLayerData) {
        //   return LinkLayer(
        //     layerData: layerItem,
        //     onUpdate: onUpdate,
        //     editable: editable,
        //   );
        // }

        // Blank layer
        return Container();
      }).toList(),
    );
  }
  // Widget build(BuildContext context) {
  //   final vmw = context.watch<UserInfoProvider>();
  //   return Stack(
  //     alignment: Alignment.center,
  //     children: layers.map((layerItem) {
  //       // Background layer
  //       if (layerItem is BackgroundLayerData) {
  //         return vmw.selectedFilterColor.build(
  //           BackgroundLayer(
  //             layerData: layerItem,
  //             onUpdate: onUpdate,
  //             editable: editable,
  //           ),
  //         );
  //       }
  //       if (layerItem is FilterLayerData) {
  //         return vmw.selectedFilterColor.build(
  //           FilterLayer(
  //             layerData: layerItem,
  //             onUpdate: onUpdate,
  //             editable: editable,
  //           ),
  //         );
  //       }

  //       // Image layer
  //       if (layerItem is ImageLayerData) {
  //         return vmw.selectedFilterColor.build(
  //           ImageLayer(
  //             layerData: layerItem,
  //             onUpdate: onUpdate,
  //             editable: editable,
  //           ),
  //         );
  //       }

  //       // // Background blur layer
  //       // if (layerItem is BackgroundBlurLayerData && layerItem.radius > 0) {
  //       //   return BackgroundBlurLayer(
  //       //     layerData: layerItem,
  //       //     onUpdate: onUpdate,
  //       //     editable: editable,
  //       //   );
  //       // }

  //       // Emoji layer
  //       if (layerItem is EmojiLayerData) {
  //         return vmw.selectedFilterColor.build(
  //           EmojiLayer(
  //             layerData: layerItem,
  //             onUpdate: onUpdate,
  //             editable: editable,
  //           ),
  //         );
  //       }

  //       // Text layer
  //       if (layerItem is TextLayerData) {
  //         return vmw.selectedFilterColor.build(
  //           TextLayer(
  //             layerData: layerItem,
  //             onUpdate: onUpdate,
  //             editable: editable,
  //           ),
  //         );
  //       }

  //       // // Link layer
  //       // if (layerItem is LinkLayerData) {
  //       //   return LinkLayer(
  //       //     layerData: layerItem,
  //       //     onUpdate: onUpdate,
  //       //     editable: editable,
  //       //   );
  //       // }

  //       // Blank layer
  //       return Container();
  //     }).toList(),
  //   );
  // }
}

/// Main layer
class FilterLayer extends StatefulWidget {
  final FilterLayerData layerData;
  final VoidCallback? onUpdate;
  final bool editable;

  const FilterLayer({
    super.key,
    required this.layerData,
    this.onUpdate,
    this.editable = false,
  });

  @override
  State<FilterLayer> createState() => _FilterLayerState();
}

class _FilterLayerState extends State<FilterLayer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.layerData.image.width.toDouble(),
      height: widget.layerData.image.height.toDouble(),
      // color: black,
      padding: EdgeInsets.zero,
      child: Image.memory(widget.layerData.image.bytes),
    );
  }
}
