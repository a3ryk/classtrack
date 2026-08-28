import 'package:uuid/uuid.dart';

class UuidGenerator {
  static const _uuid = Uuid();

  /// Generates a unique UUIDv4 string
  static String generate() {
    return _uuid.v4();
  }
}
