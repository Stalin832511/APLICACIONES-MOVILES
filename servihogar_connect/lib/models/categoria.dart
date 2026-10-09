class CategoriaModel {
  final int id;
  final String nombre;
  final String? descripcion;

  const CategoriaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    return CategoriaModel(
      id: (json['idCategoria'] ?? json['IdCategoria']) as int,
      nombre: (json['nombre'] ?? json['Nombre']) as String,
      descripcion:
          (json['descripcion'] ?? json['Descripcion']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'idCategoria': id,
        'nombre': nombre,
        'descripcion': descripcion,
      };
}
