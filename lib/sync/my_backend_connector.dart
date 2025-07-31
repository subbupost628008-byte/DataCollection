import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:powersync/powersync.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyBackendConnector extends PowerSyncBackendConnector {
  final PowerSyncDatabase db;
  MyBackendConnector(this.db);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    try {
      final tokenResponse = await http.post(
        Uri.parse('https://382142cde869.ngrok-free.app/get-token'),
      );

      if (tokenResponse.statusCode != 200) {
        print('Failed to fetch token: ${tokenResponse.body}');
        return null;
      }

      final token = jsonDecode(tokenResponse.body)['access_token'];

      final userId = parseUserIdFromToken(token);

      return PowerSyncCredentials(
        endpoint: 'https://688710b6185ab57fcd7b4646.powersync.journeyapps.com',
        token: token,
        userId: userId,
      );
    } catch (e) {
      print('Error fetching PowerSync credentials: $e');
      return null;
    }
  }

  String parseUserIdFromToken(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return '';
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final jsonMap = jsonDecode(payload);
    return jsonMap['sub'] ?? '';
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    for (var op in transaction.crud) {
      switch (op.op) {
        case UpdateType.put:
          print('UpdateType.put');

          final response = await http.post(
            Uri.parse('https://382142cde869.ngrok-free.app/powersync/crud'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'transaction_id': transaction.transactionId,
              'operations': transaction.crud.map((op) => op.toJson()).toList(),
            }),
          );

          if (response.statusCode == 200) {
            await transaction.complete();
            print('Synced to server');

            print('Transaction datas: ${op.toJson()}');
            final Map<String, dynamic> json = op.toJson();
            final imagePath = json['data']['image_path'];
          
            Uint8List? imageBytes;

            if (imagePath != null &&
                imagePath is String &&
                File(imagePath).existsSync()) {
              imageBytes = await File(imagePath).readAsBytes();
             
              print('Image loaded. Size: ${imageBytes.length}');
               await uploadImageToServer(imageBytes,  json['id']);
            } else {
              print('Image file not found at path: $imagePath');
            }
            //await fetchAllUserData();
          } else {
            print('Failed to sync. Status: ${response.statusCode}');
          }
        case UpdateType.patch:
          print('UpdateType.patch');

        // TODO: Instruct your backend API to PATCH a record
        case UpdateType.delete:
        //TODO: Instruct your backend API to DELETE a record
      }
    }

    // Completes the transaction and moves onto the next one
    await transaction.complete();
  }

   Future<String?> uploadImageToServer(Uint8List imageBytes, String recordId) async {
    print('Image loaded. Size: ${imageBytes.length}');
     print('recordId .$recordId');
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
}
