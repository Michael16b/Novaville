class ValidationPatterns {
  ValidationPatterns._();

  // Letters-only TLD (2+ chars) to avoid invalid endings like .com2
  static final RegExp email = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );
}
