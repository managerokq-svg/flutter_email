// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:email_validator/email_validator.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:super_up/app/modules/auth/waiting_list/views/waiting_list_page.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import 'package:v_platform/v_platform.dart';

import '../../../../core/api_service/auth/auth_api_service.dart';
import '../../../../core/api_service/profile/profile_api_service.dart';
import '../../../../core/app_config/app_config_controller.dart';
import '../../../home/home_controller/views/home_view.dart';
import '../../../home/mobile/settings_tab/views/sheet_for_choose_language.dart';
import '../../auth_utils.dart';

class RegisterController extends SBaseController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final AuthApiService authService;
  final ProfileApiService profileService;

  RegisterController(
    this.authService,
    this.profileService,
  ) : super();

  Future<void> register(BuildContext context) async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    if (name.isEmpty) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).nameMustHaveValue,
        context: context,
      );
      return;
    }
    if (!EmailValidator.validate(email)) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).emailNotValid,
        context: context,
      );
      return;
    }
    final password = passwordController.text;
    final confirm = confirmController.text;

    if (password.isEmpty) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).passwordMustHaveValue,
        context: context,
      );
      return;
    }

    if (password != confirm) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).passwordNotMatch,
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
        final errEnum = EnumToString.fromString(
            ApiI18nErrorRes.values, exception.toString());
        Navigator.of(context).pop();
        VAppAlert.showOkAlertDialog(
          context: context,
          title: S.of(context).error,
          content: AuthTrUtils.tr(errEnum) ?? exception.toString(),
        );
      },
      request: () async {
        final deviceHelper = DeviceInfoHelper();
        await authService.register(RegisterDto(
          email: email,
          method: RegisterMethod.email,
          fullName: name,
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
          _homeNav(context);
        } else {
          context.toPage(
            WaitingListPage(
              profile: response,
            ),
            withAnimation: true,
            removeAll: true,
          );
        }
      },
      config: const VApiConfig(
        ignoreTimeoutErrors: false,
        ignoreNetworkErrors: false,
      ),
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    nameController.dispose();
    confirmController.dispose();
    passwordController.dispose();
  }

  @override
  void onInit() {}

  void _homeNav(BuildContext context) {
    context.toPage(
      const HomeView(),
      withAnimation: true,
      removeAll: true,
    );
  }

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

  void changeLang(BuildContext context) async {
    final res = await showCupertinoModalBottomSheet(
      expand: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const SheetForChooseLanguage(),
    ) as ModelSheetItem?;
    if (res == null) {
      return;
    }

    await VLanguageListener.I.setLocal(Locale(res.id.toString()));
    await VAppPref.setStringKey(
      SStorageKeys.appLanguageTitle.name,
      res.title,
    );
  }

  void changeTheme(BuildContext context) {
    final isDark = context.isDark;

    VThemeListener.I.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
