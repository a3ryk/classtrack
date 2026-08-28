class UserProfileEntity {
  final String studentName;
  final String rollNumber;
  final String enrollmentNumber;
  final String degreeProgramme;
  final String department;

  const UserProfileEntity({
    required this.studentName,
    required this.rollNumber,
    required this.enrollmentNumber,
    required this.degreeProgramme,
    required this.department,
  });

  UserProfileEntity copyWith({
    String? studentName,
    String? rollNumber,
    String? enrollmentNumber,
    String? degreeProgramme,
    String? department,
  }) {
    return UserProfileEntity(
      studentName: studentName ?? this.studentName,
      rollNumber: rollNumber ?? this.rollNumber,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      degreeProgramme: degreeProgramme ?? this.degreeProgramme,
      department: department ?? this.department,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentName': studentName,
      'rollNumber': rollNumber,
      'enrollmentNumber': enrollmentNumber,
      'degreeProgramme': degreeProgramme,
      'department': department,
    };
  }

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      studentName: json['studentName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      enrollmentNumber: json['enrollmentNumber'] as String? ?? '',
      degreeProgramme: json['degreeProgramme'] as String? ?? '',
      department: json['department'] as String? ?? '',
    );
  }
}
