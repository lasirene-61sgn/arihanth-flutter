import 'package:arianth/screens/key_user/riverpod/key_user_notifier.dart';
import 'package:arianth/screens/user/riverpod/user_notifier.dart';
import 'package:arianth/services/widget/reusable_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UserDetailsViewScreen extends ConsumerStatefulWidget {
  final String screenName;
  const UserDetailsViewScreen({super.key, this.screenName = ''});

  @override
  ConsumerState<UserDetailsViewScreen> createState() => _UserDetailsViewScreenState();
}

class _UserDetailsViewScreenState extends ConsumerState<UserDetailsViewScreen> {
  // State variables to hold user details
  String _email = '';
  String _userCode = '';
  String _aadharNumber = '';
  String _name = '';
  String _mobileNo = '';
  String? _dob;
  String _bpCode = '';
  String aadharImage = '';
  String photoImage = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchUserDetails();
    });
  }

  void _fetchUserDetails() {
    final keyUserState = ref.read(keyUserProvider);
    final userState = ref.read(userProvider);

    dynamic source;

    if (widget.screenName == "Users") {
      source = userState.userDetail;
      if (kDebugMode) {
        print("Fetching user details: $source");
      }
    } else {
      source = keyUserState.keyUserDetail; // default
    }

    if (source != null) {
      setState(() {
        _email = source.emailId ?? '';
        _userCode = source.userCode ?? '';
        _aadharNumber = source.aadharNumber ?? '';
        _name = source.fullName ?? '';
        _mobileNo = source.mobileNo ?? '';
        // Handle DOB parsing
        try {
          _dob = source.dob != null && source.dob!.isNotEmpty
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(source.dob!))
              : 'Not Set';
        } catch (e) {
          _dob = source.dob ?? 'Not Set';
        }
        _bpCode = source.bpCode ?? '';
        aadharImage = source.aadharPhoto ?? '';
        photoImage = source.profilePicture ?? '';
      });
    }
  }

  // Helper method to generate the sections for ReusableDetailView
  List<DetailSection> _buildSections() {
    if (_name.isEmpty && _userCode.isEmpty && _email.isEmpty) {
      return [];
    }

    return [
      DetailSection(
        items: [
          DetailItem(label: 'Full Name', value: _name),
          DetailItem(label: 'User Code', value: _userCode, copyable: true),
          DetailItem(label: 'BP Code', value: _bpCode, copyable: true),
          DetailItem(label: 'Role/Screen', value: widget.screenName),

          DetailItem(label: 'Mobile Number', value: _mobileNo, copyable: true),
          DetailItem(label: 'Email Address', value: _email, copyable: true),
          // DetailItem(label: 'Date of Birth', value: _dob),
          DetailItem(label: 'Aadhar Number', value: _aadharNumber, copyable: true),
          if (aadharImage.isNotEmpty) DetailItem(
            label: 'Aadhar Image',
            value: null,
            imageUrl: aadharImage,
            imageSize: 140,
          ),
          if (photoImage.isNotEmpty) DetailItem(
            label: 'Image',
            value: null,
            imageUrl: photoImage,
            imageSize: 140,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    String title = '${widget.screenName == "Users" ? "User" : "Key User"} Details';

    return ReusableDetailView(
      title: title,
      onBackPressed: () => Navigator.pop(context),
      sections: _buildSections(),
    );
  }
}