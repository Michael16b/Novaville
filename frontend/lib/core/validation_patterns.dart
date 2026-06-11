/// Shared regular expressions used by form validators.
class ValidationPatterns {
  ValidationPatterns._();

  /// Email pattern with a letters-only TLD to reject endings like `.com2`.
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password pattern requiring mixed case, a digit, and a special character.
  static final RegExp password = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
  );
}
