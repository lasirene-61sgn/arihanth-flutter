import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/chat/riverpod/chat_detail_notifier.dart';
import 'package:arianth/screens/chat/riverpod/chat_notifier.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool searchToggle = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchChats());
    ChatNotifier.onMessageReceivedCallback = () {
      if (mounted) {
        ref.read(chatProvider.notifier).fetchChats(isRefresh: true);
      }
    };
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!searchToggle) {
        ref.read(chatProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    ChatNotifier.onMessageReceivedCallback = null;
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatChatTime(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (messageDate == today) {
        return DateFormat('hh:mm a').format(dateTime);
      } else if (today.difference(messageDate).inDays == 1) {
        return 'Yesterday';
      } else if (now.difference(dateTime).inDays < 7) {
        return DateFormat('EEE').format(dateTime); // e.g. Mon, Tue
      } else {
        return DateFormat('dd/MM/yy').format(dateTime);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: AppColor.divider),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),

        // 🔵 Toggle between Title and Search Bar
        title: !searchToggle
            ? const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : EnterpriseSearchBar(
                controller: _searchController,
                hintText: 'Search Contacts...',
                onChanged: (value) {
                  ref.read(chatProvider.notifier).searchChatsFromServer(value);
                },
                onCancel: () {
                  setState(() {
                    _searchController.clear();
                    searchToggle = false;
                    ref.read(chatProvider.notifier).searchChatsFromServer('');
                  });
                },
              ),

        actions: [
          if (!searchToggle)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  searchToggle = true;
                });
              },
            ),
          // 💬 Social Chat Icon to open contacts & users screen
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Get.toNamed(AppRoutes.chatContacts)?.then((_) {
                  ref.read(chatProvider.notifier).fetchChats();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: const Icon(
                  Icons.mark_chat_unread_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Get.toNamed(AppRoutes.chatContacts)?.then((_) {
            ref.read(chatProvider.notifier).fetchChats();
          });
        },
      ),
      body: (chatState.isLoading && chatState.chats.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : chatState.error != null && chatState.chats.isEmpty
              ? Center(child: Text(chatState.error!))
              : chatState.chats.isEmpty
                  ? const Center(child: Text('No contacts found'))
                  : ListView.separated(
                      controller: _scrollController,
                      itemCount: chatState.chats.length + (chatState.isMoreLoading ? 1 : 0),
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: AppColor.divider.withOpacity(0.5),
                        indent: 70,
                      ),
                      itemBuilder: (context, index) {
                        if (index == chatState.chats.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        final chat = chatState.chats[index];
                        final bool isGroup = chat.isGroup || chat.type == 'group';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isGroup
                                ? Colors.teal.withValues(alpha: 0.12)
                                : AppColor.primary.withValues(alpha: 0.1),
                            backgroundImage: chat.imageUrl != null && chat.imageUrl!.isNotEmpty
                                ? NetworkImage(chat.imageUrl!)
                                : null,
                            child: chat.imageUrl == null || chat.imageUrl!.isEmpty
                                ? (isGroup
                                    ? const Icon(Icons.groups_rounded, color: Colors.teal, size: 24)
                                    : Text(
                                        chat.name != null && chat.name!.isNotEmpty
                                            ? chat.name!.substring(0, 1).toUpperCase()
                                            : '?',
                                        style: TextStyle(color: AppColor.primary),
                                      ))
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: RichText(
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      TextSpan(text: chat.name ?? (isGroup ? 'Group' : '')),
                                      if (!isGroup && chat.bpCode != null && chat.bpCode!.isNotEmpty)
                                        TextSpan(
                                          text: ' (${chat.bpCode})',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (isGroup || chat.type != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isGroup
                                        ? Colors.teal.withValues(alpha: 0.1)
                                        : (chat.type == 'buyer'
                                            ? Colors.blue.withValues(alpha: 0.1)
                                            : Colors.orange.withValues(alpha: 0.1)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isGroup
                                          ? Colors.teal.withValues(alpha: 0.3)
                                          : (chat.type == 'buyer'
                                              ? Colors.blue.withValues(alpha: 0.3)
                                              : Colors.orange.withValues(alpha: 0.3)),
                                    ),
                                  ),
                                  child: Text(
                                    isGroup ? 'GROUP' : chat.type!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isGroup
                                          ? Colors.teal
                                          : (chat.type == 'buyer' ? Colors.blue : Colors.orange),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    (chat.lastMessage != null && chat.lastMessage!.isNotEmpty)
                                        ? chat.lastMessage!
                                        : 'No messages yet',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: (chat.lastMessage != null && chat.lastMessage!.isNotEmpty)
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade400,
                                      fontSize: 13,
                                      fontWeight: (chat.unreadCount != null && chat.unreadCount! > 0)
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (chat.lastMessageTime != null && chat.lastMessageTime!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatChatTime(chat.lastMessageTime!),
                                    style: TextStyle(
                                      color: (chat.unreadCount != null && chat.unreadCount! > 0)
                                          ? AppColor.primary
                                          : Colors.grey.shade500,
                                      fontSize: 11,
                                      fontWeight: (chat.unreadCount != null && chat.unreadCount! > 0)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          trailing: (chat.unreadCount != null && chat.unreadCount! > 0)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${chat.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onLongPress: null,
                          onTap: () async {
                            int? convId = chat.conversationId;
                            // Only start conversation if it is direct 1-to-1 without conversationId
                            if (convId == null && !isGroup && chat.id != null) {
                              convId = await ref.read(chatDetailProvider.notifier).startConversation(
                                chat.id!,
                                recipientType: chat.type,
                              );
                            } else if (convId == null && isGroup && chat.id != null) {
                              convId = chat.id;
                            }

                            if (convId != null) {
                              Get.toNamed(
                                AppRoutes.chatDetails,
                                arguments: {
                                  'conversationId': convId,
                                  'chatName': chat.name ?? (isGroup ? 'Group Chat' : 'Chat'),
                                  'partnerCode': isGroup ? '' : chat.bpCode,
                                },
                              )?.then((_) {
                                ref.read(chatProvider.notifier).fetchChats();
                              });
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
