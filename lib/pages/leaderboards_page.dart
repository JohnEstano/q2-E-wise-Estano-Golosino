import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/leaderboard_service.dart';

class LeaderboardsPage extends StatefulWidget {
  const LeaderboardsPage({super.key});

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  final List<Map<String, dynamic>> _levels = [
    {'label': 'Global', 'icon': Icons.public},
    // Future levels can be added here
    // {'label': 'City', 'icon': Icons.location_city},
    // {'label': 'Province', 'icon': Icons.map},
  ];
  String _selectedLevel = 'Global';
  bool _isLoading = true;
  List<LeaderboardEntry> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        setState(() {
          _leaderboard = [];
          _isLoading = false;
        });
        return;
      }

      final leaderboard = await _leaderboardService.getLeaderboardWithUser(
        currentUserId: currentUserId,
        topCount: 20,
      );

      setState(() {
        _leaderboard = leaderboard;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() {
        _leaderboard = [];
        _isLoading = false;
      });
    }
  }

  // Vibrant colors for medals
  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD600); // Lightning Yellow (Gold)
      case 2:
        return const Color(0xFFB0BEC5); // Vibrant Silver
      case 3:
        return const Color(0xFFFF8A65); // Vibrant Bronze (Orange)
      default:
        return Colors.grey.shade300;
    }
  }

  Color _rankTextColor(int rank, bool isMe) {
    if (isMe) return Colors.white;
    if (rank == 1) return Colors.black; // Black on yellow
    if (rank == 2) return Colors.black; // Black on silver
    if (rank == 3) return Colors.white; // White on orange
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        title: const Text(
          'Leaderboards',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Rank Level:',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedLevel,
                      items: _levels
                          .map(
                            (level) => DropdownMenuItem<String>(
                              value: level['label'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    level['icon'] as IconData,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    level['label'] as String,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedLevel = val);
                          _loadLeaderboard();
                        }
                      },
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      underline: Container(),
                      dropdownColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _leaderboard.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No entries yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start scanning devices to appear!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ).copyWith(top: 8, bottom: 16),
                    itemCount: _leaderboard.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, idx) {
                      final entry = _leaderboard[idx];
                      final bool isMe = entry.isCurrentUser;
                      final int rank = entry.rank;
                      final String name = entry.userName;
                      final int score = entry.ecoScore;

                      return Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isMe
                                ? cs.primary.withOpacity(0.12)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: cs.primary.withOpacity(0.2),
                                  child: entry.photoURL != null
                                      ? ClipOval(
                                          child: Image.network(
                                            entry.photoURL!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    color: cs.primary,
                                                  );
                                                },
                                          ),
                                        )
                                      : Icon(Icons.person, color: cs.primary),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? cs.primary
                                          : _rankColor(rank),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        color: _rankTextColor(rank, isMe),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              name + (isMe ? ' (You)' : ''),
                              style: TextStyle(
                                fontWeight: isMe
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isMe ? cs.primary : Colors.black87,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.eco,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isMe ? cs.primary : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
