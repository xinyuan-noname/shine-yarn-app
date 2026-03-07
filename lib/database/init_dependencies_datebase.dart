import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
void initializeDatabase() {
  if (kIsWeb) {
    return;
  }
  if (databaseFactory == databaseFactoryFfi) {
    return;
  }
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
