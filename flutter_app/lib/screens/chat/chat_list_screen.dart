import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dating_app/config/theme.dart';

class _PlaceholderConversation {
  final String matchId;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;

  const _PlaceholderConversation({
    required this.matchId,
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.isOnline = false,
  });
}

const _placeholderConversations = [
  _PlaceholderConversation(
    matchId: '1',
    name: 'Sophie',
    lastMessage: 'Hey! How was your weekend?',
    time: '2m',
    unread: 2,
    isOnline: true,
  ),
  _PlaceholderConversation(
    matchId: '2',
    name: 'Emma',
    lastMessage: 'That restaurant was amazing!',
    time: '1h',
    isOnline: true,
  ),
  _PlaceholderConversation(
    matchId: '3',
    name: 'Olivia',
    lastMessage: 'See you Saturday then!',
    time: '3h',
    unread: 1,
  ),
  _PlaceholderConversation(
    matchId: '4',
    name: 'Ava',
    lastMessage: 'Have you read the new Brandon Sanderson?',
    time: '1d',
  ),
  _PlaceholderConversation(
    matchId: '5',
    name: 'Mia',
    lastMessage: 'Just finished a 10K run!',
    time: '2d',
  ),
];

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: _placeholderConversations.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _placeholderConversations.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(left: 84),
                child: Divider(height: 1),
              ),
              itemBuilder: (context, index) {
                final convo = _placeholderConversations[index];
                return _ConversationTile(conversation: convo);
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.greyText.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Match with someone and start a conversation!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.greyText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _PlaceholderConversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      onTap: () {
        context.push(
            '/chat/${conversation.matchId}?name=${conversation.name}');
      },
      leading: Stack(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRose.withOpacity(0.5),
                  AppTheme.softPink,
                ],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          if (conversation.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conversation.name,
        style: TextStyle(
          fontWeight:
              conversation.unread > 0 ? FontWeight.w700 : FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.unread > 0
              ? AppTheme.darkText
              : AppTheme.greyText,
          fontWeight:
              conversation.unread > 0 ? FontWeight.w500 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            conversation.time,
            style: TextStyle(
              color: conversation.unread > 0
                  ? AppTheme.primaryPink
                  : AppTheme.greyText,
              fontSize: 12,
              fontWeight: conversation.unread > 0
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          if (conversation.unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unread}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
