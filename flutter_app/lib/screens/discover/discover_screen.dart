import 'package:flutter/material.dart';
import 'package:dating_app/config/theme.dart';

class _NearbyUser {
  final String name;
  final int age;
  final String city;
  final String distance;
  final bool isOnline;

  const _NearbyUser({
    required this.name,
    required this.age,
    required this.city,
    required this.distance,
    this.isOnline = false,
  });
}

const _placeholderUsers = [
  _NearbyUser(
      name: 'Luna', age: 24, city: 'Downtown', distance: '1.2 km', isOnline: true),
  _NearbyUser(
      name: 'Aria', age: 26, city: 'Midtown', distance: '2.5 km', isOnline: true),
  _NearbyUser(
      name: 'Chloe', age: 23, city: 'West Side', distance: '3.1 km'),
  _NearbyUser(
      name: 'Zoe', age: 27, city: 'East Village', distance: '4.0 km', isOnline: true),
  _NearbyUser(
      name: 'Lily', age: 25, city: 'Uptown', distance: '5.2 km'),
  _NearbyUser(
      name: 'Grace', age: 22, city: 'Harbor', distance: '6.7 km'),
  _NearbyUser(
      name: 'Nora', age: 28, city: 'Park Side', distance: '7.3 km', isOnline: true),
  _NearbyUser(
      name: 'Ella', age: 26, city: 'Central', distance: '8.1 km'),
];

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Distance filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.location_on,
                    color: AppTheme.primaryPink, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Nearby',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.softPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Within 10 km',
                    style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _placeholderUsers.length,
              itemBuilder: (context, index) {
                final user = _placeholderUsers[index];
                return _DiscoverCard(user: user);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final _NearbyUser user;

  const _DiscoverCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryRose.withOpacity(0.4),
                          AppTheme.softPink.withOpacity(0.6),
                          AppTheme.accentCoral.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 56,
                      color: Colors.white54,
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.onlineGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.name}, ${user.age}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.greyText),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${user.city} - ${user.distance}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greyText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Icon(Icons.favorite, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
