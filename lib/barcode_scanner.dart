// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:typed_data';

class BarcodeScannerWidget extends StatefulWidget {
  const BarcodeScannerWidget({super.key});

  @override
  _BarcodeScannerWidgetState createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  CameraController? _cameraController;
  final BarcodeScanner _barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController?.initialize();
    if (mounted) {
      setState(() {});
    }
    _startBarcodeScanning();
  }

  void _startBarcodeScanning() {
    _cameraController?.startImageStream((CameraImage image) {
      //if (_barcodeScanner.isBusy) return;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final inputImage = InputImage.fromBytes(
          bytes: _convertCameraImage(image),
          metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: InputImageRotation.rotation0deg,
              format: InputImageFormat.bgra8888,
              bytesPerRow: image.planes.first.bytesPerRow));

      final List<Barcode> barcodes =
          await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        // Barcode(s) detected. Handle the results as needed.
        for (Barcode barcode in barcodes) {
          print("Aqui 02 Barcode value: ${barcode.rawValue}");
          // Do something with the barcode value.
        }
      }
    } catch (e) {
      print("Barcode scanning error: $e");
    }
  }

  Uint8List _convertCameraImage(CameraImage image) {
    // Convert the camera image to bytes (you may need to handle different formats based on the camera used).
    // This example assumes the format is ImageFormat.yuv420.
    final int width = image.width;
    final int height = image.height;
    final planes = image.planes;
    final imageSize = width * height * planes.length;
    final List<int> bytes = List<int>.filled(imageSize, 0);
    int index = 0;

    for (int planeIndex = 0; planeIndex < planes.length; planeIndex++) {
      final Plane plane = planes[planeIndex];
      final Uint8List planeBytes = plane.bytes;
      for (int i = 0; i < planeBytes.length; i++) {
        bytes[index++] = planeBytes[i];
      }
    }

    return Uint8List.fromList(bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: _cameraController!.value.aspectRatio,
      child: CameraPreview(_cameraController!),
    );
  }
}
