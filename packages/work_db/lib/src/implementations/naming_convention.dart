/// Static class for managing naming conventions.
///
/// Enforces the following rules:
/// - Only classic ASCII characters (0x20-0x7E)
/// - The word "lock" is forbidden in any case variation (lock, Lock, LOCK, etc.)
class NamingConvention {
  // Private constructor to prevent instantiation
  NamingConvention._();

  /// Regex pattern for classic ASCII characters (space through ~)
  static final RegExp _asciiPattern = RegExp(r'^[ -~]+$');

  /// Pattern to match "lock" in any case variation (as substring anywhere in the name)
  static final RegExp _lockPattern = RegExp('lock', caseSensitive: false);

  /// Validates if a name follows the naming convention.
  ///
  /// Returns `true` if the name:
  /// - Contains only classic ASCII characters
  /// - Does not contain the word "lock" in any case variation
  ///
  /// Returns `false` otherwise.
  static bool isValid(String name) {
    if (name.isEmpty) {
      return false;
    }

    // Check if only contains classic ASCII characters
    if (!_asciiPattern.hasMatch(name)) {
      return false;
    }

    // Check if "lock" word is present in any case
    if (_lockPattern.hasMatch(name)) {
      return false;
    }

    return true;
  }

  /// Validates if a name follows the naming convention.
  ///
  /// Throws [ArgumentError] with a descriptive message if the name is invalid.
  static void validateOrThrow(String name) {
    if (!isValid(name)) {
      if (name.isEmpty) {
        throw ArgumentError('Name cannot be empty');
      }

      if (!_asciiPattern.hasMatch(name)) {
        throw ArgumentError(
          'Name "$name" contains invalid characters. '
          'Only classic ASCII characters (0x20-0x7E) are allowed.',
        );
      }
      // Lock is used by the system
      if (_lockPattern.hasMatch(name)) {
        throw ArgumentError(
          'Name "$name" contains the forbidden word "lock". '
          'The word "lock" is not allowed in any case variation.',
        );
      }

      throw ArgumentError('Name "$name" does not follow naming conventions.');
    }
  }

  /// Returns a list of validation errors for the given name.
  ///
  /// Returns an empty list if the name is valid.
  static List<String> getValidationErrors(String name) {
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Name cannot be empty');
      return errors;
    }

    if (!_asciiPattern.hasMatch(name)) {
      errors.add(
        'Contains invalid characters. Only classic ASCII characters (0x20-0x7E) are allowed.',
      );
    }

    if (_lockPattern.hasMatch(name)) {
      errors.add('Contains the forbidden word "lock" in some case variation.');
    }

    return errors;
  }
}
