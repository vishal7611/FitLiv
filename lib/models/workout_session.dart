class WorkoutSession {
  final String id;
  final String exerciseName;
  final int reps;
  final int goodReps;
  final double durationInSeconds;
  final double efficiency; // (goodReps / reps) * 100
  final int? heartRate;
  final int? bloodOxygen;
  final DateTime timestamp;

  WorkoutSession({
    required this.id,
    required this.exerciseName,
    required this.reps,
    required this.goodReps,
    required this.durationInSeconds,
    required this.efficiency,
    this.heartRate,
    this.bloodOxygen,
    required this.timestamp,
  });

  String get exerciseType => exerciseName.toLowerCase().contains('bicep')
      ? 'bicepCurl'
      : 'pushUp';

  String get formattedDate => "${timestamp.day}/${timestamp.month}/${timestamp.year}";

  Map<String, dynamic> toMap() => {
    'id': id,
    'exerciseName': exerciseName,
    'reps': reps,
    'goodReps': goodReps,
    'durationInSeconds': durationInSeconds,
    'efficiency': efficiency,
    'heartRate': heartRate,
    'bloodOxygen': bloodOxygen,
    'timestamp': timestamp.toIso8601String(),
  };

  factory WorkoutSession.fromMap(Map<String, dynamic> map) => WorkoutSession(
    id: map['id'],
    exerciseName: map['exerciseName'],
    reps: map['reps'],
    goodReps: map['goodReps'] ?? 0,
    durationInSeconds: (map['durationInSeconds'] ?? 0).toDouble(),
    efficiency: (map['efficiency'] ?? 0).toDouble(),
    heartRate: map['heartRate'],
    bloodOxygen: map['bloodOxygen'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
