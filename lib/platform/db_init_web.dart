import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

void initializeDatabaseFactory() {
  sqflite.databaseFactory = databaseFactoryFfiWeb;
  print('✅ تم تفعيل sqflite على الويب'); // للتشخيص
}