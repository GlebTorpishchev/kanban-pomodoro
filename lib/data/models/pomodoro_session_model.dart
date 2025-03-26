class PomodoroSessionModel {
  final String id;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? workDuration;
  final int? breakDuration;
  final bool? isCompleted;

  PomodoroSessionModel({
    required this.id,
    this.startTime,
    this.endTime,
    this.workDuration,
    this.breakDuration,
    this.isCompleted,
  });

  PomodoroSessionModel copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? workDuration,
    int? breakDuration,
    bool? isCompleted,
  }) {
    return PomodoroSessionModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      workDuration: workDuration ?? this.workDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'workDuration': workDuration,
      'breakDuration': breakDuration,
      'isCompleted': isCompleted == true ? 1 : 0,
    };
  }

  static PomodoroSessionModel fromMap(Map<String, dynamic> map) {
    return PomodoroSessionModel(
      id: map['id'],
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      workDuration: map['workDuration'],
      breakDuration: map['breakDuration'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}

// Или используй полную версию PomodoroSessionModel:
// Если ты хочешь вернуть закомментированную версию с обязательными полями, замени текущую версию на эту:
// dart
//
// class PomodoroSessionModel {
//   final String? id;
//   final DateTime startTime;
//   final DateTime? endTime;
//   final int workDuration; // в минутах
//   final int breakDuration; // в минутах
//   final bool isCompleted;
//
//   PomodoroSessionModel({
//     this.id,
//     required this.startTime,
//     this.endTime,
//     required this.workDuration,
//     required this.breakDuration,
//     this.isCompleted = false,
//   });
//
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'startTime': startTime.toIso8601String(),
//       'endTime': endTime?.toIso8601String(),
//       'workDuration': workDuration,
//       'breakDuration': breakDuration,
//       'isCompleted': isCompleted ? 1 : 0,
//     };
//   }
//
//   factory PomodoroSessionModel.fromMap(Map<String, dynamic> map) {
//     return PomodoroSessionModel(
//       id: map['id'],
//       startTime: DateTime.parse(map['startTime']),
//       endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
//       workDuration: map['workDuration'],
//       breakDuration: map['breakDuration'],
//       isCompleted: map['isCompleted'] == 1,
//     );
//   }
// }
//
