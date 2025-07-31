import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/user_data_service.dart';

class DataCollectionScreen extends StatefulWidget {
  const DataCollectionScreen({super.key});

  @override
  State<DataCollectionScreen> createState() => _DataCollectionScreenState();
}

class _DataCollectionScreenState extends State<DataCollectionScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentsController = TextEditingController();
  Uint8List? _photoBytes;
  bool isSubmitting = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 75);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes = bytes;
      });
    }
  }

  Future<void> _submitData() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    final isOnline = await Connectivity().checkConnectivity() != ConnectivityResult.none;

    final id = const Uuid().v4();

    String? localImagePath;
    String? localImageUrl;
    if (_photoBytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${dir.path}/feedback_images');
      await imageDir.create(recursive: true);
      final imageFile = File('${imageDir.path}/$id.png');
      await imageFile.writeAsBytes(_photoBytes!);
      localImagePath = imageFile.path;
      localImageUrl = ''; 
    }

    // Save user data locally to PowerSync DB
    await saveUserData(
      recordid: id,
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      comments: _commentsController.text.trim(),
      imagePath: localImagePath,
      imageUrl: localImageUrl,
    );

    // Reset UI
    setState(() {
      isSubmitting = false;
      _emailController.clear();
      _nameController.clear();
      _phoneController.clear();
      _commentsController.clear();
      _photoBytes = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data saved successfully")));
    Navigator.of(context).pop(true);
  }

  Future<String?> uploadImageToServer(Uint8List imageBytes, String recordId) async {
    try {
      final uri = Uri.parse("https://382142cde869.ngrok-free.app/upload"); 

      final request = http.MultipartRequest('POST', uri)
        ..fields['id'] = recordId
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: '$recordId.png',
            contentType: MediaType('image', 'png'),
          ),
        );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final decoded = jsonDecode(responseBody);
        debugPrint("iamge url ${decoded['imageUrl']}");
        return decoded['imageUrl'];
      } else {
        debugPrint('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    }
    return null;
  }

  
@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Collection"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: "Phone",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentsController,
                    decoration: const InputDecoration(
                      labelText: "Comments",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  if (_photoBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:  Image.memory(_photoBytes!, height: 150,fit: BoxFit.cover,),
                    )
                  else
                    const Text("No image selected", textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text("Capture Photo"),
                    onPressed: _pickImage,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSubmitting ? "Submitting..." : "Submit"),
                    onPressed: isSubmitting ? null : _submitData,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
