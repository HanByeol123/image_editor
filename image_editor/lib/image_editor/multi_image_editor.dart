// ignore_for_file: depend_on_referenced_packages, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_editor/image_editor/edit_options/options.dart';
import 'package:image_editor/image_editor/image_editor_plus.dart';
import 'package:image_editor/image_editor/single_image_editor.dart';
import 'package:image_editor_plus/data/image_item.dart';
import 'package:permission_handler/permission_handler.dart';

class MultiImageEditor extends StatefulWidget {
  final List images;
  final ImagePickerOption imagePickerOption;

  const MultiImageEditor({
    super.key,
    this.images = const [],
    this.imagePickerOption = const ImagePickerOption(),
  });

  @override
  createState() => _MultiImageEditorState();
}

class _MultiImageEditorState extends State<MultiImageEditor> {
  List<ImageItem> images = [];
  PermissionStatus galleryPermission = PermissionStatus.permanentlyDenied, cameraPermission = PermissionStatus.permanentlyDenied;

  late bool _isLoading = true;
  late List<int> removedIndex = [];

  checkPermissions() async {
    if (widget.imagePickerOption.pickFromGallery) {
      galleryPermission = await Permission.photos.status;
    }

    if (widget.imagePickerOption.captureFromCamera) {
      cameraPermission = await Permission.camera.status;
    }

    setState(() {});
  }

  @override
  void initState() {
    images = widget.images.map((e) => ImageItem(e)).toList();
    checkPermissions();

    _isLoading = false;
    setState(() {});

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    viewportSize = MediaQuery.of(context).size;

    return _isLoading
        ? const Center(
            child: CircularProgressIndicator.adaptive(),
          )
        : Theme(
            data: theme,
            child: Scaffold(
              appBar: AppBar(
                // automaticallyImplyLeading: false,
                actions: [
                  const BackButton(),
                  const Spacer(),
                  IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      Navigator.pop(context, [images, removedIndex]);
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: GridView.builder(
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1 / 1.6,
                    crossAxisSpacing: 1.0,
                    mainAxisSpacing: 3.0,
                  ),
                  controller: ScrollController(keepScrollOffset: false),
                  itemCount: images.length,
                  itemBuilder: (context, index) => _selectedItems(index),
                ),
              ),
            ),
          );
  }

  Widget _selectedItems(int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            var img = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SingleImageEditor(
                  image: images[index],
                  outputFormat: OutputFormat.jpeg,
                ),
              ),
            );

            // print(img);

            if (img != null) {
              images[index].load(img);
              setState(() {});
            }
          },
          child: Container(
            width: MediaQuery.of(context).size.width / 3,
            // height: 200,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.white.withAlpha(80)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                images[index].bytes,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 7,
          right: 7,
          child: Container(
            height: 25,
            width: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(60),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              iconSize: 20,
              padding: const EdgeInsets.all(0),
              onPressed: () {
                images.remove(images[index]);
                removedIndex.add(index);
                setState(() {});
              },
              icon: const Icon(Icons.clear_outlined),
            ),
          ),
        ),
      ],
    );
  }
}
