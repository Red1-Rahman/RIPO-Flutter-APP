import 'package:flutter/material.dart';
import 'package:ripo/data/api_exception.dart';
import 'package:ripo/data/repositories/admin_repository.dart';

class AdminFinanceScreen extends StatefulWidget {
  const AdminFinanceScreen({super.key});

  @override
  State<AdminFinanceScreen> createState() => _AdminFinanceScreenState();
}

class _AdminFinanceScreenState extends State<AdminFinanceScreen> {
  final _adminRepository = AdminRepository();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _finance = {
    'platformRevenue': 0,
    'trend': '+0%',
    'commissionEarned': 0,
    'pendingPayouts': 0,
    'totalJobs': 0,
    'payouts': <Map<String, dynamic>>[],
    'transactions': <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _loadFinance();
  }

  Future<void> _loadFinance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payload = await _adminRepository.fetchFinance();
      if (!mounted) return;
      setState(() => _finance = payload);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load finance data.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style:
                  const TextStyle(fontFamily: 'Inter', color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadFinance, child: const Text('Retry')),
          ],
        ),
      );
    }

    final payoutsRaw = _finance['payouts'];
    final transactionsRaw = _finance['transactions'];
    final payouts = payoutsRaw is List
        ? payoutsRaw
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
        : <Map<String, dynamic>>[];
    final transactions = transactionsRaw is List
        ? transactionsRaw
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRevenueBanner(),
          const SizedBox(height: 16),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildSectionTitle('Pending Payouts'),
          const SizedBox(height: 12),
          if (payouts.isEmpty)
            const Text(
              'No pending payouts.',
              style: TextStyle(fontFamily: 'Inter', color: Colors.black45),
            )
          else
            ...payouts.map(
              (payout) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildPendingPayoutCard(
                  payout['business']?.toString() ?? 'Business',
                  payout['owner']?.toString() ?? 'Owner',
                  'BDT ${payout['amount']?.toString() ?? '0'}',
                  payout['subtitle']?.toString() ?? '',
                ),
              ),
            ),
          const SizedBox(height: 24),
          _buildSectionTitle('Recent Transactions'),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Text(
              'No transactions found.',
              style: TextStyle(fontFamily: 'Inter', color: Colors.black45),
            )
          else
            ...transactions.map(
              (item) => _buildTransactionItem(
                item['title']?.toString() ?? '',
                '${item['isIncoming'] == true ? '+' : '-'}BDT ${item['amount']?.toString() ?? '0'}',
                item['date']?.toString() ?? '',
                item['isIncoming'] == true,
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRevenueBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6950F4), Color(0xFF8C7AF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x406950F4), blurRadius: 14, offset: Offset(0, 6))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(Icons.account_balance_wallet_rounded,
                size: 100, color: Colors.white.withValues(alpha: 0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Platform Revenue',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                'BDT ${_finance['platformRevenue']?.toString() ?? '0'}',
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100)),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: Color(0xFF00E676), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _finance['trend']?.toString() ?? '+0%',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
            child: _buildQuickStat(
                'Commission\nEarned',
                'BDT ${_finance['commissionEarned']?.toString() ?? '0'}',
                Icons.toll_rounded,
                const Color(0xFF4CAF50))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildQuickStat(
                'Pending\nPayouts',
                'BDT ${_finance['pendingPayouts']?.toString() ?? '0'}',
                Icons.pending_actions_rounded,
                const Color(0xFFFF9800))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildQuickStat(
                'Total\nJobs',
                _finance['totalJobs']?.toString() ?? '0',
                Icons.handyman_rounded,
                const Color(0xFF2196F3))),
      ],
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black87));
  }

  Widget _buildPendingPayoutCard(
      String business, String owner, String amount, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.storefront_rounded,
                color: Color(0xFFFF9800), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text('$owner • $subtitle',
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Colors.black54)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6950F4))),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('Release',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      String title, String amount, String date, bool isIncoming) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isIncoming
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncoming
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isIncoming
                    ? const Color(0xFF388E3C)
                    : const Color(0xFFD32F2F),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                  Text(date,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: Colors.black45)),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isIncoming
                    ? const Color(0xFF388E3C)
                    : const Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
