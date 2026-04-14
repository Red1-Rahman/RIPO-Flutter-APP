// backend\lib\src\db\schema.dart
import 'package:sqlite3/sqlite3.dart';

import '../http/auth.dart';

void createSchema(Database db) {
  db.execute('''
    CREATE TABLE IF NOT EXISTS roles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      full_name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      phone TEXT,
      password_hash TEXT NOT NULL,
      role_id INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (role_id) REFERENCES roles(id)
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      image TEXT
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS services (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      provider_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      category_id INTEGER NOT NULL,
      image TEXT,
      price INTEGER NOT NULL,
      original_price INTEGER NOT NULL,
      discount TEXT NOT NULL,
      rating REAL NOT NULL,
      reviews INTEGER NOT NULL,
      duration TEXT NOT NULL,
      distance TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      FOREIGN KEY (provider_id) REFERENCES users(id),
      FOREIGN KEY (category_id) REFERENCES categories(id)
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS bookings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id INTEGER NOT NULL,
      provider_id INTEGER NOT NULL,
      service_id INTEGER NOT NULL,
      status TEXT NOT NULL,
      booking_date TEXT NOT NULL,
      time_slot TEXT NOT NULL,
      address TEXT NOT NULL,
      price INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (customer_id) REFERENCES users(id),
      FOREIGN KEY (provider_id) REFERENCES users(id),
      FOREIGN KEY (service_id) REFERENCES services(id)
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS provider_jobs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      provider_id INTEGER NOT NULL,
      booking_id INTEGER NOT NULL,
      status TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (provider_id) REFERENCES users(id),
      FOREIGN KEY (booking_id) REFERENCES bookings(id)
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS payouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      business TEXT NOT NULL,
      owner_name TEXT NOT NULL,
      provider_id INTEGER NOT NULL,
      amount INTEGER NOT NULL,
      jobs_completed INTEGER NOT NULL,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (provider_id) REFERENCES users(id)
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount INTEGER NOT NULL,
      is_incoming INTEGER NOT NULL,
      created_at TEXT NOT NULL
    );
  ''');
}

