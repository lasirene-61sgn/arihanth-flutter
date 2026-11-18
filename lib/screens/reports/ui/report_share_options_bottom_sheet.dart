import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/dashboard_screen/riverpod/dashboard_notifier.dart';
import 'package:arianth/screens/chat/riverpod/chat_detail_notifier.dart';
import 'package:arianth/screens/chat/model/chat_model.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/universal_share_bottom_sheet.dart';
import 'package:arianth/services/widget/custom_msg.dart';

class ReportShareOptionsBottomSheet extends ConsumerStatefulWidget {
  final File file;
  final String title;
  final String subject;

  const ReportShareOptionsBottomSheet({
    super.key,
    required this.file,
    required this.title,
    required this.subject,
  });

  static Future<void> show({
    required BuildContext context,
    required File file,
    required String title,
    String? subject,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReportShareOptionsBottomSheet(
        file: file,
        title: title,
        subject: subject ?? title,
      ),
    );
  }

  @override
  ConsumerState<ReportShareOptionsBottomSheet> createState() =>
      _ReportShareOptionsBottomSheetState();
}

class _ReportShareOptionsBottomSheetState
    extends ConsumerState<ReportShareOptionsBottomSheet> {
  bool _isLoading = true;
  double _progress = 0.1;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isSending = false;
  String _sendActionText = '';

  @override
  void initState() {
    super.initState();
    _startSimulatedLoading();
  }

  void _startSimulatedLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        _progress += 0.3;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _isLoading = false;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _shareToWhatsApp() async {
    Navigator.of(context).pop();
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.file.path, mimeType: 'image/png')],
          subject: widget.subject,
        ),
      );
    } catch (e) {
      debugPrint("Error sharing report via WhatsApp: $e");
      Toaster.showError("Failed to share report");
    }
  }

  Future<void> _openChatPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => UniversalChatRecipientPicker(
        onRecipientSelected: (chat) async {
          Navigator.of(sheetContext).pop();
          await _sendToConversation(chat);
        },
      ),
    );
  }

  Future<void> _sendToConversation(ChatModel chat) async {
    setState(() {
      _isSending = true;
      _sendActionText = 'Connecting with ${chat.name ?? 'user'}...';
    });

    try {
      int? convId = chat.conversationId;
      if (convId == null && chat.isGroup && chat.id != null) {
        convId = chat.id;
      } else if (convId == null && chat.id != null) {
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

      setState(() {
        _sendActionText = 'Sending report to chat...';
      });

      final chatNotifier = ref.read(chatDetailProvider.notifier);
      await chatNotifier.fetchMessages(convId, isSilent: true);

      final caption = "Report: ${widget.title}";

      await chatNotifier.sendAttachment(
        filePath: widget.file.path,
        fileName: widget.file.path.split('/').last,
        caption: caption,
      );

      Toaster.showSuccess("Report shared to ${chat.name ?? 'Chat'} successfully!");
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error sending report to chat: $e");
      Toaster.showError("Failed to send report to chat");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final String? role = SharedPreferencesHelper().getString('role');
    final prefsPermissionsRaw = SharedPreferencesHelper().getString('permissions');

    List<String> cachedPermissions = [];
    if (prefsPermissionsRaw != null && prefsPermissionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(prefsPermissionsRaw);
        if (decoded is List) {
          cachedPermissions = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    final permissions = dashboardState.dashboardData?.permissions ?? cachedPermissions;
    final bool isSuperAdmin = role?.toLowerCase() == 'super_admin';
    final bool canShareToChat = isSuperAdmin || permissions.contains('chat');

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
            // Pill indicator
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Select how you want to share this report",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Sending State
            if (_isSending) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColor.primary, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text(
                      _sendActionText.isNotEmpty ? _sendActionText : 'Processing...',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ]
            // 2. Loading / Preparing State (shows first before share options)
            else if (_isLoading) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Single item preview with spinner / hourglass icon
                    Row(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade200,
                                child: Image.file(
                                  widget.file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.description_outlined,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.hourglass_bottom,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "#1",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Badges: Finished, Pending, Time
                    Row(
                      children: [
                        // Finished badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                "Finished: 0",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Pending badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade300, width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pending_actions, size: 12, color: Colors.orange),
                              SizedBox(width: 4),
                              Text(
                                "Pending: 1",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Elapsed Time
                        Text(
                          "Time: ${_elapsedSeconds}s",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Progress bar & live status
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Initializing share card...",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "${(_progress * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]
            // 3. Loaded State - Show Share via WhatsApp & In-App Chat
            else ...[
              // Option 1: WhatsApp / External Apps
              _ShareReportOptionTile(
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

              // Option 2: In-App Chat (permission based)
              if (canShareToChat) ...[
                const SizedBox(height: 12),
                _ShareReportOptionTile(
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
                  subtitle: "Send report card directly into in-app chat",
                  onTap: _openChatPicker,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareReportOptionTile extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareReportOptionTile({
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

