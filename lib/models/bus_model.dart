class Bus {
  final int? id;
  final String placa;
  final int rutaId;
  final String empresa;
  final bool esRutaModificada;

  Bus({
    this.id,
    required this.placa,
    required this.rutaId,
    required this.empresa,
    this.esRutaModificada = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'placa': placa.toUpperCase().trim(),
      'ruta_id': rutaId,
      'empresa': empresa,
      'es_ruta_modificada': esRutaModificada ? 1 : 0,
    };
  }

  factory Bus.fromMap(Map<String, dynamic> map) {
    return Bus(
      id: map['id'] as int?,
      placa: map['placa'] as String,
      rutaId: map['ruta_id'] as int,
      empresa: map['empresa'] as String,
      esRutaModificada: map['es_ruta_modificada'] == 1,
    );
  }
}
