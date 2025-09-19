// lib/pages/pickup_page.dart
import 'package:flutter/material.dart';
import '../models/device.dart';
import 'dart:math';
import '../widgets/navigation.dart' as nav;
import '../pages/camera_page.dart';
import '../pages/home_page.dart';

class ScheduledPickup {
  final String id;
  final String contactName;
  final String phone;
  final String address;
  final DateTime scheduledAt;
  final List<PickupItem> items;
  final String method;
  final String notes;
  String status;

  ScheduledPickup({
    required this.id,
    required this.contactName,
    required this.phone,
    required this.address,
    required this.scheduledAt,
    required this.items,
    required this.method,
    required this.notes,
    this.status = 'Scheduled',
  });

  double get totalWeightKg => items.fold(0.0, (p, i) => p + (i.weightKg * i.quantity));
}

class PickupItem {
  final String id;
  final String name;
  final double weightKg;
  int quantity;

  PickupItem({required this.id, required this.name, required this.weightKg, this.quantity = 1});
}

class PickupPage extends StatefulWidget {
  final List<Device> devices;
  final List<Post> posts;
  final Function(Device)? onDeviceUpdated;

  const PickupPage({
    super.key,
    this.devices = const [],
    this.posts = const [],
    this.onDeviceUpdated,
  });

  @override
  State<PickupPage> createState() => _PickupPageState();
}

class _PickupPageState extends State<PickupPage> {
  final _formKey = GlobalKey<FormState>();
  final _contactCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _addressCtl = TextEditingController();
  final _notesCtl = TextEditingController();

  DateTime? _pickedDateTime;
  String _method = 'Doorstep collection';
  Map<String, int> _selectedQty = {};
  List<ScheduledPickup> _scheduled = [];
  bool _submitting = false;

