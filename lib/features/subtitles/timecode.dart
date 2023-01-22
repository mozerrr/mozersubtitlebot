class TimeCode {
  /// Считает множитель разницы между двумя кадровыми частотами.
  static double frameRateDifferenceMultiplier(
    double originalFrameRate,
    double targetFrameRate,
  ) {
    return originalFrameRate / targetFrameRate;
  }

  /// Разделитель между двумя таймкодами в формате srt.
  ///
  /// 00:00:11,820 --> 00:00:18,771
  static const divider = ' --> ';
}
