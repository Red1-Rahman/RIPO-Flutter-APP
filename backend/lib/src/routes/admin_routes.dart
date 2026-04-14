import 'package:shelf_router/shelf_router.dart';

import '../handlers/admin_handler.dart';
import '../http/auth.dart';

Router buildAdminRoutes(AdminHandler handler, TokenService tokens) {
  final router = Router();

  router.get('/dashboard', requireAuth(tokens, roles: {'admin'})(handler.dashboard));
  router.get('/users', requireAuth(tokens, roles: {'admin'})(handler.users));
  router.get('/finance', requireAuth(tokens, roles: {'admin'})(handler.finance));

  return router;
}
