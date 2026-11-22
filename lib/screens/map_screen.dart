import 'dart:async';

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../database/database_helper.dart';
import '../models/ruta_model.dart';
import '../models/bus_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _origenController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();

  List<LatLng> _geometriaDibujar = [];
  Ruta? _rutaActual;
  bool _cargando = true;

  // Estados de la interfaz
  bool _isMoviendoMapa = false;
  bool _mostrarDobleCuadro = false;
  Timer? _debounce;

  static final LatLng _centroArequipa = const LatLng(-16.409047, -71.537451);

  // Coordenadas de prueba
  static final List<LatLng> _geometriaReal = [
    const LatLng(-16.448902, -71.552459),
    const LatLng(-16.447886, -71.551585),
    const LatLng(-16.447746, -71.551432),
    const LatLng(-16.445017, -71.553786),
    const LatLng(-16.442251, -71.55666937),
    const LatLng(-16.440150, -71.558833),
    const LatLng(-16.439878, -71.558953),
    const LatLng(-16.439760, -71.559254),
    const LatLng(-16.438298, -71.560881),
    const LatLng(-16.437801, -71.561243),
    const LatLng(-16.436320905047342, -71.56206888762844),
    const LatLng(-16.43575660176365, -71.56212715192025),
    const LatLng(-16.434493627545628, -71.5620613344775),
    const LatLng(-16.434284216952722, -71.5617527167433),
    const LatLng(-16.43330329065115, -71.56025066764465),
    const LatLng(-16.43286872139493, -71.55981400638153),
    const LatLng(-16.432336955092463, -71.55997737524335),
    const LatLng(-16.432097626025467, -71.56075056115719),
    const LatLng(-16.43160479616734, -71.56155001241902),
    const LatLng(-16.43098042464007, -71.5610590003389),
    const LatLng(-16.428332362606632, -71.55899066473538),
    const LatLng(-16.42548789371331, -71.55663330406774),
    const LatLng(-16.41947433107315, -71.55155403453058),
    const LatLng(-16.416595499887542, -71.5488620530132),
    const LatLng(-16.412787560774042, -71.54560177064859),
    const LatLng(-16.408863939188212, -71.54240790034216),
    const LatLng(-16.406371532882506, -71.54050214132776),
    const LatLng(-16.40577080909992, -71.54009268915995),
    const LatLng(-16.40687113272969, -71.53939053187223),
    const LatLng(-16.408977856364434, -71.53764350532953),
    const LatLng(-16.408910688879224, -71.53732657549844),
    const LatLng(-16.40746481473816, -71.53546921924345),
    const LatLng(-16.405502792298687, -71.53304065217723),
    const LatLng(-16.404382132768117, -71.53172133958017),
    const LatLng(-16.40255347885269, -71.52940290945959),
    const LatLng(-16.40348678180897, -71.52854793594032),
    const LatLng(-16.404077164331955, -71.527807204536),
    const LatLng(-16.404278671723283, -71.52749395993551),
  ];

  @override
  void initState() {
    super.initState();
    _cargarRutaCompleta();
  }

  @override
  void dispose() {
    _origenController.dispose();
    _destinoController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarRutaCompleta() async {
    final db = DatabaseHelper.instance;
    if ((await db.getRutas()).isEmpty) {
      await db.insertRutaConPuntos(
        Ruta(
          nombreCorto: 'R-Real',
          nombreLargo: 'Ruta de Prueba',
          empresa: 'Transportes Arequipa',
          geometria: _geometriaReal,
          tarifaNormal: 1.5,
          tarifaHoraPunta: 2.0,
          frecuenciaMinutos: 10,
        ),
      );
      await db.insertBus(
        Bus(placa: 'V1A-234', rutaId: 1, empresa: 'Transportes Arequipa'),
      );
    }

    final rutas = await db.getRutas();
    if (rutas.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _rutaActual = rutas.first;
        _geometriaDibujar = _rutaActual!.geometria;
        _cargando = false;
      });
    }
  }

  // Lógica del botón GPS (Habilitado y funcional)
  void _usarGPS() {
    // 1. Movemos el mapa a la ubicación actual (simulada)
    _mapController.move(_centroArequipa, 16.0);

    // 2. Actualizamos la interfaz
    setState(() {
      _mostrarDobleCuadro = true;
      _isMoviendoMapa = false;
      _origenController.text = "Mi ubicación actual (GPS)";
      if (_destinoController.text.isEmpty) {
        _destinoController.text = "";
      }
    });
  }

  // Lógica del botón de buscar (la flechita)
  void _buscarRuta() {
    if (_rutaActual == null) return;

    // Simulamos la búsqueda (Origen en Plaza de Armas, Destino al final)
    int indiceOrigen = 29;
    int indiceDestino = _rutaActual!.geometria.length - 1;

    if (indiceOrigen > indiceDestino) {
      final temp = indiceOrigen;
      indiceOrigen = indiceDestino;
      indiceDestino = temp;
    }

    final segmento = _rutaActual!.getSegmento(indiceOrigen, indiceDestino);

    setState(() {
      _geometriaDibujar = segmento;
      _mostrarDobleCuadro = false;
      _isMoviendoMapa = false;
    });

    _mapController.move(_rutaActual!.geometria[indiceOrigen], 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    // 1. EL MAPA
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _centroArequipa,
                        initialZoom: 14.5,
                        maxZoom: 19.0,
                        // DETECCIÓN DE MOVIMIENTO DEL MAPA
                        onPositionChanged: (MapCamera camera, bool hasGesture) {
                          if (hasGesture) {
                            if (!_isMoviendoMapa) {
                              setState(() {
                                _isMoviendoMapa = true;
                                _mostrarDobleCuadro = true;
                              });
                            }

                            // Si el usuario está moviendo, reiniciamos el temporizador
                            if (_debounce?.isActive ?? false) {
                              _debounce!.cancel();
                            }

                            // Si suelta el dedo por 600ms, se ejecuta esto:
                            _debounce = Timer(const Duration(milliseconds: 600), () {
                              if (!mounted) return;
                              final center = _mapController.camera.center;
                              setState(() {
                                _isMoviendoMapa = false;
                                _origenController.text =
                                    "Ubicación seleccionada (${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)})";
                              });
                            });
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.flutter_chapa',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _geometriaDibujar,
                              strokeWidth: 6,
                              color: Colors.blueAccent.withValues(alpha: 0.7),
                              borderColor: Colors.white,
                              borderStrokeWidth: 1,
                            ),
                          ],
                        ),
                      ],
                    ),

                    // 2. PIN CENTRAL
                    if (_isMoviendoMapa || _mostrarDobleCuadro)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 45,
                          ),
                        ),
                      ),

                    // 3. INTERFAZ SUPERIOR
                    Positioned(
                      top: 50,
                      left: 16,
                      right: 16,
                      child: _mostrarDobleCuadro
                          ? _buildDobleCuadro()
                          : _buildBuscadorSimple(),
                    ),

                    // 4. BOTÓN GPS (Habilitado)
                    Positioned(
                      bottom: 100,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: _usarGPS,
                        backgroundColor: Colors.white,
                        mini: true,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // 5. MENÚ INFERIOR
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  'Buses',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey.shade300,
                            ),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.alt_route,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Rutas',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBuscadorSimple() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: '¿A dónde quieres llegar?',
          prefixIcon: const Icon(Icons.search, color: Colors.black),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF0B1F40),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _buscarRuta,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDobleCuadro() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              const Icon(
                Icons.radio_button_unchecked,
                color: Colors.black,
                size: 20,
              ),
              Container(height: 15, width: 2, color: Colors.grey),
              const Icon(Icons.location_on, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _origenController,
                  decoration: const InputDecoration(
                    hintText: 'Elige un punto de partida...',
                    isDense: true,
                  ),
                ),
                const Divider(),
                TextField(
                  controller: _destinoController,
                  decoration: const InputDecoration(
                    hintText: 'Elige el lugar de destino...',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: () {
              final temp = _origenController.text;
              _origenController.text = _destinoController.text;
              _destinoController.text = temp;
            },
          ),
        ],
      ),
    );
  }
}
