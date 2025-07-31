import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class ImageUploadService {
  static Future<String?> uploadImage(Uint8List photoBytes, String filename) async {
    final uri = Uri.parse('https://382142cde869.ngrok-free.app/upload'); 
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        photoBytes,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final decoded = json.decode(body);
        return decoded['imageUrl']; 
      } else {
        print('Image upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
