import 'package:flutter_timezone/flutter_timezone.dart';

/// Native implementation — uses flutter_timezone package.
Future<String> getLocalTimezoneName() async {
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    return tzInfo.identifier;
  } catch (_) {
    return 'UTC';
  }
}
