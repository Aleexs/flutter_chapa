import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/ruta_model.dart';
import '../models/bus_model.dart';

import 'db_factory_stub.dart'
    if (dart.library.io) 'db_factory_io.dart'
    if (dart.library.html) 'db_factory_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      await initDatabaseFactory();
    } else if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      await initDatabaseFactory();
    }

    final path = await getDatabasesPath();
    final dbPath = join(path, 'rutas_arequipa.db');

    return openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS buses');
          await db.execute('DROP TABLE IF EXISTS rutas');
          await _onCreate(db, newVersion);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rutas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_corto TEXT NOT NULL,
        nombre_largo TEXT NOT NULL,
        empresa TEXT NOT NULL,
        es_oficial INTEGER NOT NULL DEFAULT 1,
        geometria TEXT NOT NULL,
        tarifa_normal REAL NOT NULL,
        tarifa_hora_punta REAL NOT NULL,
        frecuencia_minutos INTEGER NOT NULL DEFAULT 15,
        url_imagen TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE buses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        placa TEXT NOT NULL UNIQUE,
        ruta_id INTEGER NOT NULL,
        empresa TEXT NOT NULL,
        es_ruta_modificada INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (ruta_id) REFERENCES rutas (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE puntos_ruta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ruta_id INTEGER NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        orden INTEGER NOT NULL,
        FOREIGN KEY (ruta_id) REFERENCES rutas (id) ON DELETE CASCADE
      )
    ''');

    // Índices para rendimiento
    await db.execute('CREATE INDEX idx_buses_placa ON buses(placa)');
    await db.execute(
      'CREATE INDEX idx_puntos_lat_lon ON puntos_ruta(lat, lon)',
    );
    await db.execute('CREATE INDEX idx_puntos_ruta ON puntos_ruta(ruta_id)');
  }

  // ---------------- RUTAS ----------------

  Future<int> insertRutaConPuntos(Ruta ruta) async {
    final db = await database;

    return await db.transaction((txn) async {
      // 1. Insertar la ruta (geometría comprimida en Polyline)
      final map = ruta.toMap();
      map.remove('id');
      final rutaId = await txn.insert('rutas', map);

      // 2. Insertar los puntos individuales usando un Batch (súper rápido)
      final batch = txn.batch();
      for (int i = 0; i < ruta.geometria.length; i++) {
        batch.insert('puntos_ruta', {
          'ruta_id': rutaId,
          'lat': ruta.geometria[i].latitude,
          'lon': ruta.geometria[i].longitude,
          'orden': i, // Importante para saber el orden en la línea
        });
      }
      await batch.commit(noResult: true);

      return rutaId;
    });
  }

  Future<List<Ruta>> getRutas() async {
    final db = await database;
    final rows = await db.query('rutas', orderBy: 'nombre_corto ASC');
    return rows.map(Ruta.fromMap).toList();
  }

  // Búsqueda espacial rápida por Bounding Box
  Future<List<Map<String, dynamic>>> getPuntosCercanos(
    double lat,
    double lon, {
    double radioMetros = 200,
  }) async {
    final db = await database;

    // Usamos un pequeño margen extra de seguridad.
    const double metrosPorGradoLat = 111320.0;
    final double deltaLat = radioMetros / metrosPorGradoLat;

    // Para la longitud, depende de la latitud actual. Usamos cos(lat).
    final double deltaLon = deltaLat / math.cos(lat * math.pi / 180.0);

    return await db.query(
      'puntos_ruta',
      where: 'lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?',
      whereArgs: [
        lat - deltaLat,
        lat + deltaLat,
        lon - deltaLon,
        lon + deltaLon,
      ],
    );
  }

  // ---------------- BUSES ----------------

  Future<int> insertBus(Bus bus) async {
    final db = await database;
    final map = bus.toMap();
    map.remove('id');
    return db.insert(
      'buses',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Bus?> getBusByPlaca(String placa) async {
    final db = await database;
    final rows = await db.query(
      'buses',
      where: 'placa = ?',
      whereArgs: [placa.toUpperCase().trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : Bus.fromMap(rows.first);
  }
}
