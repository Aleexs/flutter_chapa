// Fallback flutter
Future<void> initDatabaseFactory() async {
  throw UnsupportedError(
    'No se reconoció la plataforma para inicializar SQLite',
  );
}
