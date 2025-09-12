class User {
  final String id;
  final String username;
  final String email;
  final double height;
  final double weight;
  final String nationality;
  final int age;
  final String gender;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.height,
    required this.weight,
    required this.nationality,
    required this.age,
    required this.gender,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      height: (json['height'] ?? 0.0).toDouble(),
      weight: (json['weight'] ?? 0.0).toDouble(),
      nationality: json['nationality'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'height': height,
      'weight': weight,
      'nationality': nationality,
      'age': age,
      'gender': gender,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    double? height,
    double? weight,
    String? nationality,
    int? age,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      nationality: nationality ?? this.nationality,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Workout {
  final String id;
  final String userId;
  final String type;
  final int count;
  final int duration;
  final double calories;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Workout({
    required this.id,
    required this.userId,
    required this.type,
    required this.count,
    required this.duration,
    required this.calories,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      count: json['count'] ?? 0,
      duration: json['duration'] ?? 0,
      calories: (json['calories'] ?? 0.0).toDouble(),
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'count': count,
      'duration': duration,
      'calories': calories,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class UserStats {
  final int totalWorkouts;
  final int totalPushups;
  final double totalCalories;
  final int totalDuration;
  final List<Workout> recentWorkouts;
  final List<WorkoutType> workoutTypes;

  UserStats({
    required this.totalWorkouts,
    required this.totalPushups,
    required this.totalCalories,
    required this.totalDuration,
    required this.recentWorkouts,
    required this.workoutTypes,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalWorkouts: json['total_workouts'] ?? 0,
      totalPushups: json['total_pushups'] ?? 0,
      totalCalories: (json['total_calories'] ?? 0.0).toDouble(),
      totalDuration: json['total_duration'] ?? 0,
      recentWorkouts: (json['recent_workouts'] as List<dynamic>?)
          ?.map((w) => Workout.fromJson(w))
          .toList() ?? [],
      workoutTypes: (json['workout_types'] as List<dynamic>?)
          ?.map((wt) => WorkoutType.fromJson(wt))
          .toList() ?? [],
    );
  }
}

class WorkoutType {
  final String type;
  final int count;

  WorkoutType({
    required this.type,
    required this.count,
  });

  factory WorkoutType.fromJson(Map<String, dynamic> json) {
    return WorkoutType(
      type: json['type'],
      count: json['count'],
    );
  }
}