  final List<String> _weekdays = ['Mon', 'Tues', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  int _selectedDayIndex = DateTime.now().weekday % 7;

  // Updated: sample events reflect waste collector pickup times
  final List<Map<String, String>> _sampleEvents = [
    {'title': 'Waste pickup at your location', 'time': '6:00 AM - 7:30 AM'},
    {'title': 'Community Drop-off Window', 'time': '3:00 PM - 5:00 PM'},
  ];

  List<Device> get _devices =>
      widget.devices.isNotEmpty
          ? widget.devices
          : [Device(id: 'dummy1', name: 'Old Laptop', category: 'Electronics', estWeightKg: 2.5)];

  @override
  void initState() {
    super.initState();
    for (var d in _devices) {
      _selectedQty[d.id] = 0;
    }
  }

  @override
  void dispose() {
    _contactCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _notesCtl.dispose();
    super.dispose();
  }

  double _computeTotalWeight() {
    double total = 0.0;
    for (var d in _devices) {
      final q = _selectedQty[d.id] ?? 0;
      if (q > 0) total += d.estWeightKg * q;
    }
    return total;
  }

  List<PickupItem> _buildSelectedItems() {
    final items = <PickupItem>[];
    for (var d in _devices) {
      final q = _selectedQty[d.id] ?? 0;
      if (q > 0) {
        items.add(PickupItem(id: d.id, name: d.name, weightKg: d.estWeightKg, quantity: q));
      }
    }
    return items;
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (time == null) return;
    setState(() {
      _pickedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _incQty(String id) => setState(() => _selectedQty[id] = (_selectedQty[id] ?? 0) + 1);
  void _decQty(String id) => setState(() => _selectedQty[id] = max(0, (_selectedQty[id] ?? 0) - 1));

  Future<void> _submit() async {
    final items = _buildSelectedItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one item for pickup')));
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_pickedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a pickup date & time')));
      return;
    }

    setState(() => _submitting = true);

    // Simulate a scheduling API call / processing
    await Future.delayed(const Duration(milliseconds: 700));

    final pickup = ScheduledPickup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contactName: _contactCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      address: _addressCtl.text.trim(),
      scheduledAt: _pickedDateTime!,
      items: items,
      method: _method,
      notes: _notesCtl.text.trim(),
    );

    setState(() {
      _scheduled.insert(0, pickup);
      // reset quantities
      for (var k in _selectedQty.keys) {
        _selectedQty[k] = 0;
      }
      _pickedDateTime = null;
      _notesCtl.clear();
      _submitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup scheduled')));
    Navigator.of(context).pop(); // Close bottom sheet
  }

  void _cancelPickup(ScheduledPickup p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel pickup?'),
        content: Text('Cancel pickup scheduled for ${p.scheduledAt.toLocal()}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Yes')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      p.status = 'Canceled';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pickup canceled')));
    }
  }

  void _openScan() async {
    await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (c) => const CameraPage()),
    );
  }

  void _openScheduleSheet() {
    final cs = Theme.of(context).colorScheme;
    final textPrimary = Colors.black87;
    final textMuted = Colors.black54;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Schedule a Pickup', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: textPrimary)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactCtl,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      labelText: 'Full name',
                      hintText: 'Juan Dela Cruz',
                      labelStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter contact name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      labelText: 'Phone number',
                      hintText: '09xx...',
                      labelStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtl,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      labelText: 'Pickup address',
                      hintText: 'Street, City, Barangay',
                      labelStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Select items for pickup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textPrimary)),
                  const SizedBox(height: 12),
                  ..._devices.map((d) {
                    final qty = _selectedQty[d.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.name, style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${d.category} • ${d.estWeightKg.toStringAsFixed(2)} kg each',
                                      style: TextStyle(color: textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _decQty(d.id),
                                    icon: Icon(Icons.remove_circle_outline, color: textPrimary),
                                  ),
                                  Text('$qty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary)),
                                  IconButton(
                                    onPressed: () => _incQty(d.id),
                                    icon: Icon(Icons.add_circle_outline, color: textPrimary),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Date/time picker button (left)
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: Colors.grey.shade300),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _pickDateTime,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _pickedDateTime == null
                                  ? 'Pick date & time'
                                  : 'Pickup: ${_pickedDateTime!.toLocal().toString().substring(0, 16)}',
                              style: TextStyle(color: textPrimary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Method dropdown (right) - fixed height and light themed to prevent overflow / dark theme
                      Expanded(
                        child: SizedBox(
                          height: 52, // match the left button height to avoid tiny overflow pixels
                          child: DropdownButtonFormField<String>(
                            value: _method,
                            isExpanded: true,
                            isDense: true,
                            dropdownColor: Colors.white, // ensure the opened menu is light
                            elevation: 2,
                            style: TextStyle(color: textPrimary),
                            items: const [
                              DropdownMenuItem(value: 'Doorstep collection', child: Text('Doorstep collection')),
                              DropdownMenuItem(value: 'Drop-off at center', child: Text('Drop-off at center')),
                              DropdownMenuItem(value: 'Community bin', child: Text('Community bin')),
                            ],
                            onChanged: (v) => setState(() => _method = v ?? 'Doorstep collection'),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              labelStyle: TextStyle(color: textMuted),
                              filled: true,
                              fillColor: Colors.white, // light theme background
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtl,
                    style: TextStyle(color: textPrimary),
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      labelText: 'Notes (optional)',
                      labelStyle: TextStyle(color: textMuted),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Schedule pickup'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            for (var k in _selectedQty.keys) _selectedQty[k] = 0;
                            _pickedDateTime = null;
                            _notesCtl.clear();
                          });
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textPrimary = Colors.black87;
    final textMuted = Colors.black54;
    final todayIndex = DateTime.now().weekday % 7;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 22),
        title: const Text('Schedule Pickup', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: textPrimary,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScan,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // UPDATED: Calendar / schedule card styled to be white with waste collector info
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Waste Collector Pickup Time",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // weekday pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_weekdays.length, (i) {
                        final isSelected = i == _selectedDayIndex;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDayIndex = i;
                                // You may hook this to change _sampleEvents per day
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(18),
                                border: isSelected ? Border.all(color: Colors.green.shade300) : Border.all(color: Colors.transparent),
                              ),
                              child: Text(
                                _weekdays[i],
                                style: TextStyle(
                                  color: isSelected ? Colors.green.shade700 : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Events (waste collector pickup times)
                  Column(
                    children: _sampleEvents.map((e) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e['title'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
                            const SizedBox(height: 6),
                            Text(e['time'] ?? '', style: TextStyle(color: textMuted, fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          // Schedule Pickup button
          FilledButton.icon(
            onPressed: _openScheduleSheet,
            icon: const Icon(Icons.add, size: 22),
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            label: const Text('Schedule a Pickup', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 18),
          // Scheduled pickups section
          if (_scheduled.isNotEmpty) ...[
            Text(
              'Your scheduled pickups',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textPrimary),
            ),
            const SizedBox(height: 8),
            ..._scheduled.map((p) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.contactName, style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text(
                                '${p.items.length} item(s) • ${p.totalWeightKg.toStringAsFixed(2)} kg',
                                style: TextStyle(color: textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: p.status == 'Scheduled' ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              p.status,
                              style: TextStyle(
                                color: p.status == 'Scheduled' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('When: ${p.scheduledAt.toLocal().toString().substring(0, 16)}', style: TextStyle(color: textMuted)),
                      const SizedBox(height: 6),
                      Text('Method: ${p.method}', style: TextStyle(color: textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: p.items.map((it) => Chip(label: Text('${it.name} x${it.quantity}'))).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _cancelPickup(p),
                            icon: Icon(Icons.cancel_outlined, color: textPrimary),
                            label: Text('Cancel', style: TextStyle(color: textPrimary)),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Pickup details'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Contact: ${p.contactName}'),
                                        Text('Phone: ${p.phone}'),
                                        const SizedBox(height: 8),
                                        Text('Address: ${p.address}'),
                                        const SizedBox(height: 8),
                                        Text('When: ${p.scheduledAt.toLocal().toString().substring(0, 16)}'),
                                        const SizedBox(height: 8),
                                        Text('Notes: ${p.notes.isEmpty ? '—' : p.notes}'),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(c).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(Icons.info_outline, color: textPrimary),
                            label: Text('Details', style: TextStyle(color: textPrimary)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ],
      ),
      bottomNavigationBar: nav.EwasteNavigationBar(
        selectedIndex: 3,
      ),
    );
  }
}
