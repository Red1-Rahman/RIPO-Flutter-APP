import 'package:flutter/material.dart';
import 'package:ripo/data/repositories/booking_repository.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  const BookingDetailsScreen({super.key, this.bookingData});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingRepository _bookingRepository = BookingRepository();

  Future<Map<String, dynamic>> _loadBookingData() async {
    final bookingId = widget.bookingData?['id']?.toString();
    if (bookingId == null || bookingId.isEmpty) {
      return Map<String, dynamic>.from(widget.bookingData ?? {});
    }

    try {
      return await _bookingRepository.fetchBookingDetails(bookingId);
    } catch (_) {
      return Map<String, dynamic>.from(widget.bookingData ?? {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadBookingData(),
      builder: (context, snapshot) {
        final data = snapshot.data ??
            Map<String, dynamic>.from(widget.bookingData ?? {});
        final status = (data['status'] ?? 'Pending').toString();

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            shadowColor: Colors.black12,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Booking Details',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            actions: [
              Center(child: _statusPill(status)),
              const SizedBox(width: 12),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting &&
                  data.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildBookingInfoCard(data),
                      const SizedBox(height: 16),
                      _buildProviderCard(data),
                      const SizedBox(height: 16),
                      _buildPaymentCard(data),
                      const SizedBox(height: 16),
                      _buildSummaryCard(data),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _statusPill(String status) {
    Color bgColor = const Color(0xFFFDF0D5);
    Color textColor = const Color(0xFFF39C12);

    final lower = status.toLowerCase();
    if (lower.contains('complete')) {
      bgColor = const Color(0xFFD5F5E3);
      textColor = const Color(0xFF2E7D32);
    } else if (lower.contains('reject')) {
      bgColor = const Color(0xFFFADBD8);
      textColor = const Color(0xFFD32F2F);
    } else if (lower.contains('progress')) {
      bgColor = const Color(0xFFE2E4FF);
      textColor = const Color(0xFF5D5FEF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBookingInfoCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Booking Id: ',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: data['id']?.toString() ?? 'N/A',
                  style: const TextStyle(color: Color(0xFF6950F4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['dateTime']?.toString() ??
                data['date']?.toString() ??
                'Not scheduled',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 14),
          _buildSummaryRow('Address:', data['address']?.toString() ?? 'N/A'),
          const SizedBox(height: 6),
          _buildSummaryRow('Status:', data['status']?.toString() ?? 'Pending'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.black38,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> data) {
    final providerRaw = data['provider'];
    final provider = providerRaw is Map
        ? Map<String, dynamic>.from(providerRaw)
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: Colors.grey.shade200, shape: BoxShape.circle),
            child: const Icon(Icons.person, size: 30, color: Colors.black54),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider['name']?.toString() ?? 'Service Provider',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> data) {
    final paymentRaw = data['payment'];
    final payment = paymentRaw is Map
        ? Map<String, dynamic>.from(paymentRaw)
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Payment by: ${payment['method']?.toString() ?? 'Pay Offline'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Amount: BDT ${payment['amount']?.toString() ?? data['price']?.toString() ?? '0'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final serviceRaw = data['service'];
    final service = serviceRaw is Map
        ? Map<String, dynamic>.from(serviceRaw)
        : <String, dynamic>{};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Summary',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            service['name']?.toString() ?? 'Service',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Category: ${service['category']?.toString() ?? 'General'}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
