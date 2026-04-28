class GroupUtils {
  /// Returns the default country code based on the [groupId].
  ///
  /// Currently supported:
  /// - 'gajanan_maharaj_seattle' -> '+1'
  /// - 'gajanan_gunjan' -> '+91'
  ///
  /// Default fallback is '+1'.
  static String getDefaultCountryCode(String? groupId) {
    switch (groupId) {
      case 'gajanan_maharaj_seattle':
        return '+1';
      case 'gajanan_gunjan':
        return '+91';
      default:
        return '+1';
    }
  }
}
