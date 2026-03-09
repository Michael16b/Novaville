class ValidationPatterns {
  ValidationPatterns._();

  // Letters-only TLD (2+ chars) to avoid invalid endings like .com2
  static final RegExp email = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  // Password: minimum 8 characters, at least 1 uppercase letter, 1 lowercase letter, 1 digit, and 1 special character
  static final RegExp password = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
  );
}
