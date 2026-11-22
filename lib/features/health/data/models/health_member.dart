/// Thành viên trong hồ sơ sức khỏe gia đình.
class HealthMember {
  const HealthMember({
    required this.id,
    required this.name,
    this.relation = 'SELF',
    this.gender,
    this.birthDate,
    this.heightCm,
    this.weightKg,
    this.allergies = '',
    this.conditions = '',
    this.note = '',
  });

  static const Map<String, String> relationLabels = {
    'SELF': 'Bản thân',
    'FATHER': 'Bố',
    'MOTHER': 'Mẹ',
    'SPOUSE': 'Vợ/Chồng',
    'CHILD': 'Con',
    'GRANDPARENT': 'Ông/Bà',
    'OTHER': 'Khác',
  };

  final String id;
  final String name;
  final String relation;
  final String? gender;

  /// Ngày sinh dạng `yyyy-MM-dd`.
  final String? birthDate;
  final double? heightCm;
  final double? weightKg;
  final String allergies;
  final String conditions;
  final String note;

  String get relationLabel => relationLabels[relation] ?? 'Khác';

  int? ageAt(DateTime now) {
    final text = birthDate;
    if (text == null || text.isEmpty) {
      return null;
    }
    final born = DateTime.tryParse(text);
    if (born == null) {
      return null;
    }
    var age = now.year - born.year;
    if (now.month < born.month ||
        (now.month == born.month && now.day < born.day)) {
      age--;
    }
    return age < 0 ? null : age;
  }

  HealthMember copyWith({
    String? name,
    String? relation,
    String? gender,
    String? birthDate,
    double? heightCm,
    double? weightKg,
    String? allergies,
    String? conditions,
    String? note,
  }) {
    return HealthMember(
      id: id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      note: note ?? this.note,
    );
  }

  factory HealthMember.fromJson(Map<String, dynamic> json) {
    double? number(Object? value) =>
        value == null ? null : double.tryParse(value.toString());
    String? text(Object? value) {
      final s = value?.toString();
      return s == null || s.isEmpty ? null : s;
    }

    return HealthMember(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      relation: (json['relation'] ?? 'OTHER').toString(),
      gender: text(json['gender']),
      birthDate: text(json['birthDate']),
      heightCm: number(json['heightCm']),
      weightKg: number(json['weightKg']),
      allergies: (json['allergies'] ?? '').toString(),
      conditions: (json['conditions'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'gender': gender,
      'birthDate': birthDate,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'allergies': allergies,
      'conditions': conditions,
      'note': note,
    };
  }
}
