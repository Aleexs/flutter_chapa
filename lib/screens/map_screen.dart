// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Coordenadas de Arequipa, Perú (centro aproximado)
  final LatLng _center = const LatLng(-16.409047, -71.537451);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas Chapa'),
        backgroundColor: Colors.blue,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 13.0,
          maxZoom: 19.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.flutter_chapa',
            maxNativeZoom: 19, // OSM
          ),
          // Rutas
        ],
      ),
      // BUttonFl
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Grabar ruta personalizada
          debugPrint('Botón de grabar ruta presionado');
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
