import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

  Future<String?> detectFace(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      return null;
    }

    // Tomar el primer rostro detectado
    final face = faces.first;

    // Crear una representación simple del rostro
    final boundingBox = face.boundingBox;
    final landmarks = face.landmarks;

    // Crear una cadena con características clave
    String faceData = '${boundingBox.width},${boundingBox.height}';

    if (landmarks[FaceLandmarkType.leftEye] != null) {
      faceData += ',${landmarks[FaceLandmarkType.leftEye]!.position.x}';
    }
    if (landmarks[FaceLandmarkType.rightEye] != null) {
      faceData += ',${landmarks[FaceLandmarkType.rightEye]!.position.x}';
    }

    return faceData;
  }

  bool compareFaces(String savedFaceData, String currentFaceData) {
    // Comparación simple (en producción usarías algo más sofisticado)
    final saved = savedFaceData.split(',').map((e) => double.tryParse(e) ?? 0).toList();
    final current = currentFaceData.split(',').map((e) => double.tryParse(e) ?? 0).toList();

    if (saved.length != current.length) return false;

    // Calcular similitud (tolerancia del 15%)
    double tolerance = 0.15;
    for (int i = 0; i < saved.length; i++) {
      if (saved[i] == 0) continue;
      double diff = (saved[i] - current[i]).abs() / saved[i];
      if (diff > tolerance) return false;
    }

    return true;
  }

  void dispose() {
    _faceDetector.close();
  }
}
