import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/pose_angle_utils.dart';
import 'pose_painter.dart';
import '../models/workout_session.dart';
import '../services/workout_storage_service.dart';
import 'session_report_screen.dart';
import 'dart:async';
import 'dart:math' as math;

enum ExerciseType { bicepCurl, pushUp }

class ExerciseScreen extends StatefulWidget {
  final ExerciseType exerciseType;
  final String title;

  const ExerciseScreen({
    super.key,
    required this.exerciseType,
    required this.title,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  final FlutterTts _flutterTts = FlutterTts();
  
  // 1. HIGH-PERFORMANCE: Use ValueNotifier to update only parts of the screen
  final ValueNotifier<List<Pose>> _poseNotifier = ValueNotifier([]);
  final ValueNotifier<ExerciseFeedback?> _feedbackNotifier = ValueNotifier(null);
  
  bool _isProcessing = false;
  bool _isCameraReady = false;
  String? _lastSpokenMessage;

  late BicepCurlAnalyzer _bicepAnalyzer;
  late PushUpAnalyzer _pushUpAnalyzer;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _metricsTimer;
  int _currentHeartRate = 72;
  int _currentSpO2 = 98;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bicepAnalyzer = BicepCurlAnalyzer();
    _pushUpAnalyzer = PushUpAnalyzer();
    _initCamera();
    _initPoseDetector();
    _initTts();
    _startMetricsSimulation();
    _stopwatch.start();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.speak("Starting ${widget.title} session. Get into position.");
  }

  void _startMetricsSimulation() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentHeartRate = 80 + math.Random().nextInt(40);
          _currentSpO2 = 95 + math.Random().nextInt(5);
        });
      }
    });
  }

  void _initPoseDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
        model: PoseDetectionModel.base, // Base is significantly faster than Accurate
      ),
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.low, // Lower resolution processed much faster by AI
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() => _isCameraReady = true);
    _cameraController!.startImageStream(_processCameraImage);
  }
 int _frameCounter=0;
  Future<void> _processCameraImage(CameraImage image) async {
    _frameCounter++;
    if (_frameCounter % 2 != 0) return;
    if (_isProcessing || _poseDetector == null) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        final pose = poses.first;
        ExerciseFeedback? currentFeedback;

        if (widget.exerciseType == ExerciseType.bicepCurl) {
          final angle = PoseAngleUtils.getBicepCurlAngle(pose);
          if (angle != null) currentFeedback = _bicepAnalyzer.analyze(angle);
        } else if (widget.exerciseType == ExerciseType.pushUp) {
          final elbowAngle = PoseAngleUtils.getPushUpAngle(pose);
          final hipAngle = PoseAngleUtils.getPushUpHipAngle(pose);
          if (elbowAngle != null) {
            currentFeedback = _pushUpAnalyzer.analyze(elbowAngle, hipAngle);
          }
        }

        // 2.  HIGH-PERFORMANCE: Update values via Notifiers to avoid full-screen rebuilds
        _poseNotifier.value = poses;
        if (currentFeedback != null) {
          final int prevReps = _feedbackNotifier.value?.repCount ?? 0;
          _feedbackNotifier.value = currentFeedback;
          
          // Voice Trainer Logic
          if (currentFeedback.repCount > prevReps) {
            _flutterTts.speak("${currentFeedback.repCount}. ${currentFeedback.message}");
            _lastSpokenMessage = currentFeedback.message;
          } else if (currentFeedback.message != _lastSpokenMessage) {
            _flutterTts.speak(currentFeedback.message);
            _lastSpokenMessage = currentFeedback.message;
          }
        }
      } else {
        _poseNotifier.value = [];
      }
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController?.description;
    if (camera == null) return null;
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (format != InputImageFormat.nv21 && format != InputImageFormat.yuv_420_888)) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _endSession() async {
    _stopwatch.stop();
    await _cameraController?.stopImageStream();
    await _flutterTts.stop();
    _flutterTts.speak("Workout complete. Well done.");
    
    final int totalReps = _feedbackNotifier.value?.repCount ?? 0;
    final int goodReps = _feedbackNotifier.value?.goodRepCount ?? 0;
    final double duration = _stopwatch.elapsedMilliseconds / 1000.0;
    final double efficiency = totalReps > 0 ? (goodReps / totalReps) * 100 : 0;

    final session = WorkoutSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseName: widget.title,
      reps: totalReps,
      goodReps: goodReps,
      durationInSeconds: duration,
      efficiency: efficiency,
      heartRate: _currentHeartRate,
      bloodOxygen: _currentSpO2,
      timestamp: DateTime.now(),
    );

    if (totalReps > 0) await WorkoutStorageService.saveSession(session);

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SessionReportScreen(session: session)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _poseDetector?.close();
    _flutterTts.stop();
    _metricsTimer?.cancel();
    _poseNotifier.dispose();
    _feedbackNotifier.dispose();
    super.dispose();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'good': return Colors.greenAccent;
      case 'warning': return Colors.orangeAccent;
      case 'error': return Colors.redAccent;
      default: return Colors.white60;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 3. Camera Preview - Builds only once
          if (_isCameraReady && _cameraController != null) 
            CameraPreview(_cameraController!) 
          else 
            const Center(child: CircularProgressIndicator()),
          
          // 4. HIGH-PERFORMANCE: Isolated Stick Figure Layer
          ValueListenableBuilder<List<Pose>>(
            valueListenable: _poseNotifier,
            builder: (context, poses, _) {
              if (!_isCameraReady || poses.isEmpty || _cameraController == null) {
                return const SizedBox.shrink();
              }
              return RepaintBoundary(
                child: CustomPaint(
                  painter: PosePainter(
                    poses: poses, 
                    imageSize: Size(
                      _cameraController!.value.previewSize!.height, 
                      _cameraController!.value.previewSize!.width
                    ), 
                    screenSize: MediaQuery.of(context).size
                  ),
                ),
              );
            },
          ),

          // 5. HIGH-PERFORMANCE: Isolated Feedback Box
          Positioned(
            bottom: 120, left: 20, right: 20,
            child: ValueListenableBuilder<ExerciseFeedback?>(
              valueListenable: _feedbackNotifier,
              builder: (context, feedback, _) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87, 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(feedback?.status).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(feedback?.emoji ?? '🎯', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feedback?.message ?? 'Get in position', 
                          style: TextStyle(
                            color: _statusColor(feedback?.status), 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 6. Static UI (Header) with specific rebuild for rep count
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context), 
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(backgroundColor: Colors.black45),
                      ),
                      const SizedBox(width: 8),
                      Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Rep count updates only when feedback changes
                      ValueListenableBuilder<ExerciseFeedback?>(
                        valueListenable: _feedbackNotifier,
                        builder: (context, feedback, _) {
                          return _buildStatBadge('${feedback?.repCount ?? 0}', 'REPS', const Color(0xFF00E5FF));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetricTile(Icons.favorite, '$_currentHeartRate', 'BPM', Colors.redAccent),
                      const SizedBox(width: 12),
                      _buildMetricTile(Icons.timer, '${_stopwatch.elapsed.inMinutes}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, "0")}', 'TIME', Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 7. End Session Button
          Positioned(
            bottom: 40, left: 24, right: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _endSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                child: const Text('End Session', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54, 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color.withOpacity(0.4))
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), 
          Text(label, style: TextStyle(color: color, fontSize: 10))
        ]
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16), 
          const SizedBox(width: 6), 
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
          const SizedBox(width: 2), 
          Text(unit, style: TextStyle(color: Colors.white54, fontSize: 10))
        ]
      ),
    );
  }
}
