import 'package:flutter/material.dart';
import 'package:ripo/admin_screens/admin_users_screen.dart';
import 'package:ripo/admin_screens/admin_offers_screen.dart';
import 'package:ripo/admin_screens/settings_screen.dart';
import 'package:ripo/admin_screens/admin_finance_screen.dart';
import 'package:ripo/data/api_exception.dart';
import 'package:ripo/data/repositories/admin_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminRepository = AdminRepository();

  int _selectedNavIndex = 0;
  bool _isOverviewLoading = true;
  String? _overviewError;
  Map<String, dynamic> _overviewStats = {
    'totalRevenue': 0,
    'activeJobs': 0,
    'totalUsers': 0,
    'providers': 0,
  };
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isOverviewLoading = true;
      _overviewError = null;
    });

    try {
      final payload = await _adminRepository.fetchDashboard();
      if (!mounted) return;

      setState(() {
        _overviewStats = Map<String, dynamic>.from(
          payload['stats'] as Map? ?? <String, dynamic>{},
        );
        final activityRaw = payload['activities'];
        if (activityRaw is List) {
          _activities = activityRaw
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } else {
          _activities = [];
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _overviewError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _overviewError = 'Failed to load admin overview.');
    } finally {
      if (mounted) {
        setState(() => _isOverviewLoading = false);
      }
    }
  }

  Widget _buildBodyContent() {
    // Scaffold Body Hub
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _selectedNavIndex == 1 || _selectedNavIndex == 3
              // Component screens (Users, Offers) have their own padding logic.
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: _buildActiveTabContent())
              : _selectedNavIndex == 4
                  // Settings/Profile screen manages its own Column + Expanded structure.
                  ? _buildActiveTabContent()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: _buildActiveTabContent(),
                    ),
        ),
      ],
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildOverviewContent();
      case 1:
        return const AdminUsersScreen();
      case 2:
        return const AdminFinanceScreen();
      case 3:
        return const AdminOffersScreen();
      case 4:
        return const AdminSettingsScreen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewContent() {
    if (_isOverviewLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_overviewError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _overviewError!,
              style:
                  const TextStyle(fontFamily: 'Inter', color: Colors.black54),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _loadOverview, child: const Text('Retry')),
          ],
        ),
      );
    }

    final totalRevenue = _overviewStats['totalRevenue']?.toString() ?? '0';
    final activeJobs = _overviewStats['activeJobs']?.toString() ?? '0';
    final totalUsers = _overviewStats['totalUsers']?.toString() ?? '0';
    final providers = _overviewStats['providers']?.toString() ?? '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Total Revenue',
                    'BDT $totalRevenue',
                    Icons.account_balance_wallet_rounded,
                    const Color(0xFF6950F4))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('Active Jobs', activeJobs,
                    Icons.handyman_rounded, const Color(0xFF00BFA5))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Total Users', totalUsers,
                    Icons.people_alt_rounded, const Color(0xFFFF9800))),
            const SizedBox(width: 16),
            Expanded(
                child: _buildStatCard('Providers', providers,
                    Icons.storefront_rounded, const Color(0xFFE91E63))),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Recent Activities',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        const SizedBox(height: 12),
        if (_activities.isEmpty)
          const Text(
            'No recent activities.',
            style: TextStyle(fontFamily: 'Inter', color: Colors.black45),
          )
        else
          ...List.generate(_activities.length, (index) {
            final item = _activities[index];
            return _buildActivityItem(
              icon: _iconFromKey(item['icon']?.toString() ?? ''),
              color: _colorFromHex(item['color']?.toString() ?? '#6950F4'),
              title: item['title']?.toString() ?? '',
              subtitle: item['subtitle']?.toString() ?? '',
              time: item['time']?.toString() ?? '',
              hasBadge: item['hasBadge'] == true,
              badgeLabel: item['badgeLabel']?.toString() ?? '',
              isLast: index == _activities.length - 1,
            );
          }),
        const SizedBox(height: 16),
      ],
    );
  }

  IconData _iconFromKey(String key) {
    switch (key) {
      case 'event_available':
        return Icons.event_available_rounded;
      case 'person_add':
        return Icons.person_add_rounded;
      case 'storefront':
        return Icons.storefront_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _colorFromHex(String hex) {
    // Normalize and validate hex string, default to purple if invalid
    try {
      var cleaned = hex.replaceAll('#', '');
      if (cleaned.length == 6) {
        cleaned = 'FF$cleaned'; // Add alpha channel if only RGB provided
      }
      if (cleaned.length != 8) {
        return const Color(0xFF6950F4); // Default purple
      }
      return Color(int.parse(cleaned, radix: 16));
    } catch (_) {
      return const Color(0xFF6950F4); // Default purple on parse error
    }
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
    bool hasBadge = false,
    String badgeLabel = '',
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline track
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                      width: 1.5, color: Colors.black.withValues(alpha: 0.06)),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 3))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87)),
                        ),
                        Text(time,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Colors.black38)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Colors.black54)),
                    if (hasBadge) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(badgeLabel,
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: color)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8A8F8), Color(0xFFE8D8FF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Profile and Greeting on Left side
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: const ClipOval(
                      child: Icon(Icons.admin_panel_settings_rounded,
                          color: Color(0xFF6950F4), size: 24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RIPO Admin',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87),
                      ),
                      Text(
                        'Welcome back Admin',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),

              // Notification on Right side
              IconButton(
                icon: const Icon(Icons.notifications_rounded,
                    color: Colors.black87, size: 20),
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      body: _buildBodyContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 16,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
                icon: Icons.dashboard_rounded, label: 'Overview', index: 0),
            _buildNavItem(
                icon: Icons.people_alt_rounded, label: 'Users', index: 1),
            _buildNavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Finances',
                index: 2),
            _buildNavItem(
                icon: Icons.local_offer_rounded, label: 'Offers', index: 3),
            _buildNavItem(
                icon: Icons.settings_rounded, label: 'Settings', index: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required String label, required int index}) {
    final selected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? const Color(0xFF6950F4) : Colors.black38,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? const Color(0xFF6950F4) : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
