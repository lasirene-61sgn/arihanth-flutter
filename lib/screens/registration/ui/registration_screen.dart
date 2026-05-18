import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/registration/riverpod/registration_notifier.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _businessNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(registrationProvider.notifier).register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        businessName: _businessNameController.text.trim(),
        city: _cityController.text.trim(),
        stateName: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        address: _addressController.text.trim(),
        gstNo: _gstController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationState = ref.watch(registrationProvider);
    final _isLoading = registrationState.isLoading;
    return Scaffold(
      backgroundColor: AppColor.background,
      body: Stack(
        children: [
          // Brand Pattern Background
          Opacity(
            opacity: 0.03,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/image/tara_text_bg.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top Header with Back Button and Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppColor.primary),
                        onPressed: () => Get.back(),
                      ),
                      Image.asset('assets/image/splash_screen_logo_without_bg.png', height: 40, color: AppColor.primary),
                      const SizedBox(width: 48), // Spacer for balance
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_add_alt_1, size: 30, color: AppColor.primary),
                          ),
                          const SizedBox(height: 20),

              Text(
                'PARTNER REGISTRATION',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textPrimary,
                  fontFamily: 'Times New Roman',
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the Arihanth Jewellers network',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // --- Personal Details Section ---
              _buildSectionHeader('PERSONAL DETAILS'),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _nameController,
                label: 'FULL NAME',
                hint: 'John Doe',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _emailController,
                label: 'EMAIL ADDRESS',
                hint: 'john@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _mobileController,
                label: 'MOBILE NUMBER',
                hint: '+91 98765 43210',
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _passwordController,
                label: 'CREATE PASSWORD',
                hint: 'Minimum 6 characters',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null,
              ),

              const SizedBox(height: 32),

              // --- Business Details Section ---
              _buildSectionHeader('BUSINESS DETAILS'),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _businessNameController,
                label: 'BUSINESS NAME',
                hint: 'Arihanth Gems',
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDarkInputField(
                      controller: _cityController,
                      label: 'CITY',
                      hint: 'Mumbai',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDarkInputField(
                      controller: _pincodeController,
                      label: 'PINCODE',
                      hint: '400001',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _stateController,
                label: 'STATE',
                hint: 'Maharashtra',
              ),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _addressController,
                label: 'ADDRESS',
                hint: 'Street name, Building No',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildDarkInputField(
                controller: _gstController,
                label: 'GST NO (Optional)',
                hint: '22AAAAA0000A1Z5',
              ),

              const SizedBox(height: 48),

              // --- Submit Button ---
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SUBMIT REGISTRATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColor.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDarkInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColor.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColor.textPrimary, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 14),
            filled: true,
            fillColor: AppColor.white,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColor.error, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
