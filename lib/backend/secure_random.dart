import 'dart:math';

/// Secure random generator for string/number.
///
/// This class uses a cryptographically secure source of random numbers.
class SecureRandom {
  final Random _random;
  final String _charset;

  SecureRandom(
      {String charset =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'})
      : _random = Random.secure(),
        _charset = charset;

  /// Generate a strong random string.
  ///
  /// [length] is the length of the target random string.
  ///
  /// Returns a random string with a fixed length.
  String nextString(int length) {
    final buffer = StringBuffer();

    for (var i = 0; i < length; ++i) {
      final random = _random.nextInt(_charset.length);
      buffer.write(_charset[random]);
    }

    return buffer.toString();
  }

  /// Generate a strong random integer.
  ///
  /// [max] is the maximum value for the random integer.
  ///
  /// Returns a random integer.
  int nextInt(int max) {
    return _random.nextInt(max);
  }
}
