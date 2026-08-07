import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final ResetPasswordController controller;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    controller = ResetPasswordController(widget.email);
    controller.onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (_formKey.currentState!.validate()) {
      controller.resetPassword(context);
    }
  }

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
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 250,
                    height: 250,
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
                  bottom: -60,
                  left: -60,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF5856D6).withValues(alpha: isDark ? 0.25 : 0.15),
                          const Color(0xFF5856D6).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(isDark),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: SizedBox(
                              width: formWidth,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildHeader(isDark, accentColor),
                                  const SizedBox(height: 32),
                                  _buildFormCard(context, isDark, accentColor),
                                  const SizedBox(height: 24),
                                  _buildResendLink(isDark, accentColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.8),
                ),
              ),
              child: Icon(
                CupertinoIcons.back,
                size: 20,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFF1A1A2E).withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color accentColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
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
          child: const Icon(
            CupertinoIcons.lock_shield,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          S.of(context).resetPassword,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.of(context).enterTheCodeAndNewPassword,
          style: TextStyle(
            fontSize: 15,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : const Color(0xFF1A1A2E).withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, bool isDark, Color accentColor) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: TextStyle(
        fontSize: 20,
        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.8),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: accentColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    );
    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: accentColor),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                Align(
                  alignment: Alignment.center,
                  child: Pinput(
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    length: 6,
                    submittedPinTheme: submittedPinTheme,
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    controller: controller.codeController,
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return S.of(context).pleaseEnterValidCode;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                STextField(
                  controller: controller.newPasswordController,
                  textHint: S.of(context).enterNewPassword,
                  labelText: S.of(context).newPassword,
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
                    if (value.length < 8) {
                      return S.of(context).passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                STextField(
                  controller: controller.confirmPasswordController,
                  textHint: S.of(context).reenterNewPassword,
                  labelText: S.of(context).confirmPassword,
                  icon: CupertinoIcons.lock_shield,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    child: Icon(
                      _obscureConfirmPassword
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
                      return S.of(context).confirmPasswordRequired;
                    }
                    if (value != controller.newPasswordController.text) {
                      return S.of(context).passwordsDontMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: _handleResetPassword,
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
          S.of(context).resetPassword,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildResendLink(bool isDark, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          S.of(context).didntReceiveCode,
          style: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : const Color(0xFF1A1A2E).withValues(alpha: 0.6),
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).codeSentAgain)),
            );
          },
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 4)),
          child: Text(
            S.of(context).resend,
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
