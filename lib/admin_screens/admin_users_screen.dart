import 'package:flutter/material.dart';
import 'package:ripo/admin_screens/admin_customer_details_screen.dart';
import 'package:ripo/admin_screens/admin_provider_details_screen.dart';
import 'package:ripo/data/api_exception.dart';
import 'package:ripo/data/repositories/admin_repository.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  final _adminRepository = AdminRepository();

  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _providers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customers = await _adminRepository.fetchUsers('customer');
      final providers = await _adminRepository.fetchUsers('provider');
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _providers = providers;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load users.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab Bar ──
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFF6950F4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF6950F4).withValues(alpha: 0.5)),
              ),
              labelColor: const Color(0xFF6950F4),
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              tabs: const [
                Tab(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.person_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Customers')
                    ])),
                Tab(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.storefront_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Providers')
                    ])),
              ],
            ),
          ),
        ),

        // ── Tab Content ──
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(
                                fontFamily: 'Inter', color: Colors.black54),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                              onPressed: _loadUsers,
                              child: const Text('Retry')),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCustomersList(),
                        _buildProvidersList(),
                      ],
                    ),
        ),
      ],
    );
  }

  // ── Customers List ──

  Widget _buildCustomersList() {
    if (_customers.isEmpty) {
      return const Center(
        child: Text(
          'No customers found.',
          style: TextStyle(fontFamily: 'Inter', color: Colors.black45),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _customers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _customers[index];
        return _buildUserCard(
          name: user['name']?.toString() ?? 'Customer',
          subtitle: user['subtitle']?.toString() ?? '',
          avatarIcon: Icons.person_rounded,
          avatarColor: const Color(0xFF2196F3),
          badgeText: user['badgeText']?.toString() ?? 'Active',
          badgeColor: const Color(0xFF4CAF50),
          isProvider: false,
        );
      },
    );
  }

  // ── Providers List ──

  Widget _buildProvidersList() {
    if (_providers.isEmpty) {
      return const Center(
        child: Text(
          'No providers found.',
          style: TextStyle(fontFamily: 'Inter', color: Colors.black45),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _providers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _providers[index];
        return _buildUserCard(
          name: user['name']?.toString() ?? 'Provider',
          subtitle: user['subtitle']?.toString() ?? '',
          avatarIcon: Icons.home_repair_service_rounded,
          avatarColor: const Color(0xFFFF9800),
          badgeText: user['badgeText']?.toString() ?? 'Verified',
          badgeColor: const Color(0xFF2196F3),
          isProvider: true,
        );
      },
    );
  }

  // ── Reusable Component ──

  Widget _buildUserCard({
    required String name,
    required String subtitle,
    required IconData avatarIcon,
    required Color avatarColor,
    required String badgeText,
    required Color badgeColor,
    required bool isProvider,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isProvider) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      AdminProviderDetailsScreen(businessName: name)));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AdminCustomerDetailsScreen(name: name)));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4))
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(avatarIcon, color: avatarColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54),
                  ),
                ],
              ),
            ),

            // Action Button
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                // Inline options
              },
              icon: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.black26, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            )
          ],
        ),
      ),
    );
  }
}
