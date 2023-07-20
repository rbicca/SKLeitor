// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'barcode_utils.dart';
import 'colors.dart';
import 'globals.dart';
import 'line_painter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

// ignore: must_be_immutable
class CodigoBarras extends StatefulWidget {
  double altura;
  double largura;

  CodigoBarras({super.key, required this.altura, required this.largura});

  @override
  State<StatefulWidget> createState() => CodigoBarrasState();
}

class CodigoBarrasState extends State<CodigoBarras>
    with TickerProviderStateMixin {
  late CameraController controller;
  final BarcodeScanner _barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  bool isBarrasFound = false;
  late String barcode;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: <SystemUiOverlay>[]);
    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );

    if (Platform.isAndroid) {
      controller.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
      SystemChrome.setPreferredOrientations(
        <DeviceOrientation>[
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ],
      );
    } else {
      controller.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
      SystemChrome.setPreferredOrientations(
        <DeviceOrientation>[
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
    }

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      iniciateStream();
      setState(() {});
    });
  }

  //Inicia a transmissão de imagem
  iniciateStream() async {
    controller.startImageStream((CameraImage image) async {
      if (isBarrasFound) {
        controller.dispose();
        Future.delayed(Duration.zero, () {
          codigoBarras = barcode;
          //Navigator.of(context).popAndPushNamed(PagamentoPage.routeName);
          print('BARRAS!!!!  $codigoBarras');
        });
        return;
      }
      if (_isProcessing) return;
      _isProcessing = true;
      try {
        String codigo = await detectarCodigoBarras(image);
        if (codigo != '') {
          setState(() {
            isBarrasFound = true;
            print('FOUND   $codigo');
            barcode = codigo;
          });
        }
      } catch (e) {
        print("Erro >> $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  //Trata o retorno da transmisão de imagem
  // ignore: missing_return
  Future<String> detectarCodigoBarras(CameraImage image) async {
    final InputImageMetadata metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow);

    final imagem =
        InputImage.fromBytes(bytes: image.planes[0].bytes, metadata: metadata);

    final List<Barcode> barcodes = await _barcodeScanner.processImage(imagem);
    if (barcodes.isNotEmpty) {
      // Barcode(s) detected. Handle the results as needed.
      for (Barcode barcode in barcodes) {
        print("Barcode value: ${barcode.value}");
        // Do something with the barcode value.
        if (validateBoleto(barcode.value as String)) {
          return barcode.value as String;
        }
      }
      _barcodeScanner.close();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (controller.cameraId < 0) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Posicione a linha sobre o código de barras'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Cores.BRANCO,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 150),
            color: Cores.AZUL_ALPHA,
            child: RotatedBox(
              quarterTurns: 0,
              child: Transform.scale(
                scale: getCameraScale(
                    MediaQuery.of(context), controller.value.previewSize),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    // ignore: unnecessary_null_comparison
                    child: controller.cameraId >= 0
                        ? CameraPreview(controller)
                        : Container(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints.expand(),
            child: CustomPaint(
              painter: LinePainter(
                windowSize: Size(widget.largura, widget.altura),
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.only(bottom: 10),
            child: _button(),
          ),
        ],
      ),
    );
  }

  _button() {
    return Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        width: 250,
        height: 50,
        decoration: BoxDecoration(
          color: Cores.AMARELO_MEDIO,
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.01, 0.3],
            colors: [
              Cores.LARANJA,
              Cores.AMARELO_MEDIO,
            ],
          ),
        ),
        child: Center(
          child: InkWell(
              child: const Text(
                'Digitar código de barras',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lato',
                  color: Cores.BRANCO,
                ),
              ),
              onTap: () {} //() => Navigator.of(context).pop()),
              ),
        ));
  }

  double getCameraScale(MediaQueryData data, previewSize) {
    final double logicalWidth = data.size.height * .53;
    final double logicalHeight = previewSize.aspectRatio * logicalWidth;

    final double maxLogicalHeight = data.size.width;

    return maxLogicalHeight / logicalHeight;
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();

    SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: <SystemUiOverlay>[
          SystemUiOverlay.top,
          SystemUiOverlay.bottom,
        ]);
  }
}
