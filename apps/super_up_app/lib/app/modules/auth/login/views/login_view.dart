import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/modules/auth/forget_password_otp/views/forget_password_page.dart';
import 'package:super_up/app/modules/auth/register/views/register_view.dart';
import 'package:super_up_core/super_up_core.dart';
import '../../../../core/api_service/auth/auth_api_service.dart';
import '../../../../core/api_service/profile/profile_api_service.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  LoginViewState createState() => LoginViewState();
}

class LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  late final LoginController controller;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    controller = LoginController(
        GetIt.I.get<AuthApiService>(), GetIt.I.get<ProfileApiService>());
    controller.onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      controller.login(context);
    }
  }

  void _navigateToRegister() => context.toPage(const RegisterView());
  void _navigateToForgotPassword() => context.toPage(ForgetPasswordPage());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF007AFF);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        final formWidth = isLargeScreen ? 420.0 : constraints.maxWidth;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF0A1628),
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                      ]
                    : [
                        const Color(0xFFE8F4FD),
                        const Color(0xFFF0F4F8),
                        const Color(0xFFE1ECF4),
                      ],
              ),
            ),
            child: Stack(
              children: [
                // Decorative blur circles
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
                          accentColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF5856D6).withValues(alpha: isDark ? 0.3 : 0.15),
                          const Color(0xFF5856D6).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: SizedBox(
                          width: formWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLogo(isDark, accentColor),
                              const SizedBox(height: 40),
                              _buildFormCard(context, isDark, accentColor),
                              const SizedBox(height: 24),
                              _buildRegisterLink(isDark, accentColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(bool isDark, Color accentColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset(
            "assets/logo.png",
            height: 60,
            width: 60,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          SConstants.appName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.of(context).welcomeBack,
          style: TextStyle(
            fontSize: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : const Color(0xFF1A1A2E).withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDark, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                STextField(
                  controller: controller.emailController,
                  textHint: S.of(context).enterYourEmail,
                  labelText: S.of(context).email,
                  icon: CupertinoIcons.mail,
                  inputType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).emailRequired;
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return S.of(context).invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                STextField(
                  controller: controller.passwordController,
                  textHint: S.of(context).enterYourPassword,
                  labelText: S.of(context).password,
                  icon: CupertinoIcons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? CupertinoIcons.eye
                          : CupertinoIcons.eye_slash,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).passwordRequired;
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _navigateToForgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      S.of(context).forgotPassword,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLoginButton(accentColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(Color accentColor) {
    return GestureDetector(
      onTap: _handleLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          S.of(context).login,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRegisterLink(bool isDark, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          S.of(context).dontHaveAnAccount,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF1A1A2E).withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: _navigateToRegister,
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 4)),
          child: Text(
            S.of(context).register,
            style: TextStyle(
              color: accentColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
