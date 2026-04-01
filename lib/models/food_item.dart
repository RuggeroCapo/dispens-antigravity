import 'dart:convert';
import 'package:uuid/uuid.dart';

enum ExpiryType {
  strict,
  bestBefore,
}

extension ExpiryTypeExtension on ExpiryType {
  String get label {
    switch (this) {
      case ExpiryType.strict:
        return 'Use By';
      case ExpiryType.bestBefore:
        return 'Best Before';
    }
  }

  String get shortLabel {
    switch (this) {
      case ExpiryType.strict:
        return 'Use by';
      case ExpiryType.bestBefore:
        return 'Best before';
    }
  }
}

class FoodItem {
  final String id;
  final String name;
  final String? description;
  final DateTime expiryDate;
  final ExpiryType expiryType;
  final List<String> tags;
  final List<int> reminders; // Days before expiry
  final DateTime createdAt;

  FoodItem({
    String? id,
    required this.name,
    this.description,
    required this.expiryDate,
    required this.expiryType,
    required this.tags,
    required this.reminders,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? expiryDate,
    ExpiryType? expiryType,
    List<String>? tags,
    List<int>? reminders,
    DateTime? createdAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      expiryDate: expiryDate ?? this.expiryDate,
      expiryType: expiryType ?? this.expiryType,
      tags: tags ?? this.tags,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'expiryDate': expiryDate.toIso8601String(),
      'expiryType': expiryType.name,
      'tags': jsonEncode(tags),
      'reminders': jsonEncode(reminders),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      expiryDate: DateTime.parse(map['expiryDate']),
      expiryType: ExpiryType.values.firstWhere((e) => e.name == map['expiryType']),
      tags: List<String>.from(jsonDecode(map['tags'])),
      reminders: List<int>.from(jsonDecode(map['reminders'])),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'expiryDate': expiryDate.toIso8601String(),
      'expiryType': expiryType.name,
      'tags': tags,
      'reminders': reminders,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      expiryDate: DateTime.parse(json['expiryDate']),
      expiryType: ExpiryType.values.firstWhere((e) => e.name == json['expiryType']),
      tags: List<String>.from(json['tags']),
      reminders: List<int>.from(json['reminders']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
