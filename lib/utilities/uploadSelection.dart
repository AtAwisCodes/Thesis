import 'package:image_picker/image_picker.dart';

pickVideo() async {
  final picker = ImagePicker();
  XFile? videoFile;

  try {
    videoFile = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    return videoFile?.path;
  } catch (e) {
    print("Error picking video: $e");
  }
}
