// lib/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'home_page.dart';
import 'inventory_page.dart';
import 'map_page.dart';
import 'pickup_page.dart';
import 'camera_page.dart';
import 'leaderboards_page.dart';
import '../widgets/navigation.dart' as nav;

class ProfilePage extends StatefulWidget {
  final List<Device> devices;
  final void Function(Device) onDeviceUpdated;
  final List<Post> posts;
  final UserModel? user;

  const ProfilePage({
    super.key,
    required this.devices,
    required this.onDeviceUpdated,
    this.posts = const [],
    this.user,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Helper to safely read estWeightKg and quantity (handles nullable fields in Device)
  double _deviceWeight(Device d) {
    final double est = (d.estWeightKg ?? 0.0);
    final qtyRaw = d.quantity ?? 0;
    final double qty = qtyRaw.toDouble();
    return est * qty;
  }

  double get _totalWeightKg =>
      widget.devices.fold<double>(0.0, (prev, d) => prev + _deviceWeight(d));

  double get _estimatedCo2Kg => _totalWeightKg * 2.5;

  // NOTE: Achievements removed per request
  final int _pickupRequests = 0;

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'for pickup':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _openScan() async {
    await Navigator.of(
      context,
    ).push<String?>(MaterialPageRoute(builder: (c) => const CameraPage()));
    // You can add post-scan logic here if needed.
  }

  /// Simple Ecoscore heuristic
  /// - Produces a percentage 0..100 based on inventory weight and number of devices.
  double _calculateEcoscore() {
    final double fromWeight = _totalWeightKg * 4.0;
    final double fromDevices = widget.devices.length * 8.0;
    final double raw = fromWeight + fromDevices;
    return raw.clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const double outerPadding = 16.0;
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await FirebaseService().signOut();
                  if (mounted) {
                    // Navigate back to intro screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      bottomNavigationBar: nav.EwasteNavigationBar(
        selectedIndex: 4,
        user: widget.user,
        devices: widget.devices,
        onDeviceUpdated: widget.onDeviceUpdated,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(cs),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                outerPadding,
                18,
                outerPadding,
                outerPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildOverviewSingleCardList(
                    cs,
                    context,
                  ), // stacked rows + inventory
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Posts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPostsArea(context),
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

  Widget _buildProfileHeader(ColorScheme cs) {
    // Use authenticated user data
    final displayName = widget.user?.displayName ?? 'User';
    final email = widget.user?.email ?? '';
    final photoURL = widget.user?.photoURL;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          photoURL != null
              ? CircleAvatar(
                  radius: 34,
                  backgroundImage: NetworkImage(photoURL),
                  backgroundColor: cs.primary,
                )
              : CircleAvatar(
                  radius: 34,
                  backgroundColor: cs.primary,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        email.isNotEmpty ? email : 'No email',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Member',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Overview card with links, icons, and correct subvalues
  Widget _buildOverviewSingleCardList(ColorScheme cs, BuildContext context) {
    // Dummy scores as requested
    const int ecoscoreInt = 50;
    const int ecoscoreRank = 16;
    const int totalScans = 2;
    const int pickups = 5;
    const int ecoscoreGrowth = 12; // percent growth

    const Color iconEcoscore = Colors.green; // keep green for ecoscore
    const Color iconScans = Colors.blue; // blue for scans
    const Color iconPickup = Colors.redAccent; // red for pickups
    const Color iconInventory = Colors.deepPurple; // purple for inventory

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (c) => const LeaderboardsPage()),
              );
            },
            child: _overviewRow(
              icon: Icons.eco,
              iconColor: iconEcoscore,
              title: 'Eco Score',
              valueWidget: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$ecoscoreRank',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$ecoscoreInt%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              subvalueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.green, size: 14),
                  Text(
                    '+$ecoscoreGrowth%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 26,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (c) => const CameraPage()));
            },
            child: _overviewRow(
              icon: Icons.document_scanner,
              iconColor: iconScans,
              title: 'Total Scans',
              valueWidget: Text(
                '$totalScans',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              subvalueWidget: null,
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 26,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => PickupPage(
                    devices: widget.devices,
                    posts: widget.posts,
                    onDeviceUpdated: widget.onDeviceUpdated,
                  ),
                ),
              );
            },
            child: _overviewRow(
              icon: Icons.local_shipping,
              iconColor: iconPickup,
              title: 'Pickups',
              valueWidget: Text(
                '$pickups',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              subvalueWidget: null,
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 26,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => InventoryPage(
                    devices: widget.devices,
                    onDeviceUpdated: widget.onDeviceUpdated,
                  ),
                ),
              );
            },
            child: _overviewRow(
              icon: Icons.inventory_2,
              iconColor: iconInventory,
              title: 'Inventory',
              valueWidget: Row(
                children: [
                  Text(
                    '${widget.devices.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              subvalueWidget: null,
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget valueWidget,
    Widget? subvalueWidget,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    valueWidget,
                    if (subvalueWidget != null) ...[
                      const SizedBox(width: 6),
                      subvalueWidget,
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildPostsArea(BuildContext context) {
    if (widget.posts.isEmpty) {
      return Column(
        children: [
          _buildPostCard(
            context,
            Post(
              id: 'demo1',
              userName: 'You',
              avatarColor: Colors.blueGrey,
              deviceName: 'Your first post',
              category: 'Electronics',
              description:
                  'Start sharing your e-waste journey with the community!',
              status: 'available',
              estWeightKg: 0.5,
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
          const SizedBox(height: 16),
          _buildPostCard(
            context,
            Post(
              id: 'demo2',
              userName: 'You',
              avatarColor: Colors.blueGrey,
              deviceName: 'Another example',
              category: 'Phone',
              description:
                  'This is how your posts will appear when you create them',
              status: 'for pickup',
              estWeightKg: 0.2,
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            ),
          ),
        ],
      );
    }

    return Column(
      children: widget.posts.map((post) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPostCard(context, post),
        );
      }).toList(),
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: post.avatarColor,
                  child: Text(
                    post.userName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.category} • ${_timeAgo(post.createdAt)}',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.more_horiz, color: textMuted),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.zero,
              bottom: Radius.zero,
            ),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: post.imagePath != null
                  ? Container(
                      color: Colors.grey[50],
                      child: post.imagePath!.startsWith('asset:')
                          ? Image.asset(
                              post.imagePath!.substring(6),
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(post.imagePath!),
                              fit: BoxFit.cover,
                            ),
                    )
                  : Container(
                      color: Colors.grey[50],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          size: 56,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.deviceName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textMuted, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(post.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(post.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        post.status,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(post.status),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      // Safe access to estWeightKg (handles null)
                      '${(post.estWeightKg ?? 0.0).toStringAsFixed(2)} kg',
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_outline, size: 22),
                  color: textMuted,
                  splashRadius: 20,
                ),
                Text(
                  '${post.likes}',
                  style: TextStyle(color: textMuted, fontSize: 13),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline, size: 22),
                  color: textMuted,
                  splashRadius: 20,
                ),
                Text(
                  '${post.comments}',
                  style: TextStyle(color: textMuted, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.share_outlined, size: 22),
                  color: textMuted,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
