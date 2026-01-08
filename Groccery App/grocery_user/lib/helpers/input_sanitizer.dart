/// Input sanitization and validation helpers
/// Prevents XSS, SQL injection, and other security vulnerabilities

class InputSanitizer {
  /// Sanitize string input by removing dangerous characters
  static String sanitize(String input) {
    if (input.isEmpty) return input;

    // Remove null bytes
    String sanitized = input.replaceAll(RegExp(r'\x00'), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Remove control characters except newline and tab
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    return sanitized;
  }

  /// Sanitize and validate email
  static String? sanitizeEmail(String email) {
    final sanitized = sanitize(email).toLowerCase();

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(sanitized)) {
      return null;
    }

    // Check for dangerous patterns
    if (sanitized.contains('..') ||
        sanitized.startsWith('.') ||
        sanitized.endsWith('.')) {
      return null;
    }

    return sanitized;
  }

  /// Sanitize name (allow only letters, spaces, and common punctuation)
  static String sanitizeName(String name) {
    final sanitized = sanitize(name);

    // Remove anything that's not letter, space, hyphen, or apostrophe
    return sanitized.replaceAll(RegExp(r'[^a-zA-Z\s\-\']'), '');
  }

  /// Sanitize phone number
  static String sanitizePhone(String phone) {
    // Remove all non-numeric characters except +
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  /// Sanitize address (more permissive than name)
  static String sanitizeAddress(String address) {
    final sanitized = sanitize(address);

    // Allow alphanumeric, spaces, and common punctuation
    return sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9\s,.#\-\']'), '');
  }

  /// Validate and sanitize numeric input
  static double? sanitizeNumeric(String input) {
    final sanitized = sanitize(input);

    try {
      return double.parse(sanitized);
    } catch (e) {
      return null;
    }
  }

  /// Validate string length
  static bool validateLength(String input, int min, int max) {
    final length = input.trim().length;
    return length >= min && length <= max;
  }

  /// Check for SQL injection patterns (for queries to backend)
  static bool containsSqlInjection(String input) {
    final dangerous = [
      'select',
      'insert',
      'update',
      'delete',
      'drop',
      'create',
      'alter',
      'exec',
      'execute',
      'script',
      '--',
      ';--',
      '/*',
      '*/',
      '@@',
      '@',
      'char',
      'nchar',
      'varchar',
      'nvarchar',
      'alter',
      'begin',
      'cast',
      'cursor',
      'declare',
      'end',
      'exec',
      'execute',
      'fetch',
      'kill',
      'open',
      'sys',
      'table',
      'xp_'
    ];

    final lowerInput = input.toLowerCase();

    for (final pattern in dangerous) {
      if (lowerInput.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Check for XSS patterns
  static bool containsXss(String input) {
    final dangerous = [
      '<script',
      '</script>',
      'javascript:',
      'onerror=',
      'onload=',
      'onclick=',
      'onmouseover=',
      '<iframe',
      '</iframe>',
      '<object',
      '</object>',
      '<embed',
      '</embed>',
      'eval(',
      'expression(',
    ];

    final lowerInput = input.toLowerCase();

    for (final pattern in dangerous) {
      if (lowerInput.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  /// Validate search query (stricter than normal text)
  static String? sanitizeSearchQuery(String query) {
    final sanitized = sanitize(query);

    // Check length
    if (!validateLength(sanitized, 1, 100)) {
      return null;
    }

    // Check for dangerous patterns
    if (containsSqlInjection(sanitized) || containsXss(sanitized)) {
      return null;
    }

    // Remove special regex characters that could break queries
    return sanitized.replaceAll(RegExp(r'[^\w\s]'), '');
  }

  /// Validate price/amount
  static double? validatePrice(String price) {
    final sanitized = sanitizeNumeric(price);

    if (sanitized == null || sanitized < 0 || sanitized > 1000000) {
      return null;
    }

    // Round to 2 decimal places
    return double.parse(sanitized.toStringAsFixed(2));
  }

  /// Validate quantity
  static int? validateQuantity(String quantity) {
    final sanitized = sanitizeNumeric(quantity);

    if (sanitized == null ||
        sanitized < 1 ||
        sanitized > 10000 ||
        sanitized != sanitized.roundToDouble()) {
      return null;
    }

    return sanitized.toInt();
  }

  /// Sanitize credit card number (for display only - never store!)
  static String sanitizeCreditCard(String cardNumber) {
    // Remove all non-numeric characters
    final cleaned = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Validate length
    if (cleaned.length < 13 || cleaned.length > 19) {
      return '';
    }

    return cleaned;
  }

  /// Mask sensitive data for logging
  static String maskSensitive(String data) {
    if (data.length <= 4) {
      return '***';
    }

    return '*' * (data.length - 4) + data.substring(data.length - 4);
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute &&
          (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
