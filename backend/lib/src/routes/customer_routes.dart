// backend\lib\src\routes\customer_routes.dart
import 'package:shelf_router/shelf_router.dart';

import '../handlers/customer_handler.dart';

Router buildCustomerRoutes(CustomerHandler handler) {
  final router = Router();
  router.get('/services', handler.getServices);
  router.get('/services/recommended', handler.getRecommendedServices);
  router.get('/categories', handler.getCategories);
  router.get('/services/<id>', handler.getServiceById);
  return router;
}
