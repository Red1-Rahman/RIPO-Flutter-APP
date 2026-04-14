import 'package:flutter/material.dart';
import 'package:ripo/data/api_exception.dart';
import 'package:ripo/data/repositories/provider_repository.dart';
import 'package:ripo/customers_screens/service_details_screen.dart';
import 'package:ripo/providers_screens/add_service_screen.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  final _providerRepository = ProviderRepository();
  List<Map<String, dynamic>> _myServices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final services = await _providerRepository.fetchServices();
      if (!mounted) return;
      setState(() => _myServices = services);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load services.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleServiceStatus(Map<String, dynamic> service) async {
    final id = service['id']?.toString();
    if (id == null || id.isEmpty) return;

    final current = service['isActive'] == true;
    try {
      await _providerRepository.updateServiceStatus(
          serviceId: id, isActive: !current);
      if (!mounted) return;
      setState(() => service['isActive'] = !current);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F8),
      appBar: AppBar(
        // Optional sticky header style for tab
        backgroundColor: const Color(0xFF6950F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Portfolio',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: _isLoading
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
                          onPressed: _loadServices, child: const Text('Retry')),
                    ],
                  ),
                )
              : _myServices.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                          top: 16, bottom: 100, left: 16, right: 16),
                      itemCount: _myServices.length,
                      itemBuilder: (context, index) {
                        return _buildServiceCard(_myServices[index]);
                      },
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.design_services_outlined, size: 80, color: Colors.black12),
          const SizedBox(height: 16),
          const Text('No Services Found',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          const Text('Tap the + button below to add your first service.',
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 14, color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isActive = service['isActive'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(
              serviceData: service,
              isProviderPreview: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // Header / Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF5F5F5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      service['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Colors.black26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                service['name'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFECEFF1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'PAUSED',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isActive
                                      ? const Color(0xFF388E3C)
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service['category'],
                          style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '৳${service['price']?.toString() ?? '0'}',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6950F4)),
                            ),
                            const Spacer(),
                            Icon(Icons.star_rounded,
                                color: Colors.amber[600], size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${service['rating']?.toString() ?? '0'} (${service['reviews']?.toString() ?? '0'})',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons Divider
            const Divider(height: 1, color: Colors.black12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _toggleServiceStatus(service),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              isActive
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.play_circle_outline_rounded,
                              size: 18,
                              color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'Pause' : 'Activate',
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: Colors.black12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddServiceScreen(serviceData: service),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.edit_outlined,
                              size: 18, color: Colors.black54),
                          SizedBox(width: 6),
                          Text('Edit',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 20, color: Colors.black12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Delete Logic
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: Color(0xFFD32F2F)),
                          SizedBox(width: 6),
                          Text('Delete',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD32F2F))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ), // closes Column
      ), // closes child: Container
    ); // closes return GestureDetector
  }
}
