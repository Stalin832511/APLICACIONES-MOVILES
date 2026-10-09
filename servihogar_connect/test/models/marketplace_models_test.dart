import 'package:flutter_test/flutter_test.dart';
import 'package:servihogar_connect/models/marketplace_models.dart';

void main() {
  group('ProfessionalRequestsPage', () {
    test('parses a paginated professional request response', () {
      final page = ProfessionalRequestsPage.fromJson({
        'items': [
          {
            'idSolicitud': 14,
            'idCategoria': 3,
            'categoria': {'nombre': 'Plomería'},
            'descripcion': 'Reparar una fuga',
            'fechaCreacion': '2026-09-30T08:15:00Z',
            'latitud': 19.4,
            'longitud': '-99.1',
          },
        ],
        'page': 2,
        'pageSize': 20,
        'totalCount': 25,
        'totalPages': 2,
      });

      expect(page.page, 2);
      expect(page.totalCount, 25);
      expect(page.items.single.idSolicitud, 14);
      expect(page.items.single.idCategoria, 3);
      expect(page.items.single.categoriaNombre, 'Plomería');
      expect(page.items.single.longitud, -99.1);
    });
  });

  test('parses assignment status and accepted quote details', () {
    final assignment = ProfessionalRequest.fromJson({
      'idSolicitud': 21,
      'idCotizacion': 32,
      'estado': 'asignada',
      'descripcion': 'Instalar un grifo',
      'fechaCreacion': '2026-10-01T10:00:00Z',
      'categoria': {'nombre': 'Plomería'},
      'precioOfertado': 850.5,
      'tiempoEstimado': '90 minutos',
    });

    expect(assignment.idSolicitud, 21);
    expect(assignment.idCotizacion, 32);
    expect(assignment.estado, 'asignada');
    expect(assignment.precioOfertado, 850.5);
    expect(assignment.tiempoEstimado, '90 minutos');
  });

  test('parses quote details and professional metadata', () {
    final quote = MarketplaceQuote.fromJson({
      'idCotizacion': 8,
      'idSolicitud': 14,
      'idProfesional': 5,
      'precioOfertado': '1200.50',
      'tiempoEstimado': '2 horas',
      'estado': 'pendiente',
      'yaCalificado': true,
      'profesional': {
        'nombre': 'Alex Rivera',
        'especialidad': 'Plomería',
        'calificacionPromedio': 4.8,
      },
    });

    expect(quote.idCotizacion, 8);
    expect(quote.precioOfertado, 1200.5);
    expect(quote.profesionalNombre, 'Alex Rivera');
    expect(quote.calificacionPromedio, 4.8);
    expect(quote.yaCalificado, isTrue);
  });

  test('parses quote list together with the request lifecycle state', () {
    final response = MarketplaceQuotesResponse.fromJson({
      'items': [
        {
          'idCotizacion': 8,
          'idSolicitud': 14,
          'idProfesional': 5,
          'precioOfertado': 1200,
          'tiempoEstimado': '2 horas',
          'estado': 'aceptada',
        },
      ],
      'estado': 'completada',
    });

    expect(response.items.single.idProfesional, 5);
    expect(response.estado, 'completada');
  });

  test('parses admin counts and category active state', () {
    final summary = MarketplaceSummary.fromJson({
      'solicitudesPendientes': '4',
      'totalSolicitudesEnProceso': 2,
      'solicitudesCompletadas': 12,
      'profesionalesActivos': 7,
      'categoriasActivas': 5,
    });
    final category = MarketplaceCategory.fromJson({
      'idCategoria': 3,
      'nombre': 'Plomería',
      'descripcion': 'Instalación y reparación',
      'activa': false,
    });

    expect(summary.solicitudesPendientes, 4);
    expect(summary.solicitudesEnProceso, 2);
    expect(category.idCategoria, 3);
    expect(category.activa, isFalse);
  });

  test('parses an admin professional profile and its user account', () {
    final professional = MarketplaceProfessional.fromJson({
      'idProfesional': 11,
      'idUsuario': 9,
      'especialidad': 'Electricidad',
      'descripcion': 'Instalaciones residenciales',
      'tarifaHora': 250.5,
      'calificacionPromedio': 4.7,
      'usuario': {
        'nombre': 'María',
        'apellido': 'López',
        'email': 'maria@example.com',
      },
    });

    expect(professional.idProfesional, 11);
    expect(professional.idUsuario, 9);
    expect(professional.nombreUsuario, 'María López');
    expect(professional.emailUsuario, 'maria@example.com');
    expect(professional.tarifaHora, 250.5);
  });

  test('parses eligible admin user fields', () {
    final user = MarketplaceAdminUser.fromJson({
      'id': 42,
      'nombre': 'Ana',
      'apellido': 'García',
      'email': 'ana@example.com',
      'tipoUsuario': 'cliente',
    });

    expect(user.id, 42);
    expect(user.nombreCompleto, 'Ana García');
    expect(user.email, 'ana@example.com');
    expect(user.tipoUsuario, 'cliente');
  });

  test('accepts the backend role aliases for an eligible admin user', () {
    final user = MarketplaceAdminUser.fromJson({
      'idUsuario': 43,
      'nombre': 'Luis',
      'apellido': 'Ortiz',
      'email': 'luis@example.com',
      'tipoUsuario': 'cliente',
    });

    expect(user.id, 43);
    expect(user.nombreCompleto, 'Luis Ortiz');
    expect(user.email, 'luis@example.com');
  });
}
