import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false,
      enableClassification: false,
    ),
  );

  // ── Detectar rostro desde archivo (registro) ──
  Future<String?> detectFace(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return null;
      final face = faces.first;
      final boundingBox = face.boundingBox;
      return '${boundingBox.width},${boundingBox.height}';
    } catch (e) {
      debugPrint('Error detectando rostro desde archivo: $e');
      return null;
    }
  }

  // ── Detectar rostro desde stream de cámara ──
  Future<bool> detectFaceFromCameraImage(
    CameraImage image,
    CameraDescription camara, // ✅ Recibe la descripción de la cámara
  ) async {
    try {
      final InputImage? inputImage = _buildInputImage(image, camara);
      if (inputImage == null) return false;
      final faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('FaceDetectorService error: $e');
      return false;
    }
  }

  // ── Construir InputImage para Android e iOS ──
  InputImage? _buildInputImage(CameraImage image, CameraDescription camara) {
    try {
      if (Platform.isAndroid) {
        return _buildAndroidInputImage(image, camara);
      } else {
        return _buildIOSInputImage(image);
      }
    } catch (e) {
      debugPrint('Error construyendo InputImage: $e');
      return null;
    }
  }

  // ── Android: formato NV21, solo primer plano ──
  InputImage? _buildAndroidInputImage(
    CameraImage image,
    CameraDescription camara,
  ) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    // ✅ Rotación según dirección de la cámara (sin usar isFrontCamera)
    final InputImageRotation rotacion;
    if (camara.lensDirection == CameraLensDirection.front) {
      rotacion = InputImageRotation.rotation270deg;
    } else {
      rotacion = InputImageRotation.rotation90deg;
    }

    return InputImage.fromBytes(
      bytes: plane.bytes, // ✅ Solo primer plano, corrige el RangeError
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotacion,
        format: InputImageFormat.nv21,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ── iOS: formato BGRA8888 ──
  InputImage? _buildIOSInputImage(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}
