import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/screens/login/riverpod/forgot_password_notifier.dart';

/// Forgot Password screen — 3-step flow:
///   Step 0  →  Enter email / mobile  →  sends OTP
///   Step 1  →  Enter OTP (4 boxes)
///   Step 2  →  Enter new password + confirm
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _emailCtrl = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // ── State ───────────────────────────────────────────────────────────────────
  int _step = 0; // 0 = email, 1 = OTP, 2 = new password
  bool get _isLoading => ref.watch(forgotPasswordProvider).isLoading;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  int _resendSeconds = 0;
  String _selectedMethod = 'email';

  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Step labels ─────────────────────────────────────────────────────────────
  List<String> get _stepLabels => [
        _selectedMethod == 'email' ? 'Email' : 'Phone',
        'OTP',
        'New Password'
      ];

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _goTo(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  String get _otpValue =>
      _otpControllers.map((c) => c.text).join();

  void _startResendTimer() {
    setState(() => _resendSeconds = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  // ── API Calls ────────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      Toaster.showError('Please enter your email or mobile');
      return;
    }
    
    final success = await ref.read(forgotPasswordProvider.notifier).sendOtp(
      identifier: email,
      method: _selectedMethod,
    );
    
    if (success) {
      _startResendTimer();
      _goTo(1);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length < 6) {
      Toaster.showError('Enter the complete 6-digit OTP');
      return;
    }
    
    final success = await ref.read(forgotPasswordProvider.notifier).verifyOtp(
      identifier: _emailCtrl.text.trim(),
      otp: otp,
    );
    
    if (success) {
      _goTo(2);
    }
  }

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;
    if (newPass.isEmpty || confirm.isEmpty) {
      Toaster.showError('Please fill all fields');
      return;
    }
    if (newPass != confirm) {
      Toaster.showError('Passwords do not match');
      return;
    }
    if (newPass.length < 6) {
      Toaster.showError('Password must be at least 6 characters');
      return;
    }
    
    final success = await ref.read(forgotPasswordProvider.notifier).resetPassword(
      identifier: _emailCtrl.text.trim(),
      otp: _otpValue,
      newPassword: newPass,
      confirmPassword: confirm,
    );
    
    if (success) {
      Get.back();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColor.white, size: 18),
          onPressed: () => _step == 0 ? Get.back() : _goTo(_step - 1),
        ),
        title: Text(
          ref.watchTr('forgot_password'),
          style: const TextStyle(
              color: AppColor.white,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
              height: 1, color: AppColor.coolLavender.withOpacity(0.2)),
        ),
      ),
      body: Column(
        children: [
          // ── Step Indicator ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: Row(
              children: List.generate(_stepLabels.length, (i) {
                final isDone = i < _step;
                final isActive = i == _step;
                return Expanded(
                  child: Row(
                    children: [
                      // Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColor.primary
                              : isActive
                                  ? AppColor.primary.withOpacity(0.15)
                                  : AppColor.surface,
                          border: Border.all(
                            color: (isDone || isActive)
                                ? AppColor.primary
                                : AppColor.border,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check,
                                  size: 14, color: AppColor.textWhite)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? AppColor.primary
                                        : AppColor.textSecondary,
                                  )),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Label
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stepLabels[i],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: (isDone || isActive)
                                    ? AppColor.primary
                                    : AppColor.textSecondary,
                              ),
                            ),
                            // connector line (not after last)
                            if (i < _stepLabels.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: 2,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? AppColor.primary
                                        : AppColor.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── Page content ────────────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildEmailStep(),
                _buildOtpStep(),
                _buildPasswordStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Email/Mobile ─────────────────────────────────────────────────────
  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(Icons.lock_reset_rounded),
          const SizedBox(height: 24),
          const Text('Reset Password',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColor.textPrimary)),
          const SizedBox(height: 8),
          const Text('Enter your registered email or mobile number.\nWe\'ll send you an OTP.',
              style: TextStyle(
                  fontSize: 14, color: AppColor.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          CustomInputField(
            controller: _emailCtrl,
            labelText: _selectedMethod == 'email' ? 'Email' : 'Mobile Number',
            keyboardType: _selectedMethod == 'email' ? TextInputType.emailAddress : TextInputType.phone,
            prefixIcon: Icon(
              _selectedMethod == 'email' ? Icons.email_outlined : Icons.phone_android_outlined,
              color: AppColor.primary,
            ),
          ),
          const SizedBox(height: 16),
          // Dropdown for Method
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColor.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMethod,
                isExpanded: true,
                dropdownColor: AppColor.surface,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColor.textSecondary),
                items: const [
                  DropdownMenuItem(value: 'email', child: Text('Send OTP to Email', style: TextStyle(color: AppColor.textPrimary, fontSize: 13))),
                  DropdownMenuItem(value: 'sms', child: Text('Send OTP to Mobile (SMS)', style: TextStyle(color: AppColor.textPrimary, fontSize: 13))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMethod = val;
                      _emailCtrl.clear();
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          CustomButton(
            text: 'SEND OTP',
            isLoading: _isLoading,
            onPressed: _sendOtp,
            backgroundColor: AppColor.primary,
            textColor: AppColor.textWhite,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () => Get.back(),
              child: const Text('Back to Login',
                  style:
                      TextStyle(color: AppColor.primary, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: OTP Input ────────────────────────────────────────────────────────
  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(Icons.verified_outlined),
          const SizedBox(height: 24),
          const Text('Enter OTP',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColor.white)),
          const SizedBox(height: 8),
          Text('A 6-digit OTP was sent to ${_emailCtrl.text.trim()}',
              style: const TextStyle(
                  fontSize: 15, color: AppColor.primary, height: 1.5)),
          const SizedBox(height: 32),

          // 6-digit OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _buildOtpBox(i)),
          ),

          const SizedBox(height: 20),

          // Resend row
          Center(
            child: _resendSeconds > 0
                ? Text(
                    'Resend OTP in ${_resendSeconds}s',
                    style: const TextStyle(
                        color: AppColor.primary, fontSize: 13),
                  )
                : TextButton.icon(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
                    icon: const Icon(Icons.refresh,
                        size: 15, color: AppColor.primary),
                    label: const Text('Resend OTP',
                        style: TextStyle(
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600)),
                    onPressed: _sendOtp,
                  ),
          ),

          const SizedBox(height: 28),
          CustomButton(
            text: 'VERIFY OTP',
            isLoading: _isLoading,
            onPressed: _verifyOtp,
            backgroundColor: AppColor.primary,
            textColor: AppColor.textWhite,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
              ),
              onPressed: () => _goTo(0),
              child: const Text('Change Email / Mobile',
                  style:
                      TextStyle(color: AppColor.primary, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int i) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextFormField(
        controller: _otpControllers[i],
        focusNode: _focusNodes[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColor.black),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColor.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppColor.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColor.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            // Handle paste
            final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
            for (var j = 0; j < 6; j++) {
              _otpControllers[j].text =
                  j < digits.length ? digits[j] : '';
            }
            _focusNodes[digits.length.clamp(0, 5)].requestFocus();
            setState(() {});
            return;
          }
          setState(() {});
          if (value.isNotEmpty && i + 1 < 6) {
            _focusNodes[i + 1].requestFocus();
          } else if (value.isEmpty && i > 0) {
            _focusNodes[i - 1].requestFocus();
          }
        },
      ),
    );
  }

  // ── Step 2: New Password ─────────────────────────────────────────────────────
  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(Icons.lock_outline_rounded),
          const SizedBox(height: 24),
          const Text('Set New Password',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColor.primary)),
          const SizedBox(height: 8),
          const Text('Choose a strong new password for your account.',
              style: TextStyle(
                  fontSize: 13, color: AppColor.primary, height: 1.5)),
          const SizedBox(height: 32),

          CustomInputField(
            controller: _newPassCtrl,
            labelText: 'New Password',
            obscureText: _obscureNew,
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppColor.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: AppColor.coolLavender,
              ),
              onPressed: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 20),

          CustomInputField(
            controller: _confirmPassCtrl,
            labelText: 'Confirm Password',
            obscureText: _obscureConfirm,
            prefixIcon: const Icon(Icons.lock_outline,
                color: AppColor.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: AppColor.coolLavender,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 28),

          CustomButton(
            text: 'RESET PASSWORD',
            isLoading: _isLoading,
            onPressed: _resetPassword,
            backgroundColor: AppColor.primary,
            textColor: AppColor.textWhite,
          ),
        ],
      ),
    );
  }

  // ── Shared header icon ───────────────────────────────────────────────────────
  Widget _buildIcon(IconData icon) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColor.primary.withOpacity(0.3), width: 1.5),
      ),
      child: Icon(icon, color: AppColor.primary, size: 32),
    );
  }
}