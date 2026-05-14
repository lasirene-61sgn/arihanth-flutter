import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/chat/riverpod/chat_notifier.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool searchToggle = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).fetchChats());
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
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () => LanguageSelector.show(context, ref),
          ),
        ],
      ),
      body: chatState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatState.error != null
              ? Center(child: Text(chatState.error!))
              : chatState.chats.isEmpty
                  ? const Center(child: Text('No contacts found'))
                  : ListView.separated(
                      itemCount: chatState.chats.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: AppColor.divider.withOpacity(0.5),
                        indent: 70,
                      ),
                      itemBuilder: (context, index) {
                        final chat = chatState.chats[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColor.primary.withOpacity(0.1),
                            backgroundImage: chat.imageUrl != null && chat.imageUrl!.isNotEmpty
                                ? NetworkImage(chat.imageUrl!)
                                : null,
                            child: chat.imageUrl == null || chat.imageUrl!.isEmpty
                                ? Text(
                                    chat.name != null && chat.name!.isNotEmpty
                                        ? chat.name!.substring(0, 1).toUpperCase()
                                        : '?',
                                    style: TextStyle(color: AppColor.primary),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chat.name ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (chat.type != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: chat.type == 'buyer' 
                                        ? Colors.blue.withOpacity(0.1) 
                                        : Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: chat.type == 'buyer' 
                                          ? Colors.blue.withOpacity(0.3) 
                                          : Colors.orange.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    chat.type!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: chat.type == 'buyer' ? Colors.blue : Colors.orange,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (chat.bpCode != null)
                                Text(
                                  chat.bpCode!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              if (chat.lastMessage != null)
                                Text(
                                  chat.lastMessage!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (chat.lastMessageTime != null)
                                Text(
                                  chat.lastMessageTime!,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              if (chat.unreadCount != null && chat.unreadCount! > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColor.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${chat.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            if (chat.id != null) {
                              Get.toNamed(
                                AppRoutes.chatDetails,
                                arguments: {
                                  'conversationId': chat.id,
                                  'chatName': chat.name ?? 'Chat',
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
