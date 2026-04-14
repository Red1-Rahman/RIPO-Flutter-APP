import 'package:flutter/material.dart';
import 'package:ripo/data/api_exception.dart';
import 'package:ripo/data/repositories/customer_repository.dart';
import 'package:ripo/customers_screens/service_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _customerRepository = CustomerRepository();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy =
      'Recommended'; // Options: Recommended, Price (Low to High), Price (High to Low), Rating (High to Low)
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _searchQuery = widget.initialQuery;
      _searchController.text = widget.initialQuery;
    }
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _allServices = [];

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final services = await _customerRepository.fetchAllServices();
      if (!mounted) return;

      setState(() {
        _allServices = services
            .map(
              (s) => {
                'id': s['id']?.toString(),
                'name': s['name'] ?? 'Service',
                'discount': s['discount'] ?? '',
                'price': s['price'] ?? 0,
                'originalPrice': s['originalPrice'] ?? 0,
                'rating': (s['rating'] as num?)?.toDouble() ?? 0.0,
                'image': s['image'] ?? 'lib/media/AC_servicing.png',
                'category': s['category'] ?? 'General',
                'isFavorite': (s['isFavorite'] as bool?) ?? false,
              },
            )
            .toList();
      });
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

  List<Map<String, dynamic>> get _filteredAndSortedServices {
    // Filter
    List<Map<String, dynamic>> result = _allServices.where((s) {
      if (_searchQuery.trim().isEmpty) return true;

      final serviceName = (s['name'] as String).toLowerCase();
      final queryLower = _searchQuery.toLowerCase().trim();

      // Exact match check first
      if (serviceName.contains(queryLower)) return true;

      // Fuzzy "Like" word match
      final searchWords = queryLower.split(' ');
      for (var word in searchWords) {
        // Match if any meaningful word exists
        // e.g. clicking "AC Repair" will correctly find "AC Servicing" because "ac" matches
        if (word.length > 1 && serviceName.contains(word)) {
          return true;
        }
      }
      return false;
    }).toList();

    // Sort
    if (_sortBy == 'Price (Low to High)') {
      result.sort(
        (a, b) => (a['price'] as num).compareTo(b['price'] as num),
      );
    } else if (_sortBy == 'Price (High to Low)') {
      result.sort(
        (a, b) => (b['price'] as num).compareTo(a['price'] as num),
      );
    } else if (_sortBy == 'Rating (High to Low)') {
      result.sort(
        (a, b) => (b['rating'] as num).compareTo(a['rating'] as num),
      );
    }

    return result;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Divider(),
              _buildSortOption('Recommended'),
              _buildSortOption('Price (Low to High)'),
              _buildSortOption('Price (High to Low)'),
              _buildSortOption('Rating (High to Low)'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String value) {
    bool isSelected = _sortBy == value;
    return ListTile(
      title: Text(
        value,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? const Color(0xFF6950F4) : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF6950F4))
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: const Color(0x0A000000)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: Colors.black87, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                autofocus: true,
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 13, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  isDense: true,
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.black45,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(width: 1, height: 20, color: Colors.black12),
            GestureDetector(
              onTap: _showFilterOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFD6D0FA),
                  borderRadius:
                      BorderRadius.horizontal(right: Radius.circular(21)),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: const [
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.filter_list_rounded,
                        size: 14, color: Colors.black87),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontFamily: 'Inter', color: Colors.black54),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _loadServices, child: const Text('Retry')),
          ],
        ),
      );
    }

    final results = _filteredAndSortedServices;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'No services found.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(results[index]);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> s) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(serviceData: s),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x0F000000)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + Badge
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: const Color(0xFFF5F5F5),
                    child: Image.asset(
                      (s['image'] as String?) ?? 'lib/media/AC_servicing.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xE6FFFFFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (s['discount'] as String?) ?? '',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (s['name'] as String?) ?? 'Service',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '৳ ${s['price']}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                ((s['rating'] as num?) ?? 0).toString(),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            s['isFavorite'] = !s['isFavorite'];
                          });
                        },
                        child: Icon(
                          s['isFavorite']
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: const Color(0xFF4285F4),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
