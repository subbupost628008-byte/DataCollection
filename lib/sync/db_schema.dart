import 'package:powersync/powersync.dart';

final userSchema = Schema(([
  Table('feedback', [
    Column('user_id', ColumnType.text),
    Column('email', ColumnType.text),
    Column('name', ColumnType.text),
    Column('phone', ColumnType.text),
    Column('comments', ColumnType.text),
    Column('created_at', ColumnType.integer),
    Column('synced', ColumnType.integer),
    Column('image_path', ColumnType.text), // Local file path
    Column('image_url', ColumnType.text),  // Uploaded image URL
  ]),
]));

