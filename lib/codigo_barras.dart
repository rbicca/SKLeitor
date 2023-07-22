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

  bool _isProcessing = false;
  bool _nowHALT = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: <SystemUiOverlay>[]);
    controller =
        CameraController(cameras[0], ResolutionPreset.high, enableAudio: false);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }

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

      setState(() {});
      iniciateStream();
    });
  }

  //Inicia a transmissão de imagens
  iniciateStream() async {
    controller.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      if (_nowHALT) return;

      _isProcessing = true;

      try {
        String codigo = await detectarCodigoBarras(image);
        if (codigo != '') {
          print('FOUND   $codigo');
          _nowHALT = true;

          Future.delayed(Duration.zero, () {
            Navigator.of(context).pop(codigo);
          });
        }
      } catch (e) {
        print("Erro >> $e");
      } finally {
        _isProcessing = false;
      }
    });
  }

  // ignore: missing_return
  Future<String> detectarCodigoBarras(CameraImage image) async {
    //-----------------------------------
    if (_nowHALT) return '';

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final int totalBytes =
        image.planes.fold(0, (previousValue, e) => e.bytesPerRow);

    final InputImageMetadata metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg,
        format: InputImageFormat.nv21,
        bytesPerRow: totalBytes);

    final imagem = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    //-----------------------------------

    final List<Barcode> barcodes = await _barcodeScanner.processImage(imagem);

    if (barcodes.isNotEmpty) {
      // Barcode(s) detected. Handle the results as needed.
      for (Barcode barcode in barcodes) {
        print("Aqui 01 Barcode value: ${barcode.rawValue}");
        if (validateBoleto(barcode.rawValue as String)) {
          _nowHALT = true;
          return barcode.rawValue as String;
        }
      }
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
            onTap: () {
              _nowHALT = true;
              Navigator.of(context).pop();
            },
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

    try {
      controller.stopImageStream();
      _barcodeScanner.close();
      controller.dispose();
    } catch (_) {}

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
