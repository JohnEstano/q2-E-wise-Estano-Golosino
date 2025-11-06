// lib/pages/home_page.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'inventory_page.dart';
import '../models/device.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import 'profile_page.dart';
import 'camera_page.dart';
import 'map_page.dart';
import 'pickup_page.dart';
import 'community_post_detail_page.dart';
import 'comments_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
// FIX: Use an alias for navigation.dart to avoid ambiguous import
import '../widgets/navigation.dart' as nav;

class HomePage extends StatefulWidget {
  final UserModel? user;

  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class Post {
  String id;
  String userName;
  Color avatarColor;
  String deviceName;
  String category;
  String description;
  String status;
  double estWeightKg;
  int likes;
  int comments;
  DateTime createdAt;
  bool likedByMe;
  String? imagePath;

  Post({
    required this.id,
    required this.userName,
    required this.avatarColor,
    required this.deviceName,
    required this.category,
    required this.description,
    required this.status,
    required this.estWeightKg,
    this.likes = 0,
    this.comments = 0,
    DateTime? createdAt,
    this.likedByMe = false,
    this.imagePath,
  }) : createdAt = createdAt ?? DateTime.now();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _searchCtl = TextEditingController();
  final _scanNameCtl = TextEditingController();
  bool _scanAnalyzing = false;
  final PostService _postService = PostService();

  // NEW: feed loading flag for shimmer placeholders
  bool _feedLoading = true;

  final List<Device> _devices = [
    Device(
      id: 'd1',
      name: 'Old Laptop',
      category: 'Laptop',
      status: 'for pickup',
      quantity: 1,
      estWeightKg: 2.0,
    ),
    Device(
      id: 'd2',
      name: 'Phone Model X',
      category: 'Phone',
      status: 'available',
      quantity: 3,
      estWeightKg: 0.2,
    ),
  ];

  final List<Post> _posts = [
    Post(
      id: 'tip_intro',
      userName: 'E-Wise',
      avatarColor: const Color(0xFF1565C0),
      deviceName: 'Welcome to E-Wise',
      category: 'Awareness',
      description:
          'Start your first-ever electronic waste scan with E-wise! 🎉\n\n'
          '• Tap the camera button to scan an item\n'
          '• Get instant identification and guidance\n'
          '• Learn proper disposal methods\n'
          '• Track your environmental impact\n'
          '• Connect with recycling centers\n\n'
          'Together we can reduce e-waste and protect our planet!\n\n',
      status: 'info',
      estWeightKg: 0.0,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now(),
      imagePath: 'asset:assets/images/intro.png',
    ),
    Post(
      id: 'tip_what_is_ewaste',
      userName: 'EcoFacts',
      avatarColor: const Color(0xFF2E7D32),
      deviceName: 'What is E-waste?',
      category: 'Awareness',
      description:
          'E-waste = discarded electronic devices (phones, laptops, chargers, batteries).\n\n'
          '• Contains hazardous materials like lead, mercury, and cadmium\n'
          '• Also contains valuable metals like gold, silver, and copper\n'
          '• Only 17.4% of e-waste is properly recycled globally\n'
          '• Proper disposal prevents environmental contamination\n'
          '• Recycling recovers valuable resources for reuse',
      status: 'info',
      estWeightKg: 0.0,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      imagePath: null,
    ),
    Post(
      id: 'tip_prepare_dropoff',
      userName: 'ReuseCenter',
      avatarColor: const Color(0xFF6A1B9A),
      deviceName: 'Prepare devices for drop-off',
      category: 'Awareness',
      description:
          'Before recycling or donating your electronics:\n\n'
          '1. Back up & remove personal data completely\n'
          '2. Remove batteries if possible (they often need separate recycling)\n'
          '3. Group cables and accessories together\n'
          '4. Label working items for potential donation\n'
          '5. Clean devices of dust and debris\n'
          '6. Check if device can be repaired instead of recycled\n'
          '7. Research local regulations for specific e-waste items',
      status: 'info',
      estWeightKg: 0.0,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      imagePath: null,
    ),
    Post(
      id: 'tip_battery_recycling',
      userName: 'EcoSafety',
      avatarColor: const Color(0xFFD32F2F),
      deviceName: 'Battery Recycling Guide',
      category: 'Awareness',
      description:
          'Batteries require special handling:\n\n'
          '• Lithium-ion batteries can cause fires if damaged\n'
          '• Never dispose of batteries in regular trash\n'
          '• Tape battery terminals before recycling\n'
          '• Many retailers offer battery recycling programs\n'
          '• Different battery types require different recycling processes\n'
          '• Button batteries are especially hazardous to children and pets',
      status: 'info',
      estWeightKg: 0.0,
      likes: 0,
      comments: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      imagePath: null,
    ),
    Post(
      id: 'p1',
      userName: 'Marisol',
      avatarColor: const Color(0xFF00695C),
      deviceName: 'iPhone 8 (broken screen)',
      category: 'Phone',
      description:
          'Found this in the barangay cleanup. Screen cracked but still boots — anyone wants to repair or reuse?',
      status: 'available',
      estWeightKg: 0.25,
      likes: 8,
      comments: 2,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      imagePath: null,
    ),
    Post(
      id: 'p2',
      userName: 'Rico (School Club)',
      avatarColor: const Color(0xFF2E7D32),
      deviceName: 'Old Dell Laptop',
      category: 'Laptop',
      description:
          'Battery swollen — need advice for safe drop off. Located in QC.',
      status: 'for pickup',
      estWeightKg: 2.1,
      likes: 4,
      comments: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      imagePath: null,
    ),
  ];

  double get _totalWeightKg =>
      _devices.fold(0.0, (p, d) => p + d.estWeightKg * d.quantity);
  double get _estimatedCo2Kg => _totalWeightKg * 2.5;

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  void initState() {
    super.initState();
    // simulate initial feed load; show shimmer for a brief moment
    Future.delayed(const Duration(milliseconds: 700)).then((_) {
      if (mounted) setState(() => _feedLoading = false);
    });
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _scanNameCtl.dispose();
    super.dispose();
  }

  void _openScan() async {
    final result = await Navigator.of(
      context,
    ).push<String?>(MaterialPageRoute(builder: (c) => const CameraPage()));

    if (result != null && result.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        builder: (c) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
            ),
            child: CreatePostSheet(
              initialImagePath: result,
              onCreate: (post) {
                setState(() {
                  _posts.insert(0, post);
                  _selectedIndex = 0;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Posted to feed')));
              },
            ),
          ),
        ),
      );
    }
  }

  void _openCreatePost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CreatePostSheet(
            user: widget.user,
            onCreate: (post) {
              setState(() {
                _posts.insert(0, post);
                _selectedIndex = 0;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Posted to feed')));
            },
          ),
        ),
      ),
    );
  }

  void _addDevice(Device d) {
    setState(() => _devices.insert(0, d));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${d.name} added to your inventory')),
    );
  }

  void _updateDevice(Device updatedDevice) {
    setState(() {
      final index = _devices.indexWhere((d) => d.id == updatedDevice.id);
      if (index != -1) {
        _devices[index] = updatedDevice;
      }
    });
  }

  void _createPostFromScan(Post p) {
    setState(() => _posts.insert(0, p));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Posted to feed')));
  }

  void _toggleLike(Post p) {
    setState(() {
      p.likedByMe = !p.likedByMe;
      if (p.likedByMe) {
        p.likes += 1;
      } else {
        p.likes = max(0, p.likes - 1);
      }
    });
  }

  bool _isTip(Post p) {
    return p.status == 'info' ||
        p.category.toLowerCase() == 'awareness' ||
        p.id.toLowerCase().startsWith('tip');
  }

  Color _tipColorFromId(String id) {
    const primaries = Colors.primaries;
    final idx = id.hashCode.abs() % primaries.length;
    return primaries[idx].shade300;
  }

  Widget _feedContent(BuildContext context) {
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;
    final cs = Theme.of(context).colorScheme;

    final tips = _posts.where(_isTip).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final others = _posts.where((p) => !_isTip(p)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    Widget tipsListView() {
      if (_feedLoading) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: 3,
          itemBuilder: (context, idx) => _shimmerTipCard(context),
        );
      }
      if (tips.isEmpty) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Text('No tips yet', style: TextStyle(color: textMuted)),
              ),
            ),
          ],
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: tips.length,
        itemBuilder: (context, idx) {
          final p = tips[idx];
          return _postCard(context, p);
        },
      );
    }

    Widget communityListView() {
      return StreamBuilder<List<PostModel>>(
        stream: _postService.getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: 4,
              itemBuilder: (context, idx) => _shimmerRegularCard(context),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading posts: ${snapshot.error}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            );
          }

          final communityPosts = snapshot.data ?? [];

          if (communityPosts.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No community posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to share your e-waste!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: communityPosts.length,
            itemBuilder: (context, idx) {
              final post = communityPosts[idx];
              return _communityPostCard(context, post);
            },
          );
        },
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TabBar(
              indicatorColor: cs.primary,
              labelColor: cs.primary,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Quick start'),
                Tab(text: 'Community'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _feedLoading = true);
                    await Future.delayed(const Duration(milliseconds: 700));
                    setState(() {
                      _posts.shuffle();
                      _feedLoading = false;
                    });
                  },
                  child: tipsListView(),
                ),
                RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _feedLoading = true);
                    await Future.delayed(const Duration(milliseconds: 700));
                    setState(() {
                      _posts.shuffle();
                      _feedLoading = false;
                    });
                  },
                  child: communityListView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(BuildContext context, Post p) {
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (c) =>
                PostDetailPage(post: p, tipColor: _tipColorFromId(p.id)),
          ),
        );
      },
      child: _isTip(p) ? _tipCard(context, p) : _regularCard(context, p),
    );
  }

  Widget _tipCard(BuildContext context, Post p) {
    final bgColor = _tipColorFromId(p.id);
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: p.imagePath != null
                  ? Container(
                      color: Colors.grey[50],
                      child: p.imagePath!.startsWith('asset:')
                          ? Image.asset(
                              p.imagePath!.substring(6),
                              fit: BoxFit.cover,
                            )
                          : Image.file(File(p.imagePath!), fit: BoxFit.cover),
                    )
                  : Container(
                      color: bgColor,
                      child: Center(
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 56,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.deviceName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.description,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textMuted, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        p.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _regularCard(BuildContext context, Post p) {
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: p.avatarColor,
                  child: Text(
                    p.userName[0],
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
                        p.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.category} • ${_timeAgo(p.createdAt)}',
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
              child: p.imagePath != null
                  ? Container(
                      color: Colors.grey[50],
                      child: p.imagePath!.startsWith('asset:')
                          ? Image.asset(
                              p.imagePath!.substring(6),
                              fit: BoxFit.cover,
                            )
                          : Image.file(File(p.imagePath!), fit: BoxFit.cover),
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
                  p.deviceName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.description,
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
                        color: _getStatusColor(p.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(p.status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        p.status,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(p.status),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${p.estWeightKg.toStringAsFixed(2)} kg',
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
                  onPressed: () => _toggleLike(p),
                  icon: Icon(
                    p.likedByMe ? Icons.favorite : Icons.favorite_outline,
                    size: 22,
                  ),
                  color: p.likedByMe ? Colors.redAccent : textMuted,
                  splashRadius: 20,
                ),
                Text(
                  '${p.likes}',
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
                  '${p.comments}',
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

  Widget _communityPostCard(BuildContext context, PostModel post) {
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
                      _buildPostTag(device.category, primary),
                      if (device.brand != null)
                        _buildPostTag(device.brand!, Colors.blue.shade700),
                      _buildPostTag(
                        device.status,
                        _getStatusColor(device.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Weight Info
                  Row(
                    children: [
                      Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${device.estWeightKg.toStringAsFixed(2)} kg',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
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
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        await _postService.toggleLike(post.id);
                      },
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isLiked ? primary : Colors.grey.shade600,
                      ),
                      label: Text(
                        '${post.likes}',
                        style: TextStyle(
                          color: isLiked ? primary : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CommentsPage(post: post),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.comment_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      label: Text(
                        '${post.comments}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTag(String label, Color color) {
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
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 12,
        ),
      ),
    );
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

  Widget _scanContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;

    Future<void> analyze() async {
      final name = _scanNameCtl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Type a device name for demo analysis')),
        );
        return;
      }
      setState(() => _scanAnalyzing = true);
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() => _scanAnalyzing = false);

      final outcome = _fakeAiAnalyze(name);
      final title = outcome['title'] ?? 'Device detected';
      final desc = outcome['desc'] ?? '';
      final category = outcome['category'] ?? 'Electronics';
      final status = outcome['recommendStatus'] ?? 'available';
      final double estWeight = (outcome['estWeight'] is double)
          ? outcome['estWeight'] as double
          : double.tryParse(outcome['estWeight']?.toString() ?? '0.5') ?? 0.5;

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        builder: (c) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(c).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    desc.toString(),
                    style: TextStyle(color: textMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            final d = Device(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: name,
                              category: category.toString(),
                              status: status.toString(),
                              estWeightKg: estWeight,
                            );
                            _addDevice(d);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Add to inventory'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: cs.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            final p = Post(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              userName: 'You',
                              avatarColor: Colors.blueGrey,
                              deviceName: name,
                              category: category.toString(),
                              description: desc.toString(),
                              status: status.toString(),
                              estWeightKg: estWeight,
                            );
                            _createPostFromScan(p);
                            Navigator.of(context).pop();
                          },
                          child: const Text('Post to feed'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.photo_camera, color: cs.primary),
              title: Text(
                'Camera / barcode scanning',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Use the field below to simulate scanning results',
                style: TextStyle(color: textMuted),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _scanNameCtl,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              labelText: 'Device name (for demo)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelStyle: TextStyle(color: textMuted),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: analyze,
                  child: _scanAnalyzing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Analyze', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  side: BorderSide(color: cs.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => _scanNameCtl.text = 'Phone Model X',
                child: const Text('Sample'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Flexible(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Camera placeholder',
                    style: TextStyle(color: textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Object> _fakeAiAnalyze(String name) {
    final n = name.toLowerCase();
    if (n.contains('phone') || n.contains('iphone') || n.contains('smart')) {
      return {
        'title': 'Smartphone detected',
        'desc':
            'Contains lithium battery (hazardous). Recommend drop-off or specialist recycling. Repair possible for screen/battery.',
        'category': 'Phone',
        'recommendStatus': 'for pickup',
        'estWeight': 0.25,
      };
    }
    if (n.contains('laptop') || n.contains('notebook')) {
      return {
        'title': 'Laptop detected',
        'desc':
            'Large device with valuable components (copper, aluminum, battery). Consider reuse or certified recycling.',
        'category': 'Laptop',
        'recommendStatus': 'for pickup',
        'estWeight': 2.0,
      };
    }
    if (n.contains('battery')) {
      return {
        'title': 'Battery detected',
        'desc':
            'Batteries are hazardous. Do not dispose in general trash. Take to a battery recycling point.',
        'category': 'Battery',
        'recommendStatus': 'for pickup',
        'estWeight': 0.3,
      };
    }
    final rand = Random().nextDouble() * 1.2 + 0.1;
    return {
      'title': 'Electronic device detected',
      'desc':
          'General electronic device. Recommend assessing for reuse, repair, or certified recycling.',
      'category': 'Electronics',
      'recommendStatus': 'available',
      'estWeight': double.parse(rand.toStringAsFixed(2)),
    };
  }

  Widget _pickupContent(BuildContext context) {
    // replaced by dedicated PickupPage — keep placeholder so indices remain stable.
    return Container();
  }

  // ----------------------------
  // Shimmer skeleton widgets
  // ----------------------------
  Widget _shimmerTipCard(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: Container(color: base),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: double.infinity, color: base),
                  const SizedBox(height: 8),
                  Container(height: 12, width: double.infinity, color: base),
                  const SizedBox(height: 8),
                  Container(height: 12, width: double.infinity, color: base),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 28,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(16),
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

  Widget _shimmerRegularCard(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: base,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 12, color: base),
                        const SizedBox(height: 6),
                        Container(height: 10, width: 120, color: base),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 18, height: 18, color: base),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Container(color: base),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, color: base),
                  const SizedBox(height: 8),
                  Container(height: 12, width: double.infinity, color: base),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 28,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const Spacer(),
                      Container(width: 40, height: 12, color: base),
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
                  Container(width: 28, height: 28, color: base),
                  const SizedBox(width: 8),
                  Container(width: 20, height: 12, color: base),
                  const Spacer(),
                  Container(width: 28, height: 12, color: base),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const Color textPrimary = Colors.black87;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        title: Row(
          children: [
            Icon(Icons.eco, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'E-Wise',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Search'),
                  content: TextField(
                    controller: _searchCtl,
                    decoration: const InputDecoration(
                      hintText: 'Search feed, users, devices...',
                    ),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('Close'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(c).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Searching for "${_searchCtl.text}"...',
                            ),
                          ),
                        );
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.search, color: textPrimary),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: _openCreatePost,
            icon: Icon(Icons.add_box_outlined, color: textPrimary),
            tooltip: 'Create post',
          ),
          const SizedBox(width: 8),
          // User Profile Avatar
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    devices: _devices,
                    onDeviceUpdated: _updateDevice,
                    posts: _posts,
                    user: widget.user,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: widget.user?.photoURL != null
                  ? CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.user!.photoURL!),
                      backgroundColor: cs.primary,
                    )
                  : CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primary,
                      child: Text(
                        (widget.user?.displayName?.isNotEmpty ?? false)
                            ? widget.user!.displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _feedContent(context),
            Container(),
            _scanContent(context),
            _pickupContent(context),
          ],
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
      // FIX: Use the alias for EwasteNavigationBar
      bottomNavigationBar: nav.EwasteNavigationBar(
        selectedIndex: _selectedIndex,
        user: widget.user,
        devices: _devices,
        onDeviceUpdated: _updateDevice,
      ),
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final Post post;
  final Color tipColor;
  const PostDetailPage({required this.post, required this.tipColor, super.key});

  @override
  Widget build(BuildContext context) {
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;
    final bool isTip = _isTipStatic(post);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(post.deviceName, style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        leading: BackButton(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: post.imagePath != null
                  ? (post.imagePath!.startsWith('asset:')
                        ? Image.asset(
                            post.imagePath!.substring(6),
                            fit: BoxFit.cover,
                          )
                        : Image.file(File(post.imagePath!), fit: BoxFit.cover))
                  : Container(
                      color: isTip ? tipColor : Colors.grey[200],
                      child: Center(
                        child: Icon(
                          isTip ? Icons.lightbulb_outline : Icons.image,
                          size: 56,
                          color: isTip ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            post.deviceName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isTip) ...[
                const SizedBox(width: 12),
                Text(
                  _timeAgoStatic(post.createdAt),
                  style: TextStyle(color: textMuted),
                ),
              ],
              const Spacer(),
              if (!isTip)
                Text(
                  '${post.estWeightKg.toStringAsFixed(2)} kg',
                  style: TextStyle(color: textMuted),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.description,
            style: TextStyle(color: textMuted, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static bool _isTipStatic(Post p) {
    return p.status == 'info' ||
        p.category.toLowerCase() == 'awareness' ||
        p.id.toLowerCase().startsWith('tip');
  }

  static String _timeAgoStatic(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class CreatePostSheet extends StatefulWidget {
  final void Function(Post) onCreate;
  final String? initialImagePath;
  final UserModel? user;

  const CreatePostSheet({
    required this.onCreate,
    this.initialImagePath,
    this.user,
    super.key,
  });
  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _deviceCtl = TextEditingController();
  final _descCtl = TextEditingController();
  String _category = 'Electronics';
  String _status = 'available';
  double _weight = 0.5;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _deviceCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _deviceCtl.text.trim();
    if (name.isEmpty && _imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter device name or attach an image'),
        ),
      );
      return;
    }

    // Use authenticated user's name
    final userName = widget.user?.displayName ?? 'Anonymous User';

    final post = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: userName,
      avatarColor: Colors.blueGrey,
      deviceName: name.isEmpty ? 'Captured item' : name,
      category: _category,
      description: _descCtl.text.trim(),
      status: _status,
      estWeightKg: _weight,
      imagePath: _imagePath,
    );
    widget.onCreate(post);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const Color textPrimary = Colors.black87;
    const Color textMuted = Colors.black54;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Create post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: textPrimary),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imagePath!.startsWith('asset:')
                      ? Image.asset(
                          _imagePath!.substring(6),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_imagePath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _imagePath = null),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check),
                      label: const Text('Keep image'),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _deviceCtl,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Device name (e.g. Old Laptop)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelStyle: TextStyle(color: textMuted),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtl,
                maxLines: 3,
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  labelStyle: TextStyle(color: textMuted),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _category,
                      items: const [
                        DropdownMenuItem(
                          value: 'Electronics',
                          child: Text('Electronics'),
                        ),
                        DropdownMenuItem(value: 'Phone', child: Text('Phone')),
                        DropdownMenuItem(
                          value: 'Laptop',
                          child: Text('Laptop'),
                        ),
                        DropdownMenuItem(
                          value: 'Battery',
                          child: Text('Battery'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _category = v ?? 'Electronics'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _status,
                      items: const [
                        DropdownMenuItem(
                          value: 'available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'for pickup',
                          child: Text('For pickup'),
                        ),
                        DropdownMenuItem(
                          value: 'donated',
                          child: Text('Donated'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _status = v ?? 'available'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Weight (kg)',
                    style: TextStyle(color: textPrimary, fontSize: 15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _weight,
                      min: 0.1,
                      max: 5.0,
                      divisions: 49,
                      label: _weight.toStringAsFixed(2),
                      onChanged: (v) => setState(() => _weight = v),
                      activeColor: cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submit,
                child: const Text('Post', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
