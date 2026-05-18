import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/login/riverpod/login_notifier.dart';
import 'package:arianth/services/api/notification_service/notifiction_service.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_button.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:arianth/services/localization/app_localization.dart';
import 'package:arianth/services/localization/language_selector.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(loginProvider.notifier);
      await notifier.login(
        _emailController.text.trim(),
        _passwordController.text,
        context,
      );
    }
  }
 @override
  void initState() {
    super.initState();
  Future.microtask(() async {
      await NotificationService.init();
      await SharedPreferencesHelper().init();
      String? deviceToken = await NotificationService.getToken();
      if(deviceToken != null){
        print("--------- DEVICE TOKEN ---------");
        print(deviceToken);
        SharedPreferencesHelper().setString("DToken",deviceToken);
        print("--------------------------------");
      }else{
        print("Device token is null");
      }
  }) ;

  }
  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Header Section (Logo)
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: const BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.rectangle,
                      image: DecorationImage(
                        image: AssetImage('assets/image/tara_text_bg.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),

                // Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.watchTr('login'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColor.textPrimary,
                            fontFamily: 'Times New Roman',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ref.watchTr('login_subtitle'),
                          style: const TextStyle(fontSize: 14, color: AppColor.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // Input Fields
                        CustomInputField(
                          controller: _emailController,
                          labelText: ref.watchTr('mobile_email_hint'),
                          prefixIcon: const Icon(Icons.person_outline, color: AppColor.primary),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),

                        CustomInputField(
                          controller: _passwordController,
                          labelText: ref.watchTr('password'),
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColor.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColor.coolLavender,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          onSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 32),

                        // Action Button
                        CustomButton(
                          text: ref.watchTr('login').toUpperCase(),
                          isLoading: loginState.isLoading,
                          onPressed: _handleLogin,
                          backgroundColor: AppColor.primary,
                          textColor: AppColor.textWhite,
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: AppColor.textSecondary, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => Get.toNamed(AppRoutes.register),
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Center(
                          child: TextButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(Colors.transparent),
                            ),
                            onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                            child: Text(
                              ref.watchTr('forgot_password'),
                                style: const TextStyle(color: AppColor.primary, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Language Switcher Positioned at top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.language, color: AppColor.primary),
              onPressed: () => LanguageSelector.show(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}