import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../sync/powersync_client.dart';

Future<void> saveUserData({
  required String recordid,
  required String email,
  required String name,
  required String phone,
  required String comments,
  String? imagePath,
  String? imageUrl,
}) async {

  final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  await db.execute(
    '''
    INSERT INTO feedback (
      id, user_id, email, name, phone, comments, created_at, synced, image_path, image_url
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      recordid,
      'YT3481v14PEBLtjK72vHdMkmwYcqISar@clients',
      email,
      name,
      phone,
      comments,
      createdAt,
      0,
      imagePath,
      imageUrl
    ],
  );
  print('Data inserted to PowerSync local DB: $email');

  await fetchAllUserData();
}

Future<void> fetchAllUserData() async {
   final results = await db.execute('SELECT * FROM feedback');
  for (var row in results) {
    print('Fetched user data: ${row['email']}');
  }
}

 


