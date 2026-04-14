import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

import '../http/error_response.dart';
import '../http/json_response.dart';

class AdminHandler {
  AdminHandler({required this.db});

  final Database db;

  Response dashboard(Request request) {
    try {
      final revenueRow = db.select(
        'SELECT COALESCE(SUM(CASE WHEN is_incoming = 1 THEN amount ELSE -amount END), 0) AS total FROM transactions',
      ).first;
      final activeJobsRow = db.select(
        "SELECT COUNT(*) AS total FROM provider_jobs WHERE status IN ('Pending Request', 'In Progress')",
      ).first;
      final usersRow = db.select(
        '''
          SELECT COUNT(*) AS total
          FROM users u JOIN roles r ON r.id = u.role_id
          WHERE r.name = 'customer'
        ''',
      ).first;
      final providersRow = db.select(
        '''
          SELECT COUNT(*) AS total
          FROM users u JOIN roles r ON r.id = u.role_id
          WHERE r.name = 'provider'
        ''',
      ).first;

      final activities = [
        {
          'icon': 'event_available',
          'color': '#4CAF50',
          'title': 'New Booking Confirmed',
          'subtitle': 'Customer created a booking',
          'time': '2 min ago',
          'hasBadge': false,
        },
        {
          'icon': 'person_add',
          'color': '#2196F3',
          'title': 'New Customer Joined',
          'subtitle': 'A new customer account was created',
          'time': '18 min ago',
          'hasBadge': false,
        },
        {
          'icon': 'payments',
          'color': '#9C27B0',
          'title': 'Payout Released',
          'subtitle': 'Recent payout processed for provider',
          'time': '1 hr ago',
          'hasBadge': true,
          'badgeLabel': 'Finance',
        },
      ];

      return ok({
        'stats': {
          'totalRevenue': revenueRow['total'],
          'activeJobs': activeJobsRow['total'],
          'totalUsers': usersRow['total'],
          'providers': providersRow['total'],
        },
        'activities': activities,
      });
    } catch (_) {
      return internalError();
    }
  }

  Response users(Request request) {
    try {
      final role = (request.url.queryParameters['role'] ?? 'customer').toLowerCase();
      if (!{'customer', 'provider'}.contains(role)) {
        return badRequest('role must be customer or provider.');
      }

      final rows = db.select(
        '''
          SELECT u.id, u.full_name, u.email, u.phone
          FROM users u
          JOIN roles r ON r.id = u.role_id
          WHERE r.name = ?
          ORDER BY u.id DESC
        ''',
        [role],
      );

      final payload = rows
          .map(
            (row) => {
              'id': row['id'].toString(),
              'name': row['full_name'],
              'subtitle': role == 'provider'
                  ? '${row['full_name']} • ID: P${row['id']}'
                  : row['email'],
              'email': row['email'],
              'phone': row['phone'],
              'badgeText': role == 'provider' ? 'Verified' : 'Active',
              'isProvider': role == 'provider',
            },
          )
          .toList();

      return ok(payload);
    } catch (_) {
      return internalError();
    }
  }

  Response finance(Request request) {
    try {
      final revenueRow = db.select(
        'SELECT COALESCE(SUM(CASE WHEN is_incoming = 1 THEN amount ELSE -amount END), 0) AS total FROM transactions',
      ).first;
      final commissionRow = db.select(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions WHERE is_incoming = 1',
      ).first;
      final pendingRow = db.select(
        "SELECT COALESCE(SUM(amount), 0) AS total FROM payouts WHERE status = 'pending'",
      ).first;
      final totalJobsRow = db.select('SELECT COUNT(*) AS total FROM provider_jobs').first;

      final payouts = db.select(
        '''
          SELECT business, owner_name, amount, jobs_completed
          FROM payouts
          WHERE status = 'pending'
          ORDER BY id DESC
        ''',
      );

      final transactions = db.select(
        'SELECT title, amount, is_incoming, created_at FROM transactions ORDER BY id DESC',
      );

      return ok({
        'platformRevenue': revenueRow['total'],
        'trend': '+18% this month',
        'commissionEarned': commissionRow['total'],
        'pendingPayouts': pendingRow['total'],
        'totalJobs': totalJobsRow['total'],
        'payouts': payouts
            .map(
              (row) => {
                'business': row['business'],
                'owner': row['owner_name'],
                'amount': row['amount'],
                'subtitle': '${row['jobs_completed']} jobs completed',
              },
            )
            .toList(),
        'transactions': transactions
            .map(
              (row) => {
                'title': row['title'],
                'amount': row['amount'],
                'isIncoming': (row['is_incoming'] as int) == 1,
                'date': row['created_at'],
              },
            )
            .toList(),
      });
    } catch (_) {
      return internalError();
    }
  }
}
