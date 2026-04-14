import 'package:flutter/material.dart';
import 'package:ripo/data/api_exception.dart';
import 'package:ripo/data/repositories/booking_repository.dart';
import 'package:ripo/customers_screens/customer_dashboard_screen.dart';

class BookingScheduleScreen extends StatefulWidget {
  final Map<String, dynamic>? serviceData;

  const BookingScheduleScreen({super.key, this.serviceData});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  final _bookingRepository = BookingRepository();

  int _selectedDateIndex = 0;
  int? _selectedTimeIndex; // Nullable to handle no available slots
  bool _isLoadingSlots = true;
  bool _isSubmitting = false;
  String? _slotError;

  late final List<Map<String, String>> _dates;

  List<Map<String, dynamic>> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _dates = _generateDates();
    _loadAvailabilityForSelectedDate();
  }

  int? get _serviceId {
    final raw = widget.serviceData?['id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  Future<void> _loadAvailabilityForSelectedDate() async {
    final serviceId = _serviceId;
    if (serviceId == null) {
      setState(() {
        _slotError = 'Service id is missing for booking.';
        _isLoadingSlots = false;
      });
      return;
    }

    final date = _dates[_selectedDateIndex]['fullDate']!;
    setState(() {
      _isLoadingSlots = true;
      _slotError = null;
    });

    try {
      final slots = await _bookingRepository.fetchAvailability(
        serviceId: serviceId,
        date: date,
      );

      if (!mounted) return;
      setState(() {
        _timeSlots = slots;
        final firstOpenIndex =
            _timeSlots.indexWhere((slot) => slot['isBooked'] != true);
        _selectedTimeIndex = firstOpenIndex >= 0
            ? firstOpenIndex
            : (_timeSlots.isNotEmpty ? 0 : null);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _slotError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _slotError = 'Failed to load available slots.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  List<Map<String, String>> _generateDates() {
    final List<String> weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];
    List<Map<String, String>> datesList = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 5; i++) {
      DateTime genDate = now.add(Duration(days: i));
      String dayName = i == 0 ? 'Today' : weekdays[genDate.weekday - 1];
      datesList.add({
        'day': dayName,
        'date': genDate.day.toString(),
        'fullDate':
            '${genDate.year}-${genDate.month.toString().padLeft(2, '0')}-${genDate.day.toString().padLeft(2, '0')}'
      });
    }
    return datesList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule Order',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              _buildNoticeBanner(),
              const SizedBox(height: 14),
              _buildDateSelector(),
              const SizedBox(height: 14),
              _buildTimeSelector(),
              const SizedBox(height: 24),
              _buildConfirmButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFFFF9800).withValues(alpha: 0.5),
            width: 1.2,
            strokeAlign: BorderSide.strokeAlignOutside),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.thumb_up_alt_outlined,
              color: Color(0xFFEF9A9A),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Select a Schedule Slot',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Please select between our available time slots below for delivery of your order',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Select Date',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.calendar_month_outlined,
                  color: Color(0xFFEF9A9A), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: List.generate(_dates.length, (index) {
                final isSelected = _selectedDateIndex == index;
                final date = _dates[index];
                return GestureDetector(
                  onTap: () async {
                    setState(() => _selectedDateIndex = index);
                    await _loadAvailabilityForSelectedDate();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 44,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFE2DCFE) : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6950F4)
                            : const Color(0xFFE0E0E0),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date['day']!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF6950F4)
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date['date']!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF6950F4)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'At What time should the service arrive?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingSlots)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_slotError != null)
            Column(
              children: [
                Text(
                  _slotError!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadAvailabilityForSelectedDate,
                  child: const Text('Retry'),
                ),
              ],
            )
          else if (_timeSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'No time slots available for this date.',
                style: TextStyle(fontFamily: 'Inter', color: Colors.black45),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 4.0,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final isBooked = slot['isBooked'] == true;
                final isSelected = _selectedTimeIndex == index;

                return GestureDetector(
                  onTap: isBooked
                      ? null
                      : () => setState(() => _selectedTimeIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked
                          ? const Color(0xFFE4FAF3)
                          : isSelected
                              ? const Color(0xFFE2DCFE)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isBooked
                            ? const Color(0xFFB9EFE0)
                            : isSelected
                                ? const Color(0xFFB5A4F9)
                                : const Color(0xFFE0E0E0),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (slot['time'] as String?) ?? '',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF6950F4)
                                : Colors.black87,
                          ),
                        ),
                        if (isBooked) ...[
                          const SizedBox(height: 1),
                          const Text(
                            'Booked',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7D9E94),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showConfirmationDialog() {
    // Defensive check: ensure time slot is selected and valid
    if (_timeSlots.isEmpty ||
        _selectedTimeIndex == null ||
        _selectedTimeIndex! >= _timeSlots.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available time slot.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    final name = widget.serviceData?['name'] ?? 'AC Cooling Problem';
    final category = widget.serviceData?['category'] ?? 'AC Repair';
    final price = widget.serviceData?['price']?.toString() ?? '500';

    final selectedDateString = _dates[_selectedDateIndex]['fullDate'];
    final selectedTimeString = _timeSlots[_selectedTimeIndex!]['time'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirm Booking',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('Service:', name),
            const SizedBox(height: 8),
            _buildDialogRow('Details:', category),
            const SizedBox(height: 8),
            _buildDialogRow('Provider:', 'Shaidul Islam'),
            const SizedBox(height: 8),
            _buildDialogRow('Date:', selectedDateString ?? ''),
            const SizedBox(height: 8),
            _buildDialogRow('Time:', selectedTimeString ?? ''),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Cost:',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w700),
                ),
                Text(
                  '৳ $price',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6950F4),
                  ),
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _processBooking(); // Continue to success and dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6950F4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Book',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _processBooking() {
    _createBooking();
  }

  Future<void> _createBooking() async {
    final serviceId = _serviceId;
    if (serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create booking: service id missing.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (_timeSlots.isEmpty ||
        _selectedTimeIndex == null ||
        _selectedTimeIndex! >= _timeSlots.length) {
      return;
    }

    final selectedDate = _dates[_selectedDateIndex]['fullDate']!;
    final selectedTime =
        (_timeSlots[_selectedTimeIndex!]['time'] as String?) ?? '';

    setState(() => _isSubmitting = true);
    try {
      final result = await _bookingRepository.createBooking(
        serviceId: serviceId,
        date: selectedDate,
        timeSlot: selectedTime,
        address: 'house 57,Road 25, Block A, Banani',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Booking #${result['bookingId']} confirmed successfully.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerDashboardScreen()),
          (route) => false,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking failed. Please try again.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildDialogRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Colors.black54,
              fontWeight: FontWeight.w500,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _showConfirmationDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Confirm Booking',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }
}
