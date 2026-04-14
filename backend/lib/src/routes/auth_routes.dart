// backend\lib\src\routes\auth_routes.dart
import 'package:shelf_router/shelf_router.dart';

import '../handlers/auth_handler.dart';

Router buildAuthRoutes(AuthHandler handler) {
  final router = Router();
  router.post('/login', handler.login);
  router.post('/register', handler.register);
  router.post('/forgot-password', handler.forgotPassword);
  return router;
}
