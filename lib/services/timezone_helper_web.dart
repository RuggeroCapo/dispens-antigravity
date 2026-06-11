/// Stub implementation for web platform.
/// Returns UTC since flutter_timezone is not available on web.
Future<String> getLocalTimezoneName() async {
  return 'UTC';
}
