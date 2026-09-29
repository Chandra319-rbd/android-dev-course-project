import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';

part 'phone_number_model.g.dart';

@HiveType(typeId: AppConstants.phoneNumberTypeId)
class PhoneNumberModel extends HiveObject {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final String number;

  PhoneNumberModel({required this.label, required this.number});

  /// Create from JSON (Supabase response)
  factory PhoneNumberModel.fromJson(Map<String, dynamic> json) {
    return PhoneNumberModel(
      label: json['label'] as String? ?? '',
      number: json['number'] as String? ?? '',
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {'label': label, 'number': number};
  }

  /// Create a copy with optional new values
  PhoneNumberModel copyWith({String? label, String? number}) {
    return PhoneNumberModel(
      label: label ?? this.label,
      number: number ?? this.number,
    );
  }

  @override
  String toString() => 'PhoneNumberModel(label: $label, number: $number)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneNumberModel &&
        other.label == label &&
        other.number == number;
  }

  @override
  int get hashCode => label.hashCode ^ number.hashCode;
}
