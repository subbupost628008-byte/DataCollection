import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'db_schema.dart';
import 'my_backend_connector.dart';

late PowerSyncDatabase db;

Future<void> initPowerSync() async {
  final dir = await getApplicationSupportDirectory();
  final path = join(dir.path, 'powersync.db');

  db = PowerSyncDatabase(schema: userSchema, path: path);

  await db.initialize();

  await db.connect(connector: MyBackendConnector(db));


  print('PowerSync initialized and connected.');
}
