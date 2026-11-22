import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initDatabaseFactory() async {
  // Inicializa FFI para escritorio
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
