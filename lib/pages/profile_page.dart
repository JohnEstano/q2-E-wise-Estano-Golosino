// lib/pages/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/device.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/firebase_service.dart';
import '../services/device_service.dart';
import '../services/post_service.dart';
import 'home_page.dart';
import 'inventory_page.dart';
import 'map_page.dart';
import 'pickup_page.dart';
import 'camera_page.dart';
import 'leaderboards_page.dart';
import 'community_post_detail_page.dart';
import '../services/leaderboard_service.dart';
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
  final DeviceService _deviceService = DeviceService();
  final PostService _postService = PostService();
  final LeaderboardService _leaderboardService = LeaderboardService();
  int? _userRank;

  @override
  void initState() {
    super.initState();
    _loadUserRank();
  }

  Future<void> _loadUserRank() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final rank = await _leaderboardService.getUserRank(userId);
      if (mounted) {
        setState(() {
          _userRank = rank;
        });
      }
    }
  }

  // Helper to safely read estWeightKg and quantity
  double _deviceWeight(Device d) {
    return d.estWeightKg * d.quantity;
  }

  double get _totalWeightKg =>
      widget.devices.fold<double>(0.0, (prev, d) => prev + _deviceWeight(d));

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
    // Always use current Firebase Auth user data instead of passed widget.user
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName =
        currentUser?.displayName ?? widget.user?.displayName ?? 'User';
    final email = currentUser?.email ?? widget.user?.email ?? '';
    final photoURL = currentUser?.photoURL ?? widget.user?.photoURL;

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
                  onBackgroundImageError: (exception, stackTrace) {
                    // Fallback handled by child below
                  },
                  child: photoURL.isEmpty
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
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
    return StreamBuilder<List<Device>>(
      stream: _deviceService.getDevices(),
      builder: (context, deviceSnapshot) {
        final devices = deviceSnapshot.data ?? [];
        final totalScans = devices.length;
        final totalWeightKg = devices.fold<double>(
          0.0,
          (sum, d) => sum + (d.estWeightKg * d.quantity),
        );

        return StreamBuilder<List<PostModel>>(
          stream: _postService.getPostsByUser(
            FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
          builder: (context, postSnapshot) {
            final posts = postSnapshot.data ?? [];
            final totalPosts = posts.length;

            // Calculate ecoscore based on scans and posts
            final double fromScans = totalScans * 8.0;
            final double fromPosts = totalPosts * 5.0;
            final double fromWeight = totalWeightKg * 4.0;
            final ecoscoreRaw = fromScans + fromPosts + fromWeight;
            final int ecoscoreInt = ecoscoreRaw.clamp(0.0, 100.0).round();

            // Use real rank from leaderboard or show loading
            final ecoscoreRank = _userRank ?? 0;
            const int ecoscoreGrowth = 0; // No growth tracking yet

            // No pickups feature yet
            const int pickups = 0;

            const Color iconEcoscore = Colors.green;
            const Color iconScans = Colors.blue;
            const Color iconPickup = Colors.redAccent;
            const Color iconInventory = Colors.deepPurple;

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
                        MaterialPageRoute(
                          builder: (c) => const LeaderboardsPage(),
                        ),
                      );
                    },
                    child: _overviewRow(
                      icon: Icons.eco,
                      iconColor: iconEcoscore,
                      title: 'Eco Score',
                      valueWidget: Row(
                        children: [
                          if (ecoscoreRank > 0)
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
                          if (ecoscoreRank > 0) const SizedBox(width: 10),
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
                      subvalueWidget: ecoscoreGrowth > 0
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                Text(
                                  '+$ecoscoreGrowth%',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : null,
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
                        MaterialPageRoute(builder: (c) => const CameraPage()),
                      );
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
                            '${devices.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'items (${totalWeightKg.toStringAsFixed(2)} kg)',
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
          },
        );
      },
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('Please log in to see your posts'));
    }

    return StreamBuilder<List<PostModel>>(
      stream: _postService.getPostsByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading posts: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Column(
            children: [
              Icon(Icons.post_add, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your e-waste with the community!',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          );
        }

        return Column(
          children: posts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPostModelCard(context, post),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPostModelCard(BuildContext context, PostModel post) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final device = post.device;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = userId != null && post.likedBy.contains(userId);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CommunityPostDetailPage(post: post),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Info Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primary.withOpacity(0.2),
                    child: post.userPhotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              post.userPhotoUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, color: primary);
                              },
                            ),
                          )
                        : Icon(Icons.person, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${device.category} • ${_timeAgo(post.postedAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Device Image
            if (device.imagePath != null || device.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: device.imageUrl != null
                      ? Image.network(
                          device.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.devices,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                      : device.imagePath != null
                      ? Image.file(
                          File(device.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.devices,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.devices,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(device.category, primary),
                      if (device.brand != null)
                        _buildTag(device.brand!, Colors.blue),
                      _buildTag(device.status, _getStatusColor(device.status)),
                      _buildTag(
                        '${device.estWeightKg.toStringAsFixed(2)} kg',
                        Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 0.5),

            // Like and Comment Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (userId == null) return;
                      await _postService.toggleLike(post.id);
                    },
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey.shade600,
                    ),
                    splashRadius: 20,
                  ),
                  Text(
                    '${post.likedBy.length}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              CommunityPostDetailPage(post: post),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.comment_outlined,
                      color: Colors.grey.shade600,
                    ),
                    splashRadius: 20,
                  ),
                  Text(
                    '${post.comments}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
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
