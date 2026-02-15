import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false, // Desactivado para mayor velocidad
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
      return null;
    }
  }

  // ── Detectar rostro desde stream de cámara (verificación en tiempo real) ──
  Future<bool> detectFaceFromCameraImage(CameraImage image) async {
    try {
      final InputImage inputImage;

      if (Platform.isAndroid) {
        // Android usa NV21 - necesita concatenar planos YUV
        inputImage = _buildAndroidInputImage(image);
      } else {
        // iOS usa BGRA
        inputImage = InputImage.fromBytes(
          bytes: image.planes.first.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes.first.bytesPerRow,
          ),
        );
      }

      final faces = await _faceDetector.processImage(inputImage);
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('FaceDetectorService error: $e');
      return false;
    }
  }

  // ── Construir InputImage para Android (NV21) ──
  InputImage _buildAndroidInputImage(CameraImage image) {
    // Concatenar todos los planos de la imagen YUV
    final allBytes = <int>[];
    for (final plane in image.planes) {
      allBytes.addAll(plane.bytes);
    }
    final bytes = Uint8List.fromList(allBytes);

    // Cámara frontal en Android está rotada 270 grados
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation270deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void dispose() {
    _faceDetector.close();
  }
}


void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}
