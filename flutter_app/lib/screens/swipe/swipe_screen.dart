import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:dating_app/config/theme.dart';
import 'package:dating_app/widgets/swipe_card.dart';

class _PlaceholderProfile {
  final String name;
  final int age;
  final String bio;
  final String city;
  final List<String> interests;

  const _PlaceholderProfile({
    required this.name,
    required this.age,
    required this.bio,
    required this.city,
    required this.interests,
  });
}

const _placeholderProfiles = [
  _PlaceholderProfile(
    name: 'Sophie',
    age: 26,
    bio: 'Coffee addict. Dog mom. Love hiking on weekends.',
    city: 'San Francisco',
    interests: ['Hiking', 'Coffee', 'Dogs', 'Photography'],
  ),
  _PlaceholderProfile(
    name: 'Emma',
    age: 24,
    bio: 'Artist by day, foodie by night. Looking for someone to explore the city with.',
    city: 'New York',
    interests: ['Art', 'Food', 'Travel', 'Music'],
  ),
  _PlaceholderProfile(
    name: 'Olivia',
    age: 28,
    bio: 'Software engineer who loves yoga and board games.',
    city: 'Austin',
    interests: ['Yoga', 'Tech', 'Board Games', 'Cooking'],
  ),
  _PlaceholderProfile(
    name: 'Ava',
    age: 25,
    bio: 'Bookworm looking for a reading buddy and adventure partner.',
    city: 'Seattle',
    interests: ['Books', 'Hiking', 'Wine', 'Movies'],
  ),
  _PlaceholderProfile(
    name: 'Mia',
    age: 27,
    bio: 'Fitness enthusiast and travel junkie. Let\'s explore together!',
    city: 'Los Angeles',
    interests: ['Fitness', 'Travel', 'Surfing', 'Cooking'],
  ),
];

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: AppTheme.primaryPink,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              'Flame',
              style: TextStyle(
                color: AppTheme.primaryPink,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Card area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CardSwiper(
                controller: _swiperController,
                cardsCount: _placeholderProfiles.length,
                numberOfCardsDisplayed:
                    _placeholderProfiles.length.clamp(1, 3),
                backCardOffset: const Offset(0, -30),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                onSwipe: _onSwipe,
                onEnd: _onEnd,
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  final profile = _placeholderProfiles[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      SwipeCard(
                        name: profile.name,
                        age: profile.age,
                        bio: profile.bio,
                        imageUrl: '',
                        city: profile.city,
                        interests: profile.interests,
                      ),
                      // Like overlay
                      if (percentThresholdX > 0)
                        Positioned(
                          top: 40,
                          left: 20,
                          child: SwipeOverlayIndicator(
                            isLike: true,
                            opacity: percentThresholdX.clamp(0.0, 1.0),
                          ),
                        ),
                      // Nope overlay
                      if (percentThresholdX < 0)
                        Positioned(
                          top: 40,
                          right: 20,
                          child: SwipeOverlayIndicator(
                            isLike: false,
                            opacity: percentThresholdX.abs().clamp(0.0, 1.0),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dislike
                _ActionButton(
                  icon: Icons.close,
                  color: Colors.redAccent,
                  size: 56,
                  iconSize: 30,
                  onTap: () {
                    _swiperController.swipeLeft();
                  },
                ),
                const SizedBox(width: 20),
                // Super like
                _ActionButton(
                  icon: Icons.star,
                  color: Colors.blueAccent,
                  size: 48,
                  iconSize: 24,
                  onTap: () {
                    _swiperController.swipeTop();
                  },
                ),
                const SizedBox(width: 20),
                // Like
                _ActionButton(
                  icon: Icons.favorite,
                  color: AppTheme.primaryPink,
                  size: 56,
                  iconSize: 30,
                  onTap: () {
                    _swiperController.swipeRight();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final profile = _placeholderProfiles[previousIndex];
    final action = direction == CardSwiperDirection.right ? 'liked' : 'passed';
    print('You $action ${profile.name}');
    if (currentIndex != null) {
      setState(() => _currentIndex = currentIndex);
    }
    return true;
  }

  void _onEnd() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('No more cards'),
        content: const Text('Check back later for new people nearby!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
