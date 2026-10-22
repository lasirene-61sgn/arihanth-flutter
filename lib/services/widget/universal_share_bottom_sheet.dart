import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/chat/model/chat_model.dart';
import 'package:arianth/screens/chat/riverpod/chat_detail_notifier.dart';
import 'package:arianth/screens/chat/riverpod/chat_notifier.dart';
import 'package:arianth/screens/chat/riverpod/contacts_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class UniversalShareOptionsBottomSheet extends ConsumerStatefulWidget {
  final List<ShareCardItem> shareItems;
  final String title;

  const UniversalShareOptionsBottomSheet({
    super.key,
    required this.shareItems,
    this.title = 'Share Item',
  });

  static Future<void> show({
    required BuildContext context,
    required List<ShareCardItem> shareItems,
    String title = 'Share Item',
  }) async {
    if (shareItems.isEmpty) {
      Toaster.showError("No items to share");
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UniversalShareOptionsBottomSheet(
        shareItems: shareItems,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<UniversalShareOptionsBottomSheet> createState() =>
      _UniversalShareOptionsBottomSheetState();
}

class _UniversalShareOptionsBottomSheetState
    extends ConsumerState<UniversalShareOptionsBottomSheet> {
  bool _isProcessing = false;
  String _statusText = '';

  Future<void> _shareToWhatsApp() async {
    Navigator.of(context).pop();
    await ShareCardService.shareMultipleDirect(context, widget.shareItems);
  }

  Future<void> _openChatPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _UniversalChatRecipientPicker(
        onRecipientSelected: (chat) async {
          Navigator.of(sheetContext).pop();
          await _sendToConversation(chat);
        },
      ),
    );
  }

  Future<void> _sendToConversation(ChatModel chat) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Generating card preview...';
    });

    try {
      int? convId = chat.conversationId;
      if (convId == null && chat.isGroup && chat.id != null) {
        convId = chat.id;
      } else if (convId == null && chat.id != null) {
        setState(() => _statusText = 'Connecting with ${chat.name ?? 'user'}...');
        convId = await ref.read(chatDetailProvider.notifier).startConversation(
          chat.id!,
          recipientType: chat.type,
        );
      }

      if (convId == null) {
        Toaster.showError("Could not start chat with ${chat.name ?? 'selected user'}");
        if (mounted) Navigator.of(context).pop();
        return;
      }

      setState(() => _statusText = 'Rendering card image...');
      if (!mounted) return;
      final List<XFile> cardFiles =
          await ShareCardService.captureCardFiles(context, widget.shareItems);

      if (!mounted) return;
      if (cardFiles.isEmpty) {
        Toaster.showError("Failed to generate share image");
        Navigator.of(context).pop();
        return;
      }

      setState(() => _statusText = 'Sending to chat...');
      final chatNotifier = ref.read(chatDetailProvider.notifier);
      await chatNotifier.fetchMessages(convId, isSilent: true);

      for (int i = 0; i < cardFiles.length; i++) {
        final file = cardFiles[i];
        final item = widget.shareItems.length > i ? widget.shareItems[i] : widget.shareItems.first;
        
        // Build clear descriptive caption
        final parts = <String>[];
        if (item.workOrderNumber?.isNotEmpty == true) parts.add("WO#: ${item.workOrderNumber}");
        if (item.productCode?.isNotEmpty == true) parts.add("PO#: ${item.productCode}");
        if (item.title?.isNotEmpty == true) parts.add(item.title!);
        if (item.category?.isNotEmpty == true) parts.add("Category: ${item.category}");
        if (item.quantity?.isNotEmpty == true) parts.add("Qty: ${item.quantity}");

        final caption = parts.join(" | ");

        await chatNotifier.sendAttachment(
          filePath: file.path,
          fileName: file.name,
          caption: caption.isNotEmpty ? caption : null,
        );
      }

      Toaster.showSuccess("Shared to ${chat.name ?? 'Chat'} successfully!");
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error sending item to chat: $e");
      Toaster.showError("Failed to send item to chat");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24, left: 20, right: 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: AppColor.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "${widget.shareItems.length} card${widget.shareItems.length > 1 ? 's' : ''} ready to share",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isProcessing) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColor.primary, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text(
                      _statusText,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _UniversalShareOptionTile(
                iconWidget: Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage("assets/image/whatsapp.png"),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                title: "Share via WhatsApp",
                subtitle: "Send high-res cards directly to WhatsApp or apps",
                onTap: _shareToWhatsApp,
              ),
              const SizedBox(height: 12),
              _UniversalShareOptionTile(
                iconWidget: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColor.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                ),
                title: "Share to App Chat",
                subtitle: "Send card directly into in-app chat conversation",
                onTap: _openChatPicker,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UniversalShareOptionTile extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _UniversalShareOptionTile({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _UniversalChatRecipientPicker extends ConsumerStatefulWidget {
  final ValueChanged<ChatModel> onRecipientSelected;

  const _UniversalChatRecipientPicker({required this.onRecipientSelected});

  @override
  ConsumerState<_UniversalChatRecipientPicker> createState() => _UniversalChatRecipientPickerState();
}

class _UniversalChatRecipientPickerState extends ConsumerState<_UniversalChatRecipientPicker> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).fetchChats();
      ref.read(contactsProvider.notifier).fetchContacts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final contactsState = ref.watch(contactsProvider);

    final searchQuery = _searchCtrl.text.toLowerCase().trim();

    final filteredChats = chatState.chats.where((c) {
      if (searchQuery.isEmpty) return true;
      final name = (c.name ?? '').toLowerCase();
      final code = (c.bpCode ?? '').toLowerCase();
      return name.contains(searchQuery) || code.contains(searchQuery);
    }).toList();

    final filteredContacts = contactsState.contacts.where((c) {
      if (searchQuery.isEmpty) return true;
      final name = (c.name ?? '').toLowerCase();
      final code = (c.bpCode ?? '').toLowerCase();
      return name.contains(searchQuery) || code.contains(searchQuery);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Send to Chat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Search chats & contacts...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTabButton(0, "Recent Chats (${filteredChats.length})"),
              const SizedBox(width: 8),
              _buildTabButton(1, "All Contacts (${filteredContacts.length})"),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedTab == 0
                ? _buildList(filteredChats, chatState.isLoading)
                : _buildList(filteredContacts, contactsState.isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.primary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<ChatModel> list, bool isLoading) {
    if (isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColor.primary));
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No chats found',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final chat = list[index];
        final name = chat.name ?? 'Unknown';
        final bpCode = chat.bpCode;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColor.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: bpCode != null && bpCode.isNotEmpty
              ? Text('BP Code: $bpCode', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
              : null,
          trailing: const Icon(Icons.send_rounded, color: AppColor.primary, size: 20),
          onTap: () => widget.onRecipientSelected(chat),
        );
      },
    );
  }
}
