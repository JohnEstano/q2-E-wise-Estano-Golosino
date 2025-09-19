import 'package:flutter/material.dart';

class LeaderboardsPage extends StatefulWidget {
  final String userName;
  final int userRank;
  final int userScore;

  const LeaderboardsPage({
    super.key,
    this.userName = 'John Doe',
    this.userRank = 16,
    this.userScore = 50,
  });

  @override
  State<LeaderboardsPage> createState() => _LeaderboardsPageState();
}

class _LeaderboardsPageState extends State<LeaderboardsPage> {
  final List<Map<String, dynamic>> _levels = [
    {'label': 'Barangay', 'icon': Icons.home_work},
    {'label': 'Municipality', 'icon': Icons.apartment},
    {'label': 'City', 'icon': Icons.location_city},
    {'label': 'Province', 'icon': Icons.map},
    {'label': 'Region', 'icon': Icons.public},
    {'label': 'National', 'icon': Icons.flag},
    {'label': 'Worldwide', 'icon': Icons.language},
  ];
  String _selectedLevel = 'Barangay';

  Map<String, List<Map<String, dynamic>>> get _leaderboards => {
        'Barangay': [
          {'rank': 1, 'name': 'Maria Santos', 'score': 98},
          {'rank': 2, 'name': 'Juan Dela Cruz', 'score': 92},
          {'rank': 3, 'name': 'Liza Soberano', 'score': 89},
          {'rank': 4, 'name': 'Mark Lee', 'score': 85},
          {'rank': 5, 'name': 'Kim Chiu', 'score': 80},
          {'rank': 6, 'name': 'James Reid', 'score': 78},
          {'rank': 7, 'name': 'Sarah G', 'score': 76},
          {'rank': 8, 'name': 'Enrique Gil', 'score': 74},
          {'rank': 9, 'name': 'Kathryn Bernardo', 'score': 72},
          {'rank': 10, 'name': 'Daniel Padilla', 'score': 70},
          {'rank': 11, 'name': 'Vice Ganda', 'score': 68},
          {'rank': 12, 'name': 'Anne Curtis', 'score': 65},
          {'rank': 13, 'name': 'Coco Martin', 'score': 62},
          {'rank': 14, 'name': 'Angel Locsin', 'score': 60},
          {'rank': 15, 'name': 'Bea Alonzo', 'score': 58},
          {
            'rank': 16,
            'name': 'John Doe',
            'score': 50,
            'me': true,
          },
          {'rank': 17, 'name': 'Piolo Pascual', 'score': 48},
          {'rank': 18, 'name': 'Lea Salonga', 'score': 45},
        ],
        'Municipality': [
          {'rank': 1, 'name': 'Maria Santos', 'score': 99},
          {'rank': 2, 'name': 'Juan Dela Cruz', 'score': 95},
          {'rank': 3, 'name': 'Mark Lee', 'score': 90},
          {'rank': 4, 'name': 'Kim Chiu', 'score': 88},
          {'rank': 5, 'name': 'James Reid', 'score': 85},
        ],
        'City': [
          {'rank': 1, 'name': 'Maria Santos', 'score': 97},
          {'rank': 2, 'name': 'Juan Dela Cruz', 'score': 93},
          {'rank': 3, 'name': 'Mark Lee', 'score': 89},
          {'rank': 4, 'name': 'Kim Chiu', 'score': 87},
          {'rank': 5, 'name': 'James Reid', 'score': 84},
        ],
        'Province': [
          {'rank': 1, 'name': 'Juan Dela Cruz', 'score': 100},
          {'rank': 2, 'name': 'Maria Santos', 'score': 97},
          {'rank': 3, 'name': 'Mark Lee', 'score': 91},
        ],
        'Region': [
          {'rank': 1, 'name': 'Maria Santos', 'score': 100},
          {'rank': 2, 'name': 'Juan Dela Cruz', 'score': 95},
        ],
        'National': [
          {'rank': 1, 'name': 'Juan Dela Cruz', 'score': 100},
          {'rank': 2, 'name': 'Maria Santos', 'score': 96},
        ],
        'Worldwide': [
          {'rank': 1, 'name': 'Eco Hero', 'score': 100},
          {'rank': 2, 'name': 'Green Queen', 'score': 97},
        ],
      };

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
    final leaderboard = _leaderboards[_selectedLevel] ?? [];

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
                          .map((level) => DropdownMenuItem<String>(
                                value: level['label'] as String,
                                child: Row(
                                  children: [
                                    Icon(level['icon'] as IconData,
                                        size: 18, color: Colors.black54),
                                    const SizedBox(width: 6),
                                    Text(level['label'] as String,
                                        style: const TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedLevel = val);
                      },
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.black87),
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
            child: leaderboard.isEmpty
                ? const Center(child: Text('No entries yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 8, bottom: 16),
                    itemCount: leaderboard.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (context, idx) {
                      final entry = leaderboard[idx];
                      final bool isMe = entry['me'] == true;
                      final int rank = (entry['rank'] is int) ? entry['rank'] as int : (idx + 1);
                      final String name = (entry['name'] ?? '').toString();
                      final int score = (entry['score'] is int) ? entry['score'] as int : 0;

                      return Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isMe ? cs.primary.withOpacity(0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: isMe ? cs.primary : _rankColor(rank),
                              child: Text(
                                '#$rank',
                                style: TextStyle(
                                  color: _rankTextColor(rank, isMe),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              name + (isMe ? ' (You)' : ''),
                              style: TextStyle(
                                fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                                color: isMe ? cs.primary : Colors.black87,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '$score%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isMe ? cs.primary : Colors.black87,
                              ),
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
