import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/chat/riverpod/chat_notifier.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/screens/login/riverpod/login_notifier.dart';
import 'package:arianth/screens/meetings/riverpod/meetings_notifier.dart';
import 'package:arianth/screens/meetings/model/meeting_participant_model.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:arianth/screens/chat/model/chat_model.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/services/localization/app_localization.dart';

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(meetingsProvider.notifier).fetchMeetings();
      ref.read(chatProvider.notifier).fetchChats();
    });
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meetingsState = ref.watch(meetingsProvider);
    final loginState = ref.watch(loginProvider);
    final role = loginState.user?.role.toLowerCase() ?? SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    final isSuperAdmin = role == 'super_admin';

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          ref.watchTr('meetings'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColor.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Schedule Meeting',
            onPressed: () => _showCreateMeetingBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: meetingsState.isLoading && meetingsState.meetings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : meetingsState.error != null && meetingsState.meetings.isEmpty
                ? Center(child: Text(meetingsState.error!))
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(meetingsProvider.notifier).fetchMeetings();
                    },
                    child: meetingsState.meetings.isEmpty && meetingsState.isLoaded
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.video_call_outlined,
                                      size: 80,
                                      color: AppColor.primary.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Meetings Scheduled',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: 200,
                                      child: CustomButton(
                                        text: 'Schedule Now',
                                        onPressed: () => _showCreateMeetingBottomSheet(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: meetingsState.meetings.length,
                            itemBuilder: (context, index) {
                              final meeting = meetingsState.meetings[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Meeting with ${meeting.host?.fullName ?? "Host"}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColor.primary,
                                              ),
                                            ),
                                          ),
                                          _buildStatusBadge(meeting.status),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDateTime(meeting.scheduledAt),
                                            style: const TextStyle(fontSize: 14, color: AppColor.textSecondary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${meeting.durationMinutes ?? 0} Minutes',
                                            style: const TextStyle(fontSize: 14, color: AppColor.textSecondary),
                                          ),
                                        ],
                                      ),
                                      if (meeting.status?.toLowerCase() == 'pending') ...[
                                        if (isSuperAdmin) ...[
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (meetingsState.approvingMeetingId != null || meetingsState.cancellingMeetingId != null) return;
                                                    ref.read(meetingsProvider.notifier).approveMeeting(meeting.id!);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: meetingsState.approvingMeetingId == meeting.id.toString() 
                                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                                      : const Text('APPROVE'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (meetingsState.approvingMeetingId != null || meetingsState.cancellingMeetingId != null) return;
                                                    ref.read(meetingsProvider.notifier).rejectMeeting(meeting.id!);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: meetingsState.cancellingMeetingId == meeting.id.toString() 
                                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                                      : const Text('CANCEL'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ] else if (meeting.status?.toLowerCase() == 'approved' || meeting.status?.toLowerCase() == 'started') ...[
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              if (meetingsState.joiningRoomId != null) return;
                                              ref.read(meetingsProvider.notifier).joinMeeting(meeting.roomId!, opponentName: meeting.host?.fullName, meetingId: meeting.id);
                                            },
                                            icon: meetingsState.joiningRoomId == meeting.roomId ? const SizedBox.shrink() : const Icon(Icons.videocam_outlined),
                                            label: meetingsState.joiningRoomId == meeting.roomId 
                                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                                : const Text('JOIN MEETING'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColor.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
    );
  }

  void _showCreateMeetingBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateMeetingForm(),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color bgColor;
    Color textColor;
    
    switch (status?.toLowerCase()) {
      case 'approved':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      case 'started':
        bgColor = AppColor.primary.withOpacity(0.1);
        textColor = AppColor.primary;
        break;
      case 'ended':
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class CreateMeetingForm extends ConsumerStatefulWidget {
  const CreateMeetingForm({super.key});

  @override
  ConsumerState<CreateMeetingForm> createState() => _CreateMeetingFormState();
}

class _CreateMeetingFormState extends ConsumerState<CreateMeetingForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime = TimeOfDay.now();
  final _durationController = TextEditingController(text: '30');

  final List<String> _selectedRoles = [];
  MeetingParticipantModel? _selectedParticipant;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(meetingsProvider.notifier).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final meetingsState = ref.watch(meetingsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule Meeting',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Role Selection (Checkboxes)
              const Text('Select Role', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              meetingsState.isLoadingCategories
                  ? const SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: meetingsState.categories.map((role) {
                        final isChecked = _selectedRoles.contains(role);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: isChecked,
                              activeColor: AppColor.primary,
                              onChanged: (bool? val) {
                                setState(() {
                                  _selectedRoles.clear();
                                  if (val == true) {
                                    _selectedRoles.add(role);
                                  }
                                  _selectedParticipant = null;
                                });
                                ref.read(meetingsProvider.notifier).fetchParticipantsForRoles(_selectedRoles);
                              },
                            ),
                            Text(
                              role.toUpperCase(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),

              // Participant Dropdown
              if (_selectedRoles.isNotEmpty) ...[
                const Text('Select Participant', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                meetingsState.isLoadingParticipants
                    ? const SizedBox(
                        height: 40,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Loading participants...",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : WorkOrderDropdownWidget<MeetingParticipantModel>(
                        label: 'Participant',
                        fieldKeyName: 'participant_id',
                        items: meetingsState.participants,
                        itemLabel: (part) => part.fullName.isEmpty
                            ? "${part.userCode} [${part.category ?? 'N/A'}]"
                            : "${part.fullName} (${part.userCode}) [${part.category ?? 'N/A'}]",
                        selectedItemLabel: (part) => part.fullName.isEmpty
                            ? part.userCode
                            : "${part.fullName} (${part.userCode})",
                        value: _selectedParticipant,
                        isSearchable: true,
                        hintText: 'Select Participant',
                        isLoading: meetingsState.isLoadingParticipants,
                        onChanged: (MeetingParticipantModel? val) => setState(() => _selectedParticipant = val),
                      ),
                const SizedBox(height: 20),
              ],

              // Date Picker
              const Text('Scheduled At', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(_selectedDate == null 
                                ? 'Select Date' 
                                : DateFormat('dd-MM-yyyy').format(_selectedDate!)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 8),
                            Text(_selectedTime == null 
                                ? 'Select Time' 
                                : _selectedTime!.format(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Duration
              _input('Duration (minutes)', _durationController, type: TextInputType.number),
              const SizedBox(height: 32),

              CustomButton(
                text: meetingsState.isSaving ? 'Wait...' : 'SCHEDULE MEETING',
                onPressed: meetingsState.isSaving ? null : _submit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        CustomInputField(
          controller: controller,
          keyboardType: type,
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParticipant == null) {
      Toaster.showError('Please select a participant');
      return;
    }

    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final data = {
      'participant_id': _selectedParticipant?.userCode,
      'scheduled_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(scheduledAt),
      'duration_minutes': int.tryParse(_durationController.text) ?? 30,
    };

    await ref.read(meetingsProvider.notifier).saveMeeting(data);
  }
}
