import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../handlers/provider_handler.dart';
import '../http/auth.dart';

Router buildProviderRoutes(ProviderHandler handler, TokenService tokens) {
  final router = Router();

  router.get(
    '/services',
    requireAuth(tokens, roles: {'provider'})(handler.listServices),
  );
  router.patch(
    '/services/<id>/status',
    (Request request, String id) {
      final secured = requireAuth(
        tokens,
        roles: {'provider'},
      )((r) => handler.updateServiceStatus(r, id));
      return secured(request);
    },
  );

  router.get(
    '/jobs',
    requireAuth(tokens, roles: {'provider'})(handler.listJobs),
  );
  router.post('/jobs/<id>/accept', (Request request, String id) {
    final secured = requireAuth(tokens, roles: {'provider'})(
      (r) => handler.acceptJob(r, id),
    );
    return secured(request);
  });
  router.post('/jobs/<id>/decline', (Request request, String id) {
    final secured = requireAuth(tokens, roles: {'provider'})(
      (r) => handler.declineJob(r, id),
    );
    return secured(request);
  });
  router.post('/jobs/<id>/complete', (Request request, String id) {
    final secured = requireAuth(tokens, roles: {'provider'})(
      (r) => handler.completeJob(r, id),
    );
    return secured(request);
  });

  return router;
}
