import 'package:latlong2/latlong.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

class Ruta {
  final int? id;
  final String nombreCorto;
  final String nombreLargo;
  final String empresa;
  final bool esOficial;
  final List<LatLng> geometria;
  final double tarifaNormal;
  final double tarifaHoraPunta;
  final int frecuenciaMinutos;
  final String urlImagenReferencia;

  Ruta({
    this.id,
    required this.nombreCorto,
    required this.nombreLargo,
    required this.empresa,
    this.esOficial = true,
    required this.geometria,
    required this.tarifaNormal,
    required this.tarifaHoraPunta,
    this.frecuenciaMinutos = 15,
    this.urlImagenReferencia = '',
  });

  // Recortar -- Ver
  List<LatLng> getSegmento(int indiceInicio, int indiceFin) {
    if (indiceInicio < 0) indiceInicio = 0;
    if (indiceFin >= geometria.length) indiceFin = geometria.length - 1;
    if (indiceInicio > indiceFin) return [];
    return geometria.sublist(indiceInicio, indiceFin + 1);
  }

  Map<String, dynamic> toMap() {
    final List<List<num>> puntos = geometria
        .map((punto) => [punto.latitude, punto.longitude])
        .toList();
    final String geometriaCodificada = encodePolyline(puntos);

    return {
      'id': id,
      'nombre_corto': nombreCorto,
      'nombre_largo': nombreLargo,
      'empresa': empresa,
      'es_oficial': esOficial ? 1 : 0,
      'geometria': geometriaCodificada,
      'tarifa_normal': tarifaNormal,
      'tarifa_hora_punta': tarifaHoraPunta,
      'frecuencia_minutos': frecuenciaMinutos,
      'url_imagen': urlImagenReferencia,
    };
  }

  factory Ruta.fromMap(Map<String, dynamic> map) {
    final String geoString = map['geometria'] ?? '';
    final List<List<num>> puntosDecodificados = decodePolyline(geoString);
    final List<LatLng> puntos = puntosDecodificados
        .map((coords) => LatLng(coords[0].toDouble(), coords[1].toDouble()))
        .toList();

    return Ruta(
      id: map['id'],
      nombreCorto: map['nombre_corto'],
      nombreLargo: map['nombre_largo'],
      empresa: map['empresa'],
      esOficial: map['es_oficial'] == 1,
      geometria: puntos,
      tarifaNormal: (map['tarifa_normal'] as num).toDouble(),
      tarifaHoraPunta: (map['tarifa_hora_punta'] as num).toDouble(),
      frecuenciaMinutos: map['frecuencia_minutos'] ?? 15,
      urlImagenReferencia: map['url_imagen'] ?? '',
    );
  }
}
