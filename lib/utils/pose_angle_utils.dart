import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseAngleUtils {
  /// Calculate the angle at point B formed by points A-B-C
  static double calculateAngle(
      PoseLandmark a,
      PoseLandmark b,
      PoseLandmark c,
      ) {
    final radians = math.atan2(c.y - b.y, c.x - b.x) -
        math.atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180 / math.pi).abs();
    if (angle > 180) angle = 360 - angle;
    return angle;
  }

  /// Get angle for BICEP CURL (elbow angle)
  static double? getBicepCurlAngle(Pose pose, {bool useRight = true}) {
    final shoulder = pose.landmarks[useRight
        ? PoseLandmarkType.rightShoulder
        : PoseLandmarkType.leftShoulder];
    final elbow = pose.landmarks[useRight
        ? PoseLandmarkType.rightElbow
        : PoseLandmarkType.leftElbow];
    final wrist = pose.landmarks[useRight
        ? PoseLandmarkType.rightWrist
        : PoseLandmarkType.leftWrist];

    if (shoulder == null || elbow == null || wrist == null) return null;
    if (shoulder.likelihood < 0.5 ||
        elbow.likelihood < 0.5 ||
        wrist.likelihood < 0.5) {return null;}

    return calculateAngle(shoulder, elbow, wrist);
  }

  /// Get angle for PUSH-UP (elbow angle)
  static double? getPushUpAngle(Pose pose) {
    final shoulder =
    pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (shoulder == null || elbow == null || wrist == null){ return null;}
    if (shoulder.likelihood < 0.5 ||
        elbow.likelihood < 0.5 ||
        wrist.likelihood < 0.5) {return null;}

    return calculateAngle(shoulder, elbow, wrist);
  }

  /// Get hip angle for PUSH-UP body alignment
  static double? getPushUpHipAngle(Pose pose) {
    final shoulder =
    pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (shoulder == null || hip == null || knee == null) return null;
    return calculateAngle(shoulder, hip, knee);
  }
}

/// Exercise feedback data class
class ExerciseFeedback {
  final double angle;
  final String status;       // 'good', 'warning', 'error'
  final String message;
  final String emoji;
  final int repCount;
  final int goodRepCount;

  const ExerciseFeedback({
    required this.angle,
    required this.status,
    required this.message,
    required this.emoji,
    required this.repCount,
    required this.goodRepCount,
  });
}

/// Bicep Curl Rep Counter & Feedback
class BicepCurlAnalyzer {
  int _repCount = 0;
  int _goodRepCount = 0;
  String _phase = 'down'; // 'up' or 'down'
  bool _wasGoodDuringRep = true;

  // Thresholds
  static const double _upThreshold = 50.0;    // arm curled up
  static const double _downThreshold = 130.0; // arm extended down
  static const double _goodMin = 30.0;
  static const double _goodMax = 160.0;

  ExerciseFeedback analyze(double angle) {
    // Count reps
    if (angle < _upThreshold && _phase == 'down') {
      _phase = 'up';
    } else if (angle > _downThreshold && _phase == 'up') {
      _phase = 'down';
      _repCount++;
      if (_wasGoodDuringRep) _goodRepCount++;
      _wasGoodDuringRep = true; // reset for next rep
    }

    // Feedback & Form Check
    String status, message, emoji;
    if (angle >= _goodMin && angle <= _goodMax) {
      if (angle < _upThreshold) {
        status = 'good';
        message = 'Great curl! Hold briefly';
        emoji = '💪';
      } else if (angle > _downThreshold) {
        status = 'good';
        message = 'Good extension! Curl up now';
        emoji = '✅';
      } else {
        status = 'good';
        message = 'Perfect range of motion!';
        emoji = '🔥';
      }
    } else {
      _wasGoodDuringRep = false; // Mark form as bad for this rep
      if (angle < _goodMin) {
        status = 'warning';
        message = 'Extend arm more at bottom';
        emoji = '⚠️';
      } else {
        status = 'warning';
        message = 'Curl higher for full range';
        emoji = '📈';
      }
    }

    return ExerciseFeedback(
      angle: angle,
      status: status,
      message: message,
      emoji: emoji,
      repCount: _repCount,
      goodRepCount: _goodRepCount,
    );
  }

  void reset() {
    _repCount = 0;
    _goodRepCount = 0;
    _phase = 'down';
    _wasGoodDuringRep = true;
  }
}

/// Push-Up Rep Counter & Feedback
class PushUpAnalyzer {
  int _repCount = 0;
  int _goodRepCount = 0;
  String _phase = 'up'; // 'up' or 'down'
  bool _wasGoodDuringRep = true;

  static const double _downThreshold = 90.0;  // elbows bent at bottom
  static const double _upThreshold = 160.0;   // arms extended at top
  static const double _goodMin = 70.0;
  static const double _goodMax = 170.0;

  ExerciseFeedback analyze(elbowAngle, double? hipAngle) {
    // Count reps
    if (elbowAngle < _downThreshold && _phase == 'up') {
      _phase = 'down';
    } else if (elbowAngle > _upThreshold && _phase == 'down') {
      _phase = 'up';
      _repCount++;
      if (_wasGoodDuringRep) _goodRepCount++;
      _wasGoodDuringRep = true; // reset for next rep
    }

    // Check hip alignment
    bool hipAligned = hipAngle == null || (hipAngle > 160 && hipAngle < 200);

    String status, message, emoji;
    if (!hipAligned) {
      _wasGoodDuringRep = false;
      status = 'warning';
      message = 'Keep hips level — don\'t sag!';
      emoji = '⚠️';
    } else if (elbowAngle >= _goodMin && elbowAngle <= _goodMax) {
      if (elbowAngle < _downThreshold) {
        status = 'good';
        message = 'Deep push-up! Now push up!';
        emoji = '💪';
      } else if (elbowAngle > _upThreshold) {
        status = 'good';
        message = 'Arms extended! Lower down now';
        emoji = '✅';
      } else {
        status = 'good';
        message = 'Great form! Keep going!';
        emoji = '🔥';
      }
    } else {
      _wasGoodDuringRep = false;
      if (elbowAngle < _goodMin) {
        status = 'warning';
        message = 'Too deep — don\'t stress joints';
        emoji = '⚠️';
      } else {
        status = 'warning';
        message = 'Lower your chest more';
        emoji = '📉';
      }
    }

    return ExerciseFeedback(
      angle: elbowAngle,
      status: status,
      message: message,
      emoji: emoji,
      repCount: _repCount,
      goodRepCount: _goodRepCount,
    );
  }

  void reset() {
    _repCount = 0;
    _goodRepCount = 0;
    _phase = 'up';
    _wasGoodDuringRep = true;
  }
}
