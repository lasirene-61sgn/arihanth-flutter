import 'package:arianth/screens/key_user/riverpod/key_user_notifier.dart';
import 'package:arianth/screens/craftsman_staff/riverpod/craftsman_staff_notifier.dart';
import 'package:arianth/services/widget/reusable_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/localization/app_localization.dart';

class CraftsmanStaffDetailsViewScreen extends ConsumerStatefulWidget {
  final String screenName;
  const CraftsmanStaffDetailsViewScreen({super.key, this.screenName = ''});

  @override
  ConsumerState<CraftsmanStaffDetailsViewScreen> createState() => _CraftsmanStaffDetailsViewScreenState();
}

class _CraftsmanStaffDetailsViewScreenState extends ConsumerState<CraftsmanStaffDetailsViewScreen> {
  // State variables to hold craftsman_staff details
  String _email = '';
  String _craftsman_staffCode = '';
  String _aadharNumber = '';
  String _name = '';
  String _mobileNo = '';
  String _bpCode = '';
  String aadharImage = '';
  String photoImage = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchCraftsmanStaffDetails();
    });
  }

  void _fetchCraftsmanStaffDetails() {
    final craftsman_staffState = ref.read(craftsmanStaffProvider);
    dynamic source = craftsman_staffState.craftsman_staffDetail;

    if (source != null) {
      setState(() {
        _email = source.email ?? '';
        _craftsman_staffCode = source.staffCode ?? '';
        _aadharNumber = source.aadharNumber ?? '';
        _name = source.name ?? '';
        _mobileNo = source.mobileNo ?? '';
        _bpCode = source.craftsman?.craftmanCode ?? '';
        aadharImage = source.aadharImage ?? '';
        photoImage = source.image ?? '';
      });
    }
  }

  // Helper method to generate the sections for ReusableDetailView
  List<DetailSection> _buildSections() {
    if (_name.isEmpty && _craftsman_staffCode.isEmpty && _email.isEmpty) {
      return [];
    }

    return [
      DetailSection(
        items: [
          DetailItem(label: ref.watchTr('Full Name'), value: _name),
          DetailItem(label: ref.watchTr('CraftsmanStaff Code'), value: _craftsman_staffCode, copyable: true),
          DetailItem(label: ref.watchTr('Craftsman Code'), value: _bpCode, copyable: true),
          DetailItem(label: ref.watchTr('Role/Screen'), value: widget.screenName),

          DetailItem(label: ref.watchTr('Mobile Number'), value: _mobileNo, copyable: true),
          DetailItem(label: ref.watchTr('Email Address'), value: _email, copyable: true),
          DetailItem(label: ref.watchTr('Aadhar Number'), value: _aadharNumber, copyable: true),
          if (aadharImage.isNotEmpty) DetailItem(
            label: ref.watchTr('Aadhar Image'),
            value: null,
            imageUrl: aadharImage,
            imageSize: 140,
          ),
          if (photoImage.isNotEmpty) DetailItem(
            label: ref.watchTr('Image'),
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
    String title = '${ref.watchTr(widget.screenName == "CraftsmanStaff" ? "CraftsmanStaff" : "Key CraftsmanStaff")} ${ref.watchTr("Details")}';

    return ReusableDetailView(
      title: title,
      onBackPressed: () => Navigator.pop(context),
      sections: _buildSections(),
    );
  }
}