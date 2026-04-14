import 'package:flutter/material.dart';
import 'package:ripo/data/api_exception.dart';
import 'package:ripo/data/repositories/provider_repository.dart';

class ProviderJobsScreen extends StatefulWidget {
  const ProviderJobsScreen({super.key});

  @override
  State<ProviderJobsScreen> createState() => _ProviderJobsScreenState();
}

class _ProviderJobsScreenState extends State<ProviderJobsScreen>
    with SingleTickerProviderStateMixin {
  final _providerRepository = ProviderRepository();

  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _active = [];
  List<Map<String, dynamic>> _completed = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final jobs = await _providerRepository.fetchJobs();
      if (!mounted) return;
      setState(() {
        _requests = jobs['requests'] ?? [];
        _active = jobs['active'] ?? [];
        _completed = jobs['completed'] ?? [];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load jobs.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptJob(String id) async {
    try {
      await _providerRepository.acceptJob(id);
      await _loadJobs();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _declineJob(String id) async {
    try {
      await _providerRepository.declineJob(id);
      await _loadJobs();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> _completeJob(String id) async {
    try {
      await _providerRepository.completeJob(id);
      await _loadJobs();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
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
                              fontFamily: 'Inter',
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                              onPressed: _loadJobs, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRequestsTab(),
                        _buildActiveTab(),
                        _buildCompletedTab(),
                      ],
                    ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SafeArea(
        bottom: false,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Job Management',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelColor: const Color(0xFF6950F4),
        unselectedLabelColor: Colors.black45,
        indicatorColor: const Color(0xFF6950F4),
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Requests'),
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  // ── Tabs content ─────────────────────────────────────────────────────────

  Widget _buildRequestsTab() {
    if (_requests.isEmpty) return _buildEmptyTab('No pending requests.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final job = _requests[index];
        final id = job['id']?.toString() ?? '';
        return _buildJobCard(
          status: (job['status']?.toString() ?? 'Pending Request'),
          statusColor: const Color(0xFFFF8F00),
          statusBgColor: const Color(0xFFFFF3E0),
          name: job['name']?.toString() ?? 'Unknown',
          service: job['service']?.toString() ?? 'Service',
          address: job['address']?.toString() ?? 'N/A',
          date: job['date']?.toString() ?? 'N/A',
          price: job['price']?.toString() ?? '0',
          avatar: Icons.person,
          actionButtons: _buildActionButtons(
            negativeLabel: 'Decline',
            positiveLabel: 'Accept',
            onNegative: () => _declineJob(id),
            onPositive: () => _acceptJob(id),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab() {
    if (_active.isEmpty) return _buildEmptyTab('No active jobs.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _active.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final job = _active[index];
        final id = job['id']?.toString() ?? '';
        return _buildJobCard(
          status: 'In Progress',
          statusColor: const Color(0xFF1E88E5),
          statusBgColor: const Color(0xFFE8F4FD),
          name: job['name']?.toString() ?? 'Unknown',
          service: job['service']?.toString() ?? 'Service',
          address: job['address']?.toString() ?? 'N/A',
          date: job['date']?.toString() ?? 'N/A',
          price: job['price']?.toString() ?? '0',
          avatar: Icons.person_2,
          showContactOptions: true,
          actionButtons: _buildActionButtons(
            negativeLabel: 'Cancel Job',
            positiveLabel: 'Mark Completed',
            onNegative: () => _declineJob(id),
            onPositive: () => _completeJob(id),
          ),
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    if (_completed.isEmpty) return _buildEmptyTab('No completed jobs yet.');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _completed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        final job = _completed[index];
        return _buildJobCard(
          status: 'Completed',
          statusColor: const Color(0xFF43A047),
          statusBgColor: const Color(0xFFE8F5E9),
          name: job['name']?.toString() ?? 'Unknown',
          service: job['service']?.toString() ?? 'Service',
          address: job['address']?.toString() ?? 'N/A',
          date: job['date']?.toString() ?? 'N/A',
          price: job['price']?.toString() ?? '0',
          avatar: Icons.person,
          isCompleted: true,
        );
      },
    );
  }

  Widget _buildEmptyTab(String label) {
    return Center(
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: Colors.black45,
        ),
      ),
    );
  }

  // ── Job Card ─────────────────────────────────────────────────────────────

  Widget _buildJobCard({
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required String name,
    required String service,
    required String address,
    required String date,
    required String price,
    required IconData avatar,
    bool showContactOptions = false,
    bool isCompleted = false,
    Widget? actionButtons,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                '৳ $price',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F4FD),
                  shape: BoxShape.circle,
                ),
                child: Icon(avatar, color: const Color(0xFF1E88E5), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF6950F4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (showContactOptions)
                Row(
                  children: [
                    _buildIconButton(
                        Icons.chat_bubble_rounded, const Color(0xFF6950F4)),
                    const SizedBox(width: 8),
                    _buildIconButton(
                        Icons.call_rounded, const Color(0xFF43A047)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.black12, height: 1),
          const SizedBox(height: 16),

          // Details
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 16, color: Colors.black38),
              const SizedBox(width: 8),
              Text(address,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  size: 16, color: Colors.black38),
              const SizedBox(width: 8),
              Text(date,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.black54)),
            ],
          ),

          // Action Buttons
          if (actionButtons != null) ...[
            const SizedBox(height: 20),
            actionButtons,
          ],

          // Completed Note
          if (isCompleted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 16, color: Color(0xFF43A047)),
                const SizedBox(width: 6),
                const Text('Payment Received',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF43A047))),
                const Spacer(),
                const Icon(Icons.star_rounded,
                    size: 16, color: Color(0xFFFF8F00)),
                const SizedBox(width: 4),
                const Text('5.0',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildActionButtons({
    required String negativeLabel,
    required String positiveLabel,
    required VoidCallback onNegative,
    required VoidCallback onPositive,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onNegative,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF5252)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(negativeLabel,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF5252))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onPositive,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6950F4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(positiveLabel,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
