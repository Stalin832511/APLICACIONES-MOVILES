import 'package:flutter_test/flutter_test.dart';
import 'package:servihogar_connect/models/solicitud.dart';
import 'package:servihogar_connect/widgets/status_badge.dart';

void main() {
  test('maps lifecycle states used by the API to mobile request status', () {
    expect(
      RequestStatusParsing.fromApiValue('publicada'),
      RequestStatus.pendiente,
    );
    expect(
      RequestStatusParsing.fromApiValue('asignada'),
      RequestStatus.pendiente,
    );
    expect(
      RequestStatusParsing.fromApiValue('en proceso'),
      RequestStatus.enProceso,
    );
    expect(
      RequestStatusParsing.fromApiValue('completada'),
      RequestStatus.completado,
    );
  });

  test('parses paged requests and category identifiers', () {
    final page = SolicitudesPage.fromJson({
      'items': [
        {
          'idSolicitud': 12,
          'descripcion': 'Revisar tubería',
          'estado': 'En camino',
          'fechaCreacion': '2026-09-30T10:00:00Z',
          'idCategoria': 4,
          'categoria': {'nombre': 'Plomería'},
        },
      ],
      'page': 2,
      'pageSize': 20,
      'totalCount': 41,
      'totalPages': 3,
    });

    expect(page.page, 2);
    expect(page.pageSize, 20);
    expect(page.totalCount, 41);
    expect(page.totalPages, 3);
    expect(page.items.single.idCategoria, 4);
    expect(page.items.single.categoriaNombre, 'Plomería');
    expect(page.items.single.status, RequestStatus.enCamino);
  });

  test('preserves original state and full customer name for admin review', () {
    final request = SolicitudModel.fromJson({
      'idSolicitud': 28,
      'descripcion': 'Reparación de instalación',
      'estado': 'cancelada',
      'fechaCreacion': '2026-10-05T10:00:00Z',
      'categoria': {'idCategoria': 2, 'nombre': 'Electricidad'},
      'usuario': {
        'idUsuario': 15,
        'nombre': 'Ana',
        'apellido': 'García',
      },
    });

    expect(request.estadoOriginal, 'cancelada');
    expect(request.usuarioNombre, 'Ana García');
    expect(request.idCategoria, 2);
  });

  test('derives page count when the server omits totalPages', () {
    final page = SolicitudesPage.fromJson({
      'items': [],
      'page': 1,
      'pageSize': 20,
      'totalCount': 21,
    });

    expect(page.totalPages, 2);
  });

  test('parses a locally queued request with its category and evidence', () {
    final request = SolicitudModel.fromPendingPayload(
      localId: -1,
      payload: {
        'clientOperationId': 'operation-123',
        'idCategoria': 4,
        'descripcion': 'Revisar fuga de agua',
        'latitud': 19.4326,
        'longitud': -99.1332,
        'fotoPath': r'C:\app\evidence\photo.jpg',
      },
      createdAt: DateTime(2026, 10, 3, 12),
      categoryName: 'Plomería',
      syncFailed: false,
    );

    expect(request.id, -1);
    expect(request.pendingSync, isTrue);
    expect(request.syncFailed, isFalse);
    expect(request.idCategoria, 4);
    expect(request.categoriaNombre, 'Plomería');
    expect(request.clientOperationId, 'operation-123');
    expect(request.latitud, 19.4326);
    expect(request.longitud, -99.1332);
    expect(request.localPhotoPath, r'C:\app\evidence\photo.jpg');
    expect(request.status, RequestStatus.pendiente);
  });
}
