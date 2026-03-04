import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dating_app/config/theme.dart';

class _PlaceholderMatch {
  final String id;
  final String name;
  final int age;
  final String matchedAgo;

  const _PlaceholderMatch({
    required this.id,
    required this.name,
    required this.age,
    required this.matchedAgo,
  });
}

const _placeholderMatches = [
  _PlaceholderMatch(id: '1', name: 'Sophie', age: 26, matchedAgo: '2h ago'),
  _PlaceholderMatch(id: '2', name: 'Emma', age: 24, matchedAgo: '5h ago'),
  _PlaceholderMatch(id: '3', name: 'Olivia', age: 28, matchedAgo: '1d ago'),
  _PlaceholderMatch(id: '4', name: 'Ava', age: 25, matchedAgo: '2d ago'),
  _PlaceholderMatch(id: '5', name: 'Mia', age: 27, matchedAgo: '3d ago'),
  _PlaceholderMatch(id: '6', name: 'Isabella', age: 23, matchedAgo: '5d ago'),
];

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New matches horizontal list
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'New Matches',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _placeholderMatches.length,
              itemBuilder: (context, index) {
                final match = _placeholderMatches[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/chat/${match.id}?name=${match.name}');
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryPink,
                                AppTheme.accentCoral,
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPink.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          match.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          match.matchedAgo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // All matches grid
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'All Matches',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _placeholderMatches.length,
              itemBuilder: (context, index) {
                final match = _placeholderMatches[index];
                return GestureDetector(
                  onTap: () {
                    context.push('/chat/${match.id}?name=${match.name}');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryRose.withOpacity(0.3),
                                  AppTheme.softPink.withOpacity(0.5),
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 64,
                              color: Colors.white60,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${match.name}, ${match.age}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Matched ${match.matchedAgo}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.greyText,
                                  ),
                                ),
                              ],
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
