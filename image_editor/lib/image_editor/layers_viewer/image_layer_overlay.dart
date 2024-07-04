import 'package:flutter/material.dart';
import 'package:image_editor/home.dart';
import 'package:image_editor/image_editor/image_editor_plus.dart';
import 'package:image_editor_plus/data/layer.dart';
// import 'package:image_editor_plus/image_editor_plus.dart';

class ImageLayerOverlay extends StatefulWidget {
  final int index;
  final ImageLayerData layerData;
  final Function onUpdate;

  const ImageLayerOverlay({
    super.key,
    required this.layerData,
    required this.index,
    required this.onUpdate,
  });

  @override
  createState() => _ImageLayerOverlayState();
}

class _ImageLayerOverlayState extends State<ImageLayerOverlay> {
  double slider = 0.0;

  @override
  Widget build(BuildContext context) {
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
              i18n('크기 조정'),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
          Slider(
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
              value: widget.layerData.scale,
              min: 0,
              max: 2,
              divisions: 100,
              onChangeEnd: (v) {
                setState(() {
                  widget.layerData.scale = v.toDouble();
                  widget.onUpdate();
                });
              },
              onChanged: (v) {
                setState(() {
                  slider = v;
                  // print(v.toDouble());
                  widget.layerData.scale = v.toDouble();
                  widget.onUpdate();
                });
              }),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  removedLayers.add(layers.removeAt(widget.index));
                  Navigator.pop(context);
                  widget.onUpdate();
                },
                child: Text(
                  i18n('제거'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
