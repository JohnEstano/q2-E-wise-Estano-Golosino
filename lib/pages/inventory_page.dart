// lib/pages/inventory_page.dart
import 'package:flutter/material.dart';
import '../models/device.dart';

class InventoryPage extends StatefulWidget {
  final List<Device> devices;
  final Function(Device) onDeviceUpdated;

  const InventoryPage({
    super.key,
    required this.devices,
    required this.onDeviceUpdated,
  });

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  // Updated color palette
  final Color _seedGreen = const Color(0xFF4CAF50); // More vibrant green
  final Color _seedGreenLight = const Color(0xFFE8F5E9); // Very light green
  final Color _seedGreenDark = const Color(
    0xFF2E7D32,
  ); // Darker green for contrast

  final List<String> _categories = [
    'All',
    'Phone',
    'Laptop',
    'Battery',
    'Electronics',
    'Tablet',
    'Component',
  ];
  final List<String> _statuses = ['All', 'available', 'for pickup', 'donated'];

  List<Device> get _filteredDevices {
    return widget.devices.where((device) {
      final matchesSearch =
          device.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          device.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _categoryFilter == 'All' || device.category == _categoryFilter;
      final matchesStatus =
          _statusFilter == 'All' || device.status == _statusFilter;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeviceDetails(Device device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => _buildDeviceDetailSheet(device),
    );
  }

  Widget _buildDeviceDetailSheet(Device device) {
    // The modal bottom sheet runs inside a Material context, so Material widgets are safe here.
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Device image placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                _iconForCategory(device.category),
                size: 48,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              device.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              device.category,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            _buildDetailRow('Status', device.status),
            _buildDetailRow('Quantity', '${device.quantity}'),
            _buildDetailRow('Weight', '${device.estWeightKg} kg'),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _seedGreen,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final updatedDevice = Device(
                        id: device.id,
                        name: device.name,
                        category: device.category,
                        status: 'for pickup',
                        quantity: device.quantity,
                        estWeightKg: device.estWeightKg,
                      );
                      widget.onDeviceUpdated(updatedDevice);
                      Navigator.of(context).pop();
                      // use the ScaffoldMessenger of the root context (the page) to show the snack
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked for pickup')),
                      );
                    },
                    child: const Text('Mark for Pickup'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: _seedGreen, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('phone')) return Icons.smartphone;
    if (c.contains('laptop')) return Icons.laptop;
    if (c.contains('battery')) return Icons.battery_charging_full;
    if (c.contains('tablet')) return Icons.tablet;
    if (c.contains('component')) return Icons.memory;
    return Icons.devices_other;
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = _categoryFilter == category;

    // Wrap the ChoiceChip with a Theme to disable splash/highlight on tap
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ChoiceChip(
          label: Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          selected: isSelected,
          // Always set the category when tapped — do not toggle off to 'All' automatically.
          onSelected: (_) {
            setState(() {
              _categoryFilter = category;
            });
          },
          backgroundColor: Colors.white,
          selectedColor: _seedGreen, // Filled green when selected
          side: BorderSide(
            color: isSelected ? _seedGreen : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              8.0,
            ), // Slightly rounded corners
          ),
          showCheckmark:
              false, // Hide the default check icon to avoid duplication
          // Remove press elevation and overlay so there's no dark ripple/streak left behind.
          pressElevation: 0,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildStatusFilterButton() {
    return PopupMenuButton<String>(
      color: Colors.white,
      onSelected: (String newValue) {
        setState(() {
          _statusFilter = newValue;
        });
      },
      itemBuilder: (BuildContext context) {
        return _statuses.map((String status) {
          final isSelected = status == _statusFilter;
          return PopupMenuItem<String>(
            value: status,
            child: Row(
              children: [
                if (isSelected) Icon(Icons.check, color: _seedGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? _seedGreen : Colors.grey.shade800,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            8.0,
          ), // Squared with slight rounding
          border: Border.all(
            color: _statusFilter == 'All' ? Colors.grey.shade300 : _seedGreen,
          ),
        ),
        child: Icon(
          Icons.filter_list,
          color: _statusFilter == 'All' ? Colors.grey.shade600 : _seedGreen,
          size: 20,
        ),
      ),
      tooltip: 'Filter by status',
    );
  }

  Widget _buildInventoryItem(Device device) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: _seedGreenLight, // Lighter green background
            child: Icon(_iconForCategory(device.category), color: _seedGreen),
          ),
          title: Text(
            device.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            '${device.category} • ${device.status} • x${device.quantity}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          trailing: Text(
            '${device.estWeightKg} kg',
            style: TextStyle(fontWeight: FontWeight.w500, color: _seedGreen),
          ),
          onTap: () => _showDeviceDetails(device),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = _filteredDevices;

    // Provide a full page scaffold so Material widgets have a proper ancestor.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        elevation: 0.8,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            tooltip: 'Add device (demo)',
            onPressed: () {
              // Example: quick add a demo device to show behavior — remove if not desired.
              final demo = Device(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: 'New Device',
                category: 'Electronics',
                status: 'available',
                quantity: 1,
                estWeightKg: 0.5,
              );
              setState(() {
                widget.devices.insert(0, demo);
              });
            },
            icon: Icon(Icons.add, color: _seedGreenDark),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search devices...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Filter row with category chips and status button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _categories.map(_buildCategoryChip).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusFilterButton(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Device list
            Expanded(
              child: filteredDevices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No devices found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      itemCount: filteredDevices.length,
                      itemBuilder: (context, index) {
                        final device = filteredDevices[index];
                        return _buildInventoryItem(device);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
