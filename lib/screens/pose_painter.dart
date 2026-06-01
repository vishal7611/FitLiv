import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Size screenSize;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.screenSize,
  });

  // Connections to draw the skeleton
  static const _connections = [
    // Face
    [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
    [PoseLandmarkType.rightEar, PoseLandmarkType.rightEye],
    [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
    [PoseLandmarkType.rightEye, PoseLandmarkType.nose],
    // Shoulders
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    // Left arm
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    // Right arm
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Left leg
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    // Right leg
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final jointPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 6
      ..style = PaintingStyle.fill;

    final bonePaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final pose in poses) {
      // Draw bones
      for (final connection in _connections) {
        final from = pose.landmarks[connection[0]];
        final to = pose.landmarks[connection[1]];
        if (from != null && to != null &&
            from.likelihood > 0.5 && to.likelihood > 0.5) {
          canvas.drawLine(
            _translatePoint(from.x, from.y),
            _translatePoint(to.x, to.y),
            bonePaint,
          );
        }
      }

      // Draw joints
      for (final landmark in pose.landmarks.values) {
        if (landmark.likelihood > 0.5) {
          canvas.drawCircle(
            _translatePoint(landmark.x, landmark.y),
            5,
            jointPaint,
          );
        }
      }
    }
  }

  Offset _translatePoint(double x, double y) {
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;
    return Offset(screenSize.width-(x * scaleX), y * scaleY);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) =>
      oldDelegate.poses != poses;
}
