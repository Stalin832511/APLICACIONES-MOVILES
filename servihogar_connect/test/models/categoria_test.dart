import 'package:flutter_test/flutter_test.dart';
import 'package:servihogar_connect/models/categoria.dart';

void main() {
  group('CategoriaModel', () {
    test('lee la respuesta JSON de la API', () {
      final categoria = CategoriaModel.fromJson({
        'idCategoria': 4,
        'nombre': 'Electricidad',
        'descripcion': 'Instalaciones y averías',
      });

      expect(categoria.id, 4);
      expect(categoria.nombre, 'Electricidad');
      expect(categoria.descripcion, 'Instalaciones y averías');
    });

    test('acepta nombres de propiedades PascalCase', () {
      final categoria = CategoriaModel.fromJson({
        'IdCategoria': 2,
        'Nombre': 'Plomería',
        'Descripcion': null,
      });

      expect(categoria.id, 2);
      expect(categoria.nombre, 'Plomería');
      expect(categoria.descripcion, isNull);
    });

    test('serializa los campos necesarios para la caché local', () {
      const categoria = CategoriaModel(
        id: 7,
        nombre: 'Jardinería',
        descripcion: 'Mantenimiento de jardines',
      );

      expect(categoria.toJson(), {
        'idCategoria': 7,
        'nombre': 'Jardinería',
        'descripcion': 'Mantenimiento de jardines',
      });
    });
  });
}
