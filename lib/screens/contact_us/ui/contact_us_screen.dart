import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/contact_us/model/contact_model.dart';
import 'package:arianth/screens/contact_us/riverpod/contact_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(contactProvider.notifier).fetchContacts());
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar("Error", "Could not launch $url", snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Contact Us", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Arihanth Jewellers Pvt Ltd", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : state.error != null && state.contacts == null
              ? _buildError(state.error!)
              : _buildBody(state.contacts),
    );
  }

  Widget _buildError(String error) {
    // Ignore the actual error, just show friendly message
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Contact details are currently unavailable. Please check back later.",
          style: const TextStyle(
            color: AppColor.textHint,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBody(CompanyContacts? contacts) {
    final mobile = contacts?.mobile ?? [];
    final centrix = contacts?.centrix ?? [];
    final bank = contacts?.bank ?? [];
    final location = contacts?.location ?? [];
    final cin = contacts?.cin ?? [];
    final gst = contacts?.gst ?? [];
    final hallmark = contacts?.hallmark ?? [];
    final email = contacts?.email ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Location or static fallback
            if( location.isNotEmpty)  ...[
              _buildHeader("OFFICE ADDRESS", Icons.location_on),
              _buildInfoListCard(location),
              const SizedBox(height: 24),
            ],


            // Dynamic Mobile Numbers
            if (mobile.isNotEmpty) ...[
              _buildHeader("GENERAL HELPLINE", Icons.call),
              _buildMobileCard(mobile, centrix),
              const SizedBox(height: 24),
            ],

            // Email Section
            if (email.isNotEmpty) ...[
              _buildHeader("EMAIL ADDRESS", Icons.email_outlined),
              _buildSimpleInfoCard(email),
              const SizedBox(height: 24),
            ],

            // CIN
            if (cin.isNotEmpty) ...[
              _buildHeader("CIN NUMBER", Icons.numbers),
              _buildSimpleInfoCard(cin),
              const SizedBox(height: 24),
            ],

            // GST
            if (gst.isNotEmpty) ...[
              _buildHeader("GST NUMBER", Icons.receipt_long),
              _buildSimpleInfoCard(gst),
              const SizedBox(height: 24),
            ],

            // Hallmark
            if (hallmark.isNotEmpty) ...[
              _buildHeader("HALLMARK ID", Icons.verified_outlined),
              _buildSimpleInfoCard(hallmark),
              const SizedBox(height: 24),
            ],

            // Dynamic Bank Details
            if (bank.isNotEmpty) ...[
              _buildOfficialBankDetails(bank),
              const SizedBox(height: 24),
            ],

            const Center(
              child: Text(
                "PLEASE VERIFY ALL DETAILS BEFORE INITIATING BANK TRANSFERS",
                style: TextStyle(color: AppColor.textHint, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "EXCELLENCE IN GOLD SINCE GENERATIONS",
                style: TextStyle(color: AppColor.textHint, fontSize: 12, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColor.primary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColor.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildAddressCard() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColor.divider),
  //     ),
  //     child: const Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text("Arihanth Jewellers Pvt Ltd", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  //         SizedBox(height: 8),
  //         Text(
  //           "7th Floor, Prashanth Gold, 1/21,\n(39-40/21), North Usman Road,\nT.Nagar, Chennai - 600017.",
  //           style: TextStyle(color: AppColor.textSecondary, fontSize: 12, height: 1.5),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Shows a list of plain text values in a card (used for location fallback)
  Widget _buildInfoListCard(List<String> values) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values
            .map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(v, style: const TextStyle(fontSize: 13, color: AppColor.textPrimary, height: 1.5)),
                ))
            .toList(),
      ),
    );
  }

  // Shows a list of values as selectable/copyable rows (cin, gst, hallmark)
  Widget _buildSimpleInfoCard(List<String> values) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: values
            .map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SelectableText(
                    v,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.textPrimary, letterSpacing: 0.5),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMobileCard(List<String> mobile, List<String> centrix) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...mobile.asMap().entries.map((entry) {
            final number = entry.value;
            return Column(
              children: [
                if (entry.key > 0) const SizedBox(height: 12),
                _buildHelplineItem(number),
              ],
            );
          }),
          if (centrix.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Text("CENTRAX:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(
                  centrix.where((v) => v.isNotEmpty).join(' / '),
                  style: const TextStyle(fontSize: 10, color: AppColor.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelplineItem(String number) {
    return InkWell(
      onTap: () => _launchUrl('tel:${number.replaceAll(' ', '')}'),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.phone_android, size: 14, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(number, style: const TextStyle(fontSize: 13, color: AppColor.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialBankDetails(List<ContactInfo> banks) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance, size: 16, color: AppColor.primary),
            const SizedBox(width: 8),
            const Text("OFFICIAL BANK DETAILS", style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 16),
        ...banks.map((bank) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.divider),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Image.asset("assets/image/bank_image.png", height: 60, fit: BoxFit.contain),
                const SizedBox(height: 10),
                if (bank.accountHolderName != null && bank.accountHolderName!.isNotEmpty)
                  _buildBankRow("NAME", bank.accountHolderName!),
                if (bank.accountNumber != null && bank.accountNumber!.isNotEmpty)
                  _buildBankRow("A/C NO.", bank.accountNumber!),
                if (bank.ifscCode != null && bank.ifscCode!.isNotEmpty)
                  _buildBankRow("IFSC CODE", bank.ifscCode!),
                if (bank.branch != null && bank.branch!.isNotEmpty)
                  _buildBankRow("BRANCH", bank.branch!),
                if (bank.bankName != null && bank.bankName!.isNotEmpty)
                  _buildBankRow("BANK", bank.bankName!),
                if (bank.bankCity != null && bank.bankCity!.isNotEmpty)
                  _buildBankRow("CITY", bank.bankCity!),
                if (bank.bankState != null && bank.bankState!.isNotEmpty)
                  _buildBankRow("STATE", bank.bankState!),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildBankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColor.textPrimary))),
          const Text(" :  ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColor.textPrimary))),
        ],
      ),
    );
  }
}
