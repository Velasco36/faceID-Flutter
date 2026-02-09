import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/face_detector_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  CameraController? _controller;
  final TextEditingController _nameController = TextEditingController();
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  final FaceDetectorService _faceDetector = FaceDetectorService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      cameras[1], // Cámara frontal
      ResolutionPreset.medium,
    );

    await _controller!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await _controller!.takePicture();

      // Detectar rostro en la imagen
      final faceData = await _faceDetector.detectFace(image.path);

      if (faceData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se detectó ningún rostro')),
          );
        }
        return;
      }

      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      print('Error al tomar foto: $e');
    }
  }

  Future<void> _saveRegistration() async {
    if (_capturedImage == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    try {
      // Guardar imagen en almacenamiento local
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/${_nameController.text}.jpg';
      await File(_capturedImage!.path).copy(imagePath);

      // Extraer características faciales
      final faceData = await _faceDetector.detectFace(imagePath);

      if (faceData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al procesar el rostro')),
          );
        }
        return;
      }

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('registered_name', _nameController.text);
      await prefs.setString('registered_image_path', imagePath);
      await prefs.setString('face_data', faceData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text} registrado correctamente'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error al guardar: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _faceDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Persona')),
      body: _isCameraInitialized
          ? Column(
              children: [
                Expanded(
                  child: _capturedImage == null
                      ? CameraPreview(_controller!)
                      : Image.file(File(_capturedImage!.path)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (_capturedImage == null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _takePicture,
                                icon: const Icon(Icons.camera),
                                label: const Text('Tomar Foto'),
                              ),
                            )
                          else ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _capturedImage = null;
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saveRegistration,
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
