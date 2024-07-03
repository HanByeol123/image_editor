// ignore_for_file: depend_on_referenced_packages

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hand_signature/signature.dart';
import 'package:image_editor/image_editor/image_editor_plus.dart';
import 'package:image_editor_plus/data/image_item.dart';
import 'package:image_editor_plus/loading_screen.dart';
import 'package:image_editor_plus/options.dart' as o;
import 'package:screenshot/screenshot.dart';

class ImageEditorDrawing extends StatefulWidget {
  final ImageItem image;
  final o.BrushOption options;

  const ImageEditorDrawing({
    super.key,
    required this.image,
    this.options = const o.BrushOption(
      showBackground: true,
      translatable: true,
    ),
  });

  @override
  State<ImageEditorDrawing> createState() => _ImageEditorDrawingState();
}

class _ImageEditorDrawingState extends State<ImageEditorDrawing> {
  Color pickerColor = Colors.white, currentColor = Colors.white, currentBackgroundColor = Colors.black;
  var screenshotController = ScreenshotController();

  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  List<CubicPath> undoList = [];
  bool skipNextEvent = false;

  void changeColor(o.BrushColor color) {
    currentColor = color.color;
    currentBackgroundColor = color.background;

    setState(() {});
  }

  @override
  void initState() {
    control.addListener(() {
      if (control.hasActivePath) return;

      if (skipNextEvent) {
        skipNextEvent = false;
        return;
      }

      undoList = [];
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.clear),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(
                Icons.undo,
                color: control.paths.isNotEmpty ? Colors.white : Colors.white.withAlpha(80),
              ),
              onPressed: () {
                if (control.paths.isEmpty) return;
                skipNextEvent = true;
                undoList.add(control.paths.last);
                control.stepBack();
                setState(() {});
              },
            ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: Icon(
                Icons.redo,
                color: undoList.isNotEmpty ? Colors.white : Colors.white.withAlpha(80),
              ),
              onPressed: () {
                if (undoList.isEmpty) return;

                control.paths.add(undoList.removeLast());
                setState(() {});
              },
            ),
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (control.paths.isEmpty) return Navigator.pop(context);

                if (widget.options.translatable) {
                  var data = await control.toImage(
                    color: currentColor,
                    height: widget.image.height,
                    width: widget.image.width,
                  );

                  if (!mounted) return;

                  return Navigator.pop(context, data!.buffer.asUint8List());
                }

                var loadingScreen = showLoadingScreen(context);
                var image = await screenshotController.capture();
                loadingScreen.hide();

                if (!mounted) return;

                return Navigator.pop(context, image);
              },
            ),
          ],
        ),
        body: Screenshot(
          controller: screenshotController,
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: widget.options.showBackground ? null : currentBackgroundColor,
              image: widget.options.showBackground
                  ? DecorationImage(
                      image: Image.memory(widget.image.bytes).image,
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            child: HandSignature(
              control: control,
              color: currentColor,
              width: 1.0,
              maxWidth: 7.0,
              type: SignatureDrawType.shape,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(blurRadius: 2),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                ColorButton(
                  color: Colors.yellow,
                  onTap: (color) {
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
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(
                                MediaQuery.of(context).size.width / 2,
                              ),
                              topRight: Radius.circular(
                                MediaQuery.of(context).size.width / 2,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: ColorPicker(
                              wheelDiameter: MediaQuery.of(context).size.width - 64,
                              color: currentColor,
                              pickersEnabled: const {
                                ColorPickerType.both: false,
                                ColorPickerType.primary: false,
                                ColorPickerType.accent: false,
                                ColorPickerType.bw: false,
                                ColorPickerType.custom: false,
                                ColorPickerType.customSecondary: false,
                                ColorPickerType.wheel: true,
                              },
                              enableShadesSelection: false,
                              onColorChanged: (color) {
                                currentColor = color;
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                for (var color in widget.options.colors)
                  ColorButton(
                    color: color.color,
                    onTap: (color) {
                      currentColor = color;
                      setState(() {});
                    },
                    isSelected: color.color == currentColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HandSignature extends StatelessWidget {
  final HandSignatureControl control;
  final Color color;
  final double width;
  final double maxWidth;
  final SignatureDrawType type;
  final Set<PointerDeviceKind>? supportedDevices;
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;

  const HandSignature({
    super.key,
    required this.control,
    this.color = Colors.black,
    this.width = 1.0,
    this.maxWidth = 10.0,
    this.type = SignatureDrawType.shape,
    this.onPointerDown,
    this.onPointerUp,
    this.supportedDevices,
  });

  void _startPath(Offset point) {
    if (!control.hasActivePath) {
      onPointerDown?.call();
      control.startPath(point);
    }
  }

  void _endPath(Offset point) {
    if (control.hasActivePath) {
      control.closePath();
      onPointerUp?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          _SingleGestureRecognizer: GestureRecognizerFactoryWithHandlers<_SingleGestureRecognizer>(
            () => _SingleGestureRecognizer(debugOwner: this, supportedDevices: supportedDevices),
            (instance) {
              print(1);
              instance.onStart = (position) => _startPath(position);
              instance.onUpdate = (position) => control.alterPath(position);
              instance.onEnd = (position) => _endPath(position);
            },
          ),
        },
        child: HandSignaturePaint(
          control: control,
          color: color,
          strokeWidth: width,
          maxStrokeWidth: maxWidth,
          type: type,
          onSize: control.notifyDimension,
        ),
      ),
    );
  }
}

class _SingleGestureRecognizer extends OneSequenceGestureRecognizer {
  @override
  String get debugDescription => 'single_gesture_recognizer';

  ValueChanged<Offset>? onStart;
  ValueChanged<Offset>? onUpdate;
  ValueChanged<Offset>? onEnd;

  bool pointerActive = false;

  _SingleGestureRecognizer({
    super.debugOwner,
    Set<PointerDeviceKind>? supportedDevices,
  }) : super(
          supportedDevices: supportedDevices ?? PointerDeviceKind.values.toSet(),
        );

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (pointerActive) {
      return;
    }

    startTrackingPointer(event.pointer, event.transform);
  }

  @override
  void handleEvent(PointerEvent event) {
    print(event.runtimeType);

    if (event is PointerMoveEvent) {
      onUpdate?.call(event.localPosition);
      print(event.localPosition);
    } else if (event is PointerDownEvent) {
      pointerActive = true;
      onStart?.call(event.localPosition);
      print(event.localPosition);
    } else if (event is PointerUpEvent) {
      pointerActive = false;
      onEnd?.call(event.localPosition);
      print(event.localPosition);
    } else if (event is PointerCancelEvent) {
      pointerActive = false;
      onEnd?.call(event.localPosition);
      print(event.localPosition);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
