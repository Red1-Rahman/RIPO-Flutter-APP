// backend\lib\src\server.dart
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'db/database.dart';
import 'handlers/admin_handler.dart';
import 'handlers/auth_handler.dart';
import 'handlers/booking_handler.dart';
import 'handlers/customer_handler.dart';
import 'handlers/provider_handler.dart';
import 'http/auth.dart';
import 'http/json_response.dart';
import 'routes/admin_routes.dart';
import 'routes/auth_routes.dart';
import 'routes/booking_routes.dart';
import 'routes/customer_routes.dart';
import 'routes/provider_routes.dart';

const _corsHeaders = <String, String>{
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
};

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response(204, headers: _corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        ...response.headers,
        ..._corsHeaders,
      });
    };
  };
}

Handler createHandler({String? dbFilePath}) {
  final db = AppDatabase.openLocal(filePath: dbFilePath);
  final tokenService = TokenService(
    Platform.environment['RIPO_API_SECRET'] ?? 'ripo-local-secret',
  );

  final authHandler = AuthHandler(db: db.db, tokens: tokenService);
  final customerHandler = CustomerHandler(db: db.db);
  final bookingHandler = BookingHandler(db: db.db);
  final providerHandler = ProviderHandler(db: db.db);
  final adminHandler = AdminHandler(db: db.db);

  final router = Router()
    ..get('/health', (_) => ok({'status': 'ok'}))
    ..mount('/auth/', buildAuthRoutes(authHandler).call)
    ..mount('/customer/', buildCustomerRoutes(customerHandler).call)
    ..mount('/bookings/', buildBookingRoutes(bookingHandler, tokenService).call)
    ..mount(
        '/provider/', buildProviderRoutes(providerHandler, tokenService).call)
    ..mount('/admin/', buildAdminRoutes(adminHandler, tokenService).call);

  return Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(router.call);
}

Future<HttpServer> startServer({
  int port = 8080,
  String host = '127.0.0.1',
  String? dbFilePath,
}) async {
  final handler = createHandler(dbFilePath: dbFilePath);
  final server = await io.serve(handler, host, port);
  stdout.writeln(
      'RIPO local API running on http://${server.address.host}:${server.port}');
  return server;
}
