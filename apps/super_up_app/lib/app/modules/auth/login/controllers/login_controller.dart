// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:email_validator/email_validator.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/core/app_config/app_config_controller.dart';
import 'package:super_up/app/modules/auth/auth_utils.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';

import '../../../../core/api_service/auth/auth_api_service.dart';
import '../../../../core/api_service/profile/profile_api_service.dart';
import '../../../home/home_controller/views/home_view.dart';
import '../../waiting_list/views/waiting_list_page.dart';

class LoginController implements SBaseController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthApiService authService;
  final ProfileApiService profileService;

  LoginController(
    this.authService,
    this.profileService,
  );

  @override
  onInit() {
    if (kDebugMode) {
      emailController.text = "user1@gmail.com";
      passwordController.text = "12345678";
    }
  }

  void _homeNav(BuildContext context) {
    context.toPage(const HomeView(), removeAll: true, withAnimation: true);
  }

  Future<void> login(BuildContext context) async {
    final email = emailController.text.trim();

    if (!EmailValidator.validate(email)) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).emailNotValid,
        context: context,
      );
      return;
    }
    final password = passwordController.text;

    if (password.isEmpty) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).passwordMustHaveValue,
        context: context,
      );
      return;
    }
    if (_checkIfLoginNoAllowed()) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).loginNowAllowedNowPleaseTryAgainLater,
        context: context,
      );
      return;
    }

    await vSafeApiCall<SMyProfile>(
      onLoading: () async {
        VAppAlert.showLoading(context: context);
      },
      onError: (exception) {
        if (kDebugMode) {
          print('Login error: $exception');
          // Only print stackTrace if it exists
          if (exception is Error) {
            print('StackTrace: ${exception.stackTrace}');
          }
        }
        Navigator.of(context).pop();
        final errEnum = EnumToString.fromString(
          ApiI18nErrorRes.values,
          exception.toString(),
        );
        VAppAlert.showOkAlertDialog(
          context: context,
          title: S.of(context).error,
          content: AuthTrUtils.tr(errEnum) ?? exception.toString(),
        );
      },
      request: () async {
        final deviceHelper = DeviceInfoHelper();
        await authService.login(LoginDto(
          email: email,
          method: RegisterMethod.email,
          pushKey: await (await VChatController
                  .I.vChatConfig.currentPushProviderService)
              ?.getToken(
            VPlatforms.isWeb ? SConstants.webVapidKey : null,
          ),
          deviceInfo: await deviceHelper.getDeviceMapInfo(),
          deviceId: await deviceHelper.getId(),
          language: VLanguageListener.I.appLocal.languageCode,
          platform: VPlatforms.currentPlatform,
          password: password,
        ));
        return profileService.getMyProfile();
      },
      onSuccess: (response) async {
        final status = response.registerStatus;
        await VAppPref.setMap(SStorageKeys.myProfile.name, response.toMap());
        if (status == RegisterStatus.accepted) {
          await VAppPref.setBool(SStorageKeys.isLogin.name, true);
          if (context.mounted) {
            _homeNav(context);
          }
        } else {
          if (context.mounted) {
            context.toPage(
              WaitingListPage(
                profile: response,
              ),
              withAnimation: true,
              removeAll: true,
            );
          }
        }
      },
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
  }

  void facebook() {}

  void apple() {}

  void google() {}

  bool _checkIfLoginNoAllowed() {
    if (VPlatforms.isMobile &&
        !VAppConfigController.appConfig.allowMobileLogin) {
      return true;
    }
    if (VPlatforms.isWeb && !VAppConfigController.appConfig.allowWebLogin) {
      return true;
    }
    if (VPlatforms.isDeskTop &&
        !VAppConfigController.appConfig.allowDesktopLogin) {
      return true;
    }
    return false;
  }
}
