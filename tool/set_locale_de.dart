import 'dart:io';
import 'package:hive/hive.dart';

Future<void> main() async {
  final base = Platform.environment['LOCALAPPDATA'] ??
      Platform.environment['APPDATA'] ??
      Directory.current.path;
  final hiveDir = Directory('$base/Kaizen/hive_data');
  Hive.init(hiveDir.path);
  final box = await Hive.openBox('fitflow_progress');
  await box.put('app_locale', 'de');
  print('locale set to ${box.get('app_locale')}');
  await box.close();
}
