import 'package:flutter/material.dart';
import 'dart:convert';

enum TaskStatus { todo, inProgress, done }

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final int columnIndex;
  final DateTime? deadline;
  final DateTime createdAt;
  final Color color;
  final int position;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.columnIndex,
    this.deadline,
    required this.createdAt,
    required this.color,
    this.position = 0,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    int? columnIndex,
    DateTime? deadline,
    DateTime? createdAt,
    Color? color,
    int? position,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      columnIndex: columnIndex ?? this.columnIndex,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.index,
      'columnIndex': columnIndex,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'color': color.value,
      'position': position,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: TaskStatus.values[map['status']],
      columnIndex: map['columnIndex'],
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      createdAt: DateTime.parse(map['createdAt']),
      color: Color(map['color']),
      position: map['position'],
    );
  }

  String toJson() {
    return json.encode(toMap());
  }

  factory TaskModel.fromJson(String source) {
    return TaskModel.fromMap(json.decode(source));
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, description: $description, status: $status, columnIndex: $columnIndex, deadline: $deadline, createdAt: $createdAt, color: $color, position: $position)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TaskModel &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.status == status &&
      other.columnIndex == columnIndex &&
      other.deadline == deadline &&
      other.createdAt == createdAt &&
      other.color.value == color.value &&
      other.position == position;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      status.hashCode ^
      columnIndex.hashCode ^
      deadline.hashCode ^
      createdAt.hashCode ^
      color.hashCode ^
      position.hashCode;
  }
}