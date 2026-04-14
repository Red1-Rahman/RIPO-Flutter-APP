// backend\lib\src\routes\booking_routes.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../handlers/booking_handler.dart';
import '../http/auth.dart';

Router buildBookingRoutes(BookingHandler handler, TokenService tokens) {
  final router = Router();

  router.get('/availability', handler.getAvailability);
  router.post(
      '/', requireAuth(tokens, roles: {'customer'})(handler.createBooking));
  router.get(
    '/my',
    requireAuth(tokens, roles: {'customer'})(handler.listMyBookings),
  );
  router.get('/<id>', (Request request, String id) {
    final secured = requireAuth(
      tokens,
      roles: {'customer', 'provider', 'admin'},
    )((r) => handler.bookingDetails(r, id));
    return secured(request);
  });

  return router;
}
