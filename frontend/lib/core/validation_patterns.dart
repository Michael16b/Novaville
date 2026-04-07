class ValidationPatterns {
  ValidationPatterns._();

  // Letters-only TLD (2+ chars) to avoid invalid endings like .com2
  static final RegExp email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Password: minimum 8 characters, at least 1 uppercase letter, 1 lowercase letter, 1 digit, and 1 special character
  static final RegExp password = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
  );

  static final RegExp exactAddress = RegExp(
    r'^\s*\d{1,5}(?:\s?(?:bis|ter|quater|[A-Za-z]))?\s+'
    r'(?:rue|avenue|av\.?|boulevard|bd\.?|chemin|impasse|allee|all[ée]e|route|'
    r'place|quai|square|cours|esplanade|faubourg|sentier|sente)\s+'
    r"[A-Za-zÀ-ÿ0-9'’., -]{2,}\s*$",
    caseSensitive: false,
  );
}
