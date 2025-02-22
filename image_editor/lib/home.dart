import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor/image_editor_plus.dart';
import 'package:image_editor_plus/data/layer.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

List<Layer> layers = [], undoLayers = [], removedLayers = [];

class _HomeState extends State<Home> {
  Uint8List? imageData;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageData != null)
              Image.memory(
                imageData!,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    getImage();
                  },
                  child: const Text('Select Image'),
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () async {
                    var editedImage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageEditor(image: imageData),
                      ),
                    );

                    if (editedImage != null) {
                      print('Not Null');
                      imageData = editedImage;
                      setState(() {});
                    }
                  },
                  child: const Text('Image Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getImage() async {
    try {
      // 갤러리로 연결
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      // 영상을 선택하지 않고 나왔을 경우
      if (pickedFile == null) return;

      if (mounted) {
        var data = await rootBundle.load(pickedFile.path);
        setState(() => imageData = data.buffer.asUint8List());
      }
    } catch (e) {
      print(e);
    }
  }
}
