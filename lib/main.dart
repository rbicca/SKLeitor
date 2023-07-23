import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'sk_leitor.dart';
import 'sk_leitor_globals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leitor MLKit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'POC Leitor MLKit'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String codigo = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'POC Leitor MLKit',
            ),
            Text(codigo),
            ElevatedButton(
              onPressed: _openBarcodeReader,
              child: const Icon(Icons.camera_alt),
            )
          ],
        ),
      ),
    );
  }

  _openBarcodeReader() async {
    MediaQueryData queryData = MediaQuery.of(context);

    double altura =
        SKLeitor.getOrientation(queryData.size) == Orientation.landscape
            ? queryData.size.height
            : queryData.size.width;
    double largura =
        SKLeitor.getOrientation(queryData.size) == Orientation.landscape
            ? queryData.size.width
            : queryData.size.height;

    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (BuildContext context) {
      return SKLeitor(altura: altura, largura: largura);
    }));

    if (result != null) {
      setState(() {
        codigo = result;
      });
    }
  }
}
