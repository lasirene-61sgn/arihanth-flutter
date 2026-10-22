import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/chat/model/chat_model.dart';
import 'package:arianth/screens/chat/riverpod/chat_detail_notifier.dart';
import 'package:arianth/screens/chat/riverpod/contacts_notifier.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/enterprise_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class ChatContactsScreen extends ConsumerStatefulWidget {
  const ChatContactsScreen({super.key});

  @override
  ConsumerState<ChatContactsScreen> createState() => _ChatContactsScreenState();
}

class _ChatContactsScreenState extends ConsumerState<ChatContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _searchToggle = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(contactsProvider.notifier).fetchContacts());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(contactsProvider.notifier).loadMore(search: _searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: !_searchToggle
            ? const Text(
                'Contacts & Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : EnterpriseSearchBar(
                controller: _searchController,
                hintText: 'Search Contacts...',
                onChanged: (value) {
                  ref.read(contactsProvider.notifier).searchContacts(value);
                },
                onCancel: () {
                  setState(() {
                    _searchController.clear();
                    _searchToggle = false;
                    ref.read(contactsProvider.notifier).fetchContacts();
                  });
                },
              ),
        actions: [
          if (!_searchToggle)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _searchToggle = true;
                });
              },
            ),
        ],
      ),
      body: contactsState.isLoading && contactsState.contacts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : contactsState.error != null && contactsState.contacts.isEmpty
              ? Center(child: Text(contactsState.error!))
              : contactsState.contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No contacts found',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(contactsProvider.notifier).fetchContacts(search: _searchController.text);
                      },
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount: contactsState.contacts.length + (contactsState.isMoreLoading ? 1 : 0) + 1,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: AppColor.divider.withOpacity(0.5),
                          indent: 70,
                        ),
                        itemBuilder: (context, index) {
                          // Item 0: "New Group" option at the top of contacts list
                          if (index == 0) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColor.primary,
                                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
                              ),
                              title: const Text(
                                'New Group',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: const Text(
                                'Create a group with contacts',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                              onTap: () => _openCreateGroupDialog(contactsState.contacts),
                            );
                          }

                          final contactIndex = index - 1;
                          if (contactIndex == contactsState.contacts.length) {
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

                          final contact = contactsState.contacts[contactIndex];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColor.primary.withOpacity(0.1),
                              backgroundImage: contact.imageUrl != null && contact.imageUrl!.isNotEmpty
                                  ? NetworkImage(contact.imageUrl!)
                                  : null,
                              child: contact.imageUrl == null || contact.imageUrl!.isEmpty
                                  ? Text(
                                      (contact.name?.isNotEmpty ?? false)
                                          ? contact.name![0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: AppColor.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    contact.name ?? 'Unknown',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (contact.badge != null && contact.badge!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColor.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      contact.badge!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              contact.bpCode?.isNotEmpty == true
                                  ? contact.bpCode!
                                  : (contact.mobile?.isNotEmpty == true ? contact.mobile! : ''),
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            trailing: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.chat, color: AppColor.primary, size: 18),
                              ),
                              onPressed: () async {
                                if (contact.id == null) return;
                                final convId = await ref.read(chatDetailProvider.notifier).startConversation(
                                  contact.id!,
                                  recipientType: contact.type,
                                );
                                if (convId != null) {
                                  Get.toNamed(
                                    AppRoutes.chatDetails,
                                    arguments: {
                                      'conversationId': convId,
                                      'chatName': contact.name ?? 'Chat',
                                      'partnerCode': contact.bpCode,
                                    },
                                  );
                                }
                              },
                            ),
                            onTap: () async {
                              if (contact.id == null) return;
                              final convId = await ref.read(chatDetailProvider.notifier).startConversation(
                                contact.id!,
                                recipientType: contact.type,
                              );
                              if (convId != null) {
                                Get.toNamed(
                                  AppRoutes.chatDetails,
                                  arguments: {
                                    'conversationId': convId,
                                    'chatName': contact.name ?? 'Chat',
                                    'partnerCode': contact.bpCode,
                                  },
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
    );
  }

  void _openCreateGroupDialog(List<ChatModel> contacts) {
    final nameController = TextEditingController();
    final Set<String> selectedBpCodes = {};
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Create Group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Group Name *',
                      prefixIcon: const Icon(Icons.group),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Members (${selectedBpCodes.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (selectedBpCodes.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setModalState(() => selectedBpCodes.clear());
                          },
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: contacts.isEmpty
                        ? const Center(child: Text('No contacts available'))
                        : ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (ctx, idx) {
                              final c = contacts[idx];
                              final bp = c.bpCode?.trim() ?? '';
                              final isSelected = bp.isNotEmpty && selectedBpCodes.contains(bp);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: AppColor.primary,
                                onChanged: bp.isEmpty
                                    ? null
                                    : (val) {
                                        setModalState(() {
                                          if (val == true) {
                                            selectedBpCodes.add(bp);
                                          } else {
                                            selectedBpCodes.remove(bp);
                                          }
                                        });
                                      },
                                title: Text(
                                  c.name?.isNotEmpty == true ? c.name! : (bp.isNotEmpty ? bp : 'Unknown'),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  bp.isNotEmpty ? 'BP Code: $bp' : (c.mobile ?? 'No BP Code'),
                                  style: TextStyle(
                                    color: bp.isNotEmpty ? Colors.grey.shade600 : Colors.red.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final groupName = nameController.text.trim();
                              if (groupName.isEmpty) {
                                Toaster.showError('Please enter a group name');
                                return;
                              }
                              if (selectedBpCodes.isEmpty) {
                                Toaster.showError('Please select at least one contact');
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final selectedContacts = contacts.where((c) {
                                final bp = c.bpCode?.trim() ?? '';
                                return bp.isNotEmpty && selectedBpCodes.contains(bp);
                              }).toList();

                              final participants = selectedContacts.map((c) {
                                return {
                                  "id": c.id,
                                  "type": (c.type != null && c.type!.isNotEmpty) ? c.type : "buyer",
                                  "bp_code": c.bpCode,
                                };
                              }).toList();

                              final result = await ref.read(chatDetailProvider.notifier).createGroup(
                                name: groupName,
                                bpCodes: selectedBpCodes.toList(),
                                participants: participants,
                              );

                              if (!context.mounted) return;
                              setModalState(() => isSubmitting = false);

                              if (result != null) {
                                Navigator.of(context).pop(); // close bottom sheet
                                final convId = result['conversation_id'];
                                if (convId is int) {
                                  Get.toNamed(
                                    AppRoutes.chatDetails,
                                    arguments: {
                                      'conversationId': convId,
                                      'chatName': groupName,
                                      'partnerCode': selectedBpCodes.first,
                                    },
                                  );
                                } else {
                                  Toaster.showSuccess('Group created successfully');
                                  Get.back(); // return to chat list
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Create Group',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
