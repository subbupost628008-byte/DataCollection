import 'package:data_collection_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'sync/powersync_client.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initPowerSync();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); //

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Feedback App',
      home: const HomeScreen(),
    );
  }
}
