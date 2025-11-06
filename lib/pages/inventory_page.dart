// lib/pages/inventory_page.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../widgets/post_dialog.dart';
import 'dart:io';

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
  final DeviceService _deviceService = DeviceService();
  String _searchQuery = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  // Color palette matching analysis page
  final Color _seedGreen = const Color(0xFF4CAF50);
  final Color _seedGreenLight = const Color(0xFFE8F5E9);

  final List<String> _categories = [
    'All',
    'Batteries',
    'Components',
    'Devices',
    'Accessories',
    'Electronics',
    'Other',
  ];
  final List<String> _statuses = ['All', 'available', 'for pickup', 'donated'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeviceDetails(Device device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeviceDetailPage(
          device: device,
          onDeviceUpdated: widget.onDeviceUpdated,
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('phone')) return Icons.smartphone;
    if (c.contains('laptop')) return Icons.laptop;
    if (c.contains('batt')) return Icons.battery_charging_full;
    if (c.contains('tablet')) return Icons.tablet;
    if (c.contains('component')) return Icons.memory;
    if (c.contains('device')) return Icons.devices;
    if (c.contains('accessory')) return Icons.headset;
    return Icons.devices_other;
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = _categoryFilter == category;

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
          onSelected: (_) {
            setState(() {
              _categoryFilter = category;
            });
          },
          backgroundColor: Colors.white,
          selectedColor: _seedGreen,
          side: BorderSide(
            color: isSelected ? _seedGreen : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          showCheckmark: false,
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
          borderRadius: BorderRadius.circular(8.0),
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

  Widget _buildInventoryCard(Device device) {
    return GestureDetector(
      onTap: () => _showDeviceDetails(device),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _seedGreenLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _iconForCategory(device.category),
                      color: _seedGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.category,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              if (device.brand != null || device.model != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (device.brand != null) ...[
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        device.brand!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (device.model != null) ...[
                      Icon(Icons.label, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        device.model!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.scale,
                    '${device.estWeightKg} kg',
                    _seedGreen,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.inventory_2,
                    'x${device.quantity}',
                    Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(device.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'available':
        color = Colors.green;
        break;
      case 'for pickup':
        color = Colors.orange;
        break;
      case 'donated':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        elevation: 0.8,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.grey.shade50,
      body: StreamBuilder<List<Device>>(
        stream: _deviceService.getDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final firebaseDevices = snapshot.data ?? [];
          final allDevices = <Device>[...firebaseDevices, ...widget.devices];

          final uniqueDevices = <String, Device>{};
          for (var device in allDevices) {
            uniqueDevices[device.id] = device;
          }

          widget.devices.clear();
          widget.devices.addAll(uniqueDevices.values);

          final filteredDevices = widget.devices.where((device) {
            final matchesSearch =
                device.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                device.category.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (device.brand?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false) ||
                (device.model?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false);

            final matchesCategory =
                _categoryFilter == 'All' || device.category == _categoryFilter;
            final matchesStatus =
                _statusFilter == 'All' || device.status == _statusFilter;

            return matchesSearch && matchesCategory && matchesStatus;
          }).toList();

          return SafeArea(
            child: Column(
              children: [
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _categories
                                .map(_buildCategoryChip)
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                                'Scan devices to add them to inventory',
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
                            return _buildInventoryCard(device);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Device Detail Page - Matches Analysis Page Design EXACTLY
class DeviceDetailPage extends StatefulWidget {
  final Device device;
  final Function(Device) onDeviceUpdated;

  const DeviceDetailPage({
    super.key,
    required this.device,
    required this.onDeviceUpdated,
  });

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  final DeviceService _deviceService = DeviceService();

  void _showQRCodeDialog() {
    if (widget.device.qrCode == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Device QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: widget.device.qrCode!,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Code: ${widget.device.qrCode}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteDevice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Device'),
        content: const Text(
          'Are you sure you want to delete this device from your inventory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _deviceService.deleteDevice(widget.device.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _chipList(List<String>? items) {
    if (items == null || items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text('None', style: TextStyle(color: Colors.black87)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(t, style: const TextStyle(color: Colors.black87)),
            ),
          )
          .toList(),
    );
  }

  Widget _materialRow(String label, int percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth * (percent / 100),
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 240,
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Color _getColorForMaterial(String material) {
    final m = material.toLowerCase();
    if (m.contains('plastic')) return Colors.blue;
    if (m.contains('ferrous') || m.contains('metal')) return Colors.grey;
    if (m.contains('non-ferrous') ||
        m.contains('copper') ||
        m.contains('aluminum'))
      return Colors.amber;
    if (m.contains('pcb') || m.contains('board')) return Colors.green;
    if (m.contains('hazard') || m.contains('toxic')) return Colors.red;
    return Colors.blueGrey;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Device Details',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => PostDialog(
                    device: widget.device,
                    onPostSuccess: () {
                      // Show success message
                    },
                  ),
                ),
              );
            },
            icon: Icon(Icons.share, color: theme.colorScheme.primary),
            tooltip: 'Post to Community',
          ),
          IconButton(
            onPressed: _deleteDevice,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete device',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with QR code button and category chip overlay (matching analysis page)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: device.imageUrl != null
                        ? Image.network(
                            device.imageUrl!,
                            fit: BoxFit.cover,
                            height: 240,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          )
                        : device.imagePath != null
                        ? Image.file(
                            File(device.imagePath!),
                            fit: BoxFit.cover,
                            height: 240,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          )
                        : _buildImagePlaceholder(),
                  ),
                  // QR code button top-left
                  if (device.qrCode != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: _showQRCodeDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  // Category chip top-right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.category,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            device.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Title container (matching analysis page TextField style)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Title',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.name,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Description container (matching analysis page)
            if (device.description != null &&
                device.description!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Short description',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Info cards grid - EXACTLY matching analysis page layout
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.branding_watermark,
                    label: 'Brand',
                    value: device.brand?.isNotEmpty == true
                        ? device.brand!
                        : 'Unknown',
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoCard(
                    icon: Icons.developer_board,
                    label: 'Model',
                    value: device.model?.isNotEmpty == true
                        ? device.model!
                        : 'Unknown',
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.calendar_today,
                    label: 'Year',
                    value: device.year?.isNotEmpty == true ? device.year! : '—',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoCard(
                    icon: Icons.info_outline,
                    label: 'Condition',
                    value: device.status,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    icon: Icons.scale,
                    label: 'Weight (kg)',
                    value: device.estWeightKg.toStringAsFixed(2),
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoCard(
                    icon: Icons.category,
                    label: 'Category',
                    value: device.category,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Components section (matching analysis page)
            const Text(
              'Key components',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _chipList(device.components),
            const SizedBox(height: 12),

            // Hazards section (matching analysis page)
            const Text(
              'Hazards (inspect carefully)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _chipList(device.hazards),
            const SizedBox(height: 12),

            // Material streams section (matching analysis page)
            const Text(
              'Material streams (estimated)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (device.materialStreams == null ||
                device.materialStreams!.isEmpty)
              Column(
                children: [
                  const Text(
                    'No material breakdown provided.',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _materialRow('Plastics', 40, Colors.blue),
                  _materialRow('Ferrous', 30, Colors.grey),
                  _materialRow('Non-ferrous', 20, Colors.amber),
                  _materialRow('PCB', 5, Colors.green),
                  _materialRow('Hazardous', 5, Colors.red),
                ],
              )
            else
              Column(
                children: device.materialStreams!.entries
                    .map(
                      (e) => _materialRow(
                        e.key[0].toUpperCase() + e.key.substring(1),
                        e.value,
                        _getColorForMaterial(e.key),
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 12),

            // Disposal path section (matching analysis page)
            const Text(
              'Recommended disposal / recycling path',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                device.disposalPath?.isNotEmpty == true
                    ? device.disposalPath!
                    : 'No specific path provided. Consider certified e-waste recycler or battery-specialist.',
                style: const TextStyle(color: Colors.black87),
              ),
            ),

            // Scanned date
            if (device.scannedAt != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scanned: ${_formatDate(device.scannedAt!)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Mark for pickup button (matching analysis page button style)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updatedDevice = Device(
                    id: device.id,
                    name: device.name,
                    category: device.category,
                    status: 'for pickup',
                    quantity: device.quantity,
                    estWeightKg: device.estWeightKg,
                    description: device.description,
                    imagePath: device.imagePath,
                    imageUrl: device.imageUrl,
                    brand: device.brand,
                    model: device.model,
                    year: device.year,
                    color: device.color,
                    components: device.components,
                    hazards: device.hazards,
                    materialStreams: device.materialStreams,
                    disposalPath: device.disposalPath,
                    metrics: device.metrics,
                    scannedAt: device.scannedAt,
                    qrCode: device.qrCode,
                  );

                  await _deviceService.updateDevice(updatedDevice);
                  widget.onDeviceUpdated(updatedDevice);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Marked for pickup'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.local_shipping),
                label: const Text('Mark for Pickup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
