// ignore_for_file: avoid_print, use_full_hex_values_for_flutter_colors
import 'dart:async';
import 'dart:io';

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sk_leitor_globals.dart';
import 'sk_leitor_funcoes_febraban.dart';

// ignore: must_be_immutable
class SKLeitor extends StatefulWidget {
  double altura;
  double largura;

  SKLeitor({super.key, required this.altura, required this.largura});

  @override
  State<StatefulWidget> createState() => SKLeitorState();

  static Orientation getOrientation(size) {
    return size.width > size.height
        ? Orientation.landscape
        : Orientation.portrait;
  }
}

class SKLeitorState extends State<SKLeitor> with TickerProviderStateMixin {
  late CameraController controller;
  final BarcodeScanner _barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  static const Color corLaranja = Color(0xFFe95f32);
  static const Color corBranco = Color(0xFFf4f4f4);
  static const Color corAzulAlpha = Color(0xFFa10030a8);
  static const Color corAmareloMedio = Color(0xFFf18f34);

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
        controller.lockCaptureOrientation(DeviceOrientation.landscapeRight);
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
        String codigo = '';
        codigo = await detectarCodigoBarras(image);
        if (codigo != '') {
          print('Boleto Febraban detectado - valor: $codigo');
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
        format:
            Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.nv21,
        bytesPerRow: totalBytes);

    final imagem = InputImage.fromBytes(bytes: bytes, metadata: metadata);

    //-----------------------------------

    final List<Barcode> barcodes = await _barcodeScanner.processImage(imagem);

    if (barcodes.isNotEmpty) {
      for (Barcode barcode in barcodes) {
        print("Barras detectado - valor: ${barcode.rawValue}");
        if (SKLeitorFuncoesFebraban.validateBoleto(
            barcode.rawValue as String)) {
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
            color: corBranco,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 150),
            color: corAzulAlpha,
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
              painter: SKLeitorLinePainter(
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
          color: corAmareloMedio,
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.01, 0.3],
            colors: [
              corLaranja,
              corAmareloMedio,
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
                color: corBranco,
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

class SKLeitorLinePainter extends CustomPainter {
  SKLeitorLinePainter({required this.windowSize, this.closeWindow = false});

  final Size windowSize;
  final bool closeWindow;

  static const Color corLARANJA = Color(0xFFe95f32);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = corLARANJA;
    paint.strokeWidth = 2;
    double positionH = windowSize.height / 2.5;
    canvas.drawLine(
      Offset(10, positionH),
      Offset(windowSize.width * .98, positionH),
      paint,
    );
  }

  @override
  bool shouldRepaint(SKLeitorLinePainter oldDelegate) =>
      oldDelegate.closeWindow != closeWindow;
}
