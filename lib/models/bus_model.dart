class Bus {
  final int? id;
  final String placa;
  final int rutaId; //
  final String empresa; //
  final bool esRutaModificadaPorUsuario;

  Bus({
    this.id,
    required this.placa,
    required this.rutaId,
    required this.empresa,
    this.esRutaModificadaPorUsuario = false,
  });
}
