import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SmartCameraScreen extends StatefulWidget {
  const SmartCameraScreen({super.key});

  @override
  State<SmartCameraScreen> createState() => _SmartCameraScreenState();
}

class _SmartCameraScreenState extends State<SmartCameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  List<CameraDescription> cameras = [];
  int _selectedCameraIndex = 1; // Default kamera depan (index 1)

  // Setup ML Kit Deteksi Wajah
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isProcessing = false;
  int _faceCount = 0;
  String _statusMessage = "Mendeteksi wajah...";
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Safety check index agar tidak error jika kamera cuma 1
    if (cameras.length <= _selectedCameraIndex) {
      _selectedCameraIndex = 0;
    }
    _startCamera(cameras[_selectedCameraIndex]);
  }

  void _startCamera(CameraDescription cameraDesc) async {
    final controller = CameraController(
      cameraDesc,
      // UPDATE: Gunakan 'high' agar foto sumber TAJAM (Tidak burik).
      // Nanti kita kompres ukurannya di db_service agar muat di database.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      // Mulai Stream untuk deteksi wajah realtime
      controller.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _processImage(image);
        }
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _processImage(CameraImage image) async {
    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _faceCount = faces.length;
          // Validasi Jumlah Wajah
          if (_faceCount == 0) {
            _statusMessage = "Wajah tidak terlihat!";
            _statusColor = Colors.red;
          } else if (_faceCount > 1) {
            _statusMessage = "Hanya boleh 1 orang!";
            _statusColor = Colors.red;
          } else {
            _statusMessage = "Wajah Valid (1 Orang) ✅";
            _statusColor = Colors.green;
          }
        });
      }
    } catch (e) {
      debugPrint("Error detection: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _switchCamera() {
    if (cameras.length < 2) return;
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    });
    _controller?.dispose();
    _startCamera(cameras[_selectedCameraIndex]);
  }

  Future<void> _takePicture() async {
    // Double check: Hanya boleh ambil foto jika wajah valid (1 orang)
    if (_faceCount != 1) return;

    try {
      await _controller
          ?.stopImageStream(); // Stop stream biar ga crash saat capture
      final XFile image = await _controller!.takePicture();

      if (!mounted) return;
      // Kirim file foto kembali ke layar sebelumnya (Student Screen)
      Navigator.pop(context, image);
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Layar Kamera Full
          SizedBox.expand(child: CameraPreview(_controller!)),

          // 2. Status Overlay (Kotak Pesan di Atas)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 3. Kontrol Bawah (Tombol Foto & Switch)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Ganti Kamera
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(
                    Icons.cameraswitch,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                // Tombol Shutter (Hanya aktif jika wajah valid)
                GestureDetector(
                  onTap: (_faceCount == 1) ? _takePicture : null,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_faceCount == 1) ? Colors.white : Colors.grey,
                      border: Border.all(color: Colors.blueAccent, width: 4),
                    ),
                    child: (_faceCount == 1)
                        ? const Icon(Icons.camera, size: 40)
                        : const Icon(Icons.close, color: Colors.white),
                  ),
                ),

                const SizedBox(width: 50), // Spacer penyeimbang
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- BOILERPLATE ML KIT (Wajib ada untuk konversi format gambar) ---
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = cameras[_selectedCameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
}
