import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploadHelper {
  static const String _imgbbApiKey = '35e23c1d07b073e59906736c89bb77c5';

  static Future<String> uploadImageToImgBB(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('https://api.imgbb.com/1/upload'),
      body: {
        'key': _imgbbApiKey,
        'image': base64Image,
        'name': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 200 && body['data'] != null) {
      return body['data']['url'];
    } else {
      throw Exception('Image upload failed: ${body['error']['message']}');
    }
  }
}