void seedIfEmpty(Database db) {
  final count =
      db.select('SELECT COUNT(*) AS count FROM users').first['count'] as int;
  if (count > 0) {
    return;
  }

  final now = DateTime.now().toIso8601String();

  db.execute('INSERT INTO roles (name) VALUES (?), (?), (?)',
      ['customer', 'provider', 'admin']);

  db.execute(
    '''
      INSERT INTO users (full_name, email, phone, password_hash, role_id, created_at)
      VALUES
      (?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?)
    ''',
    [
      'Customer One',
      'customer@ripo.com',
      '01700000001',
      hashPassword('1234'),
      1,
      now,
      'Provider One',
      'provider@ripo.com',
      '01700000002',
      hashPassword('1234'),
      2,
      now,
      'Admin User',
      'admin@ripo.com',
      '01700000003',
      hashPassword('1234'),
      3,
      now,
      'Customer Two',
      'tania@ripo.com',
      '01700000004',
      hashPassword('1234'),
      1,
      now,
      'Elite Services BD',
      'elite@ripo.com',
      '01700000005',
      hashPassword('1234'),
      2,
      now,
      'Quick Fix Pro',
      'quickfix@ripo.com',
      '01700000006',
      hashPassword('1234'),
      2,
      now,
    ],
  );

  db.execute(
    'INSERT INTO categories (name, image) VALUES (?, ?), (?, ?), (?, ?), (?, ?), (?, ?)',
    [
      'AC Repair',
      'lib/media/AC_servicing.png',
      'Electronics',
      'lib/media/electronics_servicing.png',
      'Cleaning',
      'lib/media/clean_house_offer.png',
      'Painting',
      'lib/media/paint_servicing.png',
      'Water Filter',
      'lib/media/water_filter_servicing.png',
    ],
  );

  db.execute(
    '''
      INSERT INTO services
      (provider_id, name, category_id, image, price, original_price, discount, rating, reviews, duration, distance, is_active, created_at)
      VALUES
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      2,
      'AC Servicing',
      1,
      'lib/media/AC_servicing.png',
      1200,
      2000,
      '40% OFF',
      4.8,
      142,
      '45 mins',
      '2.1 km',
      1,
      now,
      2,
      'Electronics Service',
      2,
      'lib/media/electronics_servicing.png',
      800,
      1600,
      '50% OFF',
      4.5,
      88,
      '60 mins',
      '3.4 km',
      1,
      now,
      5,
      'House Cleaning',
      3,
      'lib/media/clean_house_offer.png',
      2000,
      2500,
      '20% OFF',
      4.9,
      203,
      '2 hrs',
      '4.1 km',
      1,
      now,
      6,
      'Painting',
      4,
      'lib/media/paint_servicing.png',
      3500,
      4500,
      '35% OFF',
      4.7,
      57,
      '3 hrs',
      '5.2 km',
      0,
      now,
      5,
      'Water Filter Installation',
      5,
      'lib/media/water_filter_servicing.png',
      850,
      1100,
      '23% OFF',
      4.3,
      34,
      '30 mins',
      '3.8 km',
      1,
      now,
    ],
  );

  db.execute(
    '''
      INSERT INTO bookings
      (customer_id, provider_id, service_id, status, booking_date, time_slot, address, price, created_at)
      VALUES
      (?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      1,
      2,
      1,
      'Pending',
      '2026-04-15',
      '10 AM - 11 AM',
      'Banani, Dhaka',
      1200,
      now,
      1,
      5,
      3,
      'Accepted',
      '2026-04-16',
      '11 AM - 12 PM',
      'Uttara, Dhaka',
      2000,
      now,
      4,
      2,
      2,
      'In progress',
      '2026-04-14',
      '3 PM - 4 PM',
      'Mirpur, Dhaka',
      800,
      now,
      1,
      6,
      4,
      'Completed',
      '2026-04-10',
      '4 PM - 5 PM',
      'Tongi, Gazipur',
      3500,
      now,
    ],
  );

  db.execute(
    '''
      INSERT INTO provider_jobs (provider_id, booking_id, status, updated_at)
      VALUES
      (?, ?, ?, ?),
      (?, ?, ?, ?),
      (?, ?, ?, ?),
      (?, ?, ?, ?)
    ''',
    [
      2,
      1,
      'Pending Request',
      now,
      5,
      2,
      'Pending Request',
      now,
      2,
      3,
      'In Progress',
      now,
      6,
      4,
      'Completed',
      now,
    ],
  );

  db.execute(
    '''
      INSERT INTO payouts (business, owner_name, provider_id, amount, jobs_completed, status, created_at)
      VALUES
      (?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?),
      (?, ?, ?, ?, ?, ?, ?)
    ''',
    [
      'Elite Servicing BD',
      'Shaidul Islam',
      5,
      12400,
      3,
      'pending',
      now,
      'Quick Fix Pro',
      'Rafiul Hasan',
      6,
      8750,
      2,
      'pending',
      now,
      'Provider One',
      'Provider One',
      2,
      5200,
      1,
      'pending',
      now,
    ],
  );

  db.execute(
    '''
      INSERT INTO transactions (title, amount, is_incoming, created_at)
      VALUES
      (?, ?, ?, ?),
      (?, ?, ?, ?),
      (?, ?, ?, ?),
      (?, ?, ?, ?),
      (?, ?, ?, ?)
    ''',
    [
      'Commission - AC Service',
      1200,
      1,
      '2026-04-13',
      'Payout - Elite BD',
      11000,
      0,
      '2026-04-12',
      'Commission - Plumbing Fix',
      500,
      1,
      '2026-04-12',
      'Payout - Quick Fix Pro',
      7400,
      0,
      '2026-04-11',
      'Commission - House Cleaning',
      800,
      1,
      '2026-04-11',
    ],
  );
}
