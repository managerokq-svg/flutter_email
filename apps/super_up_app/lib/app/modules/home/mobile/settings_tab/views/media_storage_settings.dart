import 'dart:io';
import 'dart:ui';

import 'package:file_sizes/file_sizes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';

class MediaStorageSettings extends StatefulWidget {
  const MediaStorageSettings({super.key});

  @override
  State<MediaStorageSettings> createState() => _MediaStorageSettingsState();
}

class _MediaStorageSettingsState extends State<MediaStorageSettings> {
  final _service = AutoDownloadMediaService();
  int dirSize = -1;
  bool _isClearing = false;

  Future<void> getDirSize() async {
    final dir = Directory(VFileUtils.downloadPath());
    if (!await dir.exists()) {
      dirSize = 0;
      setState(() {});
      return;
    }
    final files = await dir.list(recursive: true).toList();
    dirSize = files.fold(
      0,
      (int sum, file) {
        return sum + file.statSync().size;
      },
    );
    setState(() {});
  }

  @override
  void initState() {
    getDirSize();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFF007AFF);
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStorageCard(isDark, accentColor),
                          const SizedBox(height: 20),
                          _buildAutoDownloadSection(isDark, accentColor),
                          const SizedBox(height: 20),
                          _buildClearCacheCard(isDark),
                          const SizedBox(height: 30),
                        ],
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
          const SizedBox(width: 16),
          Text(
            S.of(context).storageAndData,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(bool isDark, Color accentColor) {
    final sizeText = dirSize < 0 ? '...' : FileSize.getSize(dirSize);
    final maxSize = 1024 * 1024 * 500; // 500 MB for progress visualization
    final progress = dirSize < 0 ? 0.0 : (dirSize / maxSize).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.folder_fill,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context).appStorageSizeIs,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF1A1A2E).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sizeText,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 0.8 ? Colors.orange : accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).chooseHowAutomaticDownloadWorks,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoDownloadSection(bool isDark, Color accentColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                isDark: isDark,
                icon: CupertinoIcons.antenna_radiowaves_left_right,
                iconColor: const Color(0xFFFF9500),
                title: S.of(context).whenUsingMobileData,
                subtitle: _getOptionsText(_service.getMediaDownloadOptionsForData()),
                onTap: () => _onUpdateMobileData(_service.getMediaDownloadOptionsForData()),
                showDivider: true,
              ),
              _buildSettingsTile(
                isDark: isDark,
                icon: CupertinoIcons.wifi,
                iconColor: const Color(0xFF34C759),
                title: S.of(context).whenUsingWifi,
                subtitle: _getOptionsText(_service.getMediaDownloadOptionsForWifi()),
                onTap: () => _onUpdateWifiData(_service.getMediaDownloadOptionsForWifi()),
                showDivider: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: showDivider
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : const Color(0xFF1A1A2E).withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 62,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _buildClearCacheCard(bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isClearing ? null : _onDeleteCache,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isClearing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF3B30)),
                              ),
                            )
                          : const Icon(
                              CupertinoIcons.trash,
                              color: Color(0xFFFF3B30),
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).clearAllCache,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFF3B30),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            S.of(context).clickThisOptionWillClearAppStorage,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : const Color(0xFF1A1A2E).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : const Color(0xFF1A1A2E).withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getOptionsText(List<MediaDownloadOptions> options) {
    if (options.isEmpty) return S.of(context).none;
    return options.map((e) => _getTrans(e)).join(', ');
  }

  String _getTrans(MediaDownloadOptions data) {
    switch (data) {
      case MediaDownloadOptions.images:
        return S.of(context).image;
      case MediaDownloadOptions.videos:
        return S.of(context).video;
      case MediaDownloadOptions.files:
        return S.of(context).files;
    }
  }

  Future _onUpdateMobileData(List<MediaDownloadOptions> mediaDownloadOptionsForData) async {
    final res = await VAppAlert.chooseAlertDialog(
      context: context,
      inChoose: mediaDownloadOptionsForData,
    );
    await _service.updateMediaDownloadOptionsForData(options: res);
    setState(() {});
  }

  Future _onUpdateWifiData(List<MediaDownloadOptions> mediaDownloadOptionsForWifi) async {
    final res = await VAppAlert.chooseAlertDialog(
      context: context,
      inChoose: mediaDownloadOptionsForWifi,
    );
    await _service.updateMediaDownloadOptionsForWifi(options: res);
    setState(() {});
  }

  Future<void> _onDeleteCache() async {
    final res = await VAppAlert.showAskYesNoDialog(
      context: context,
      title: S.of(context).areYouSure,
      content: S.of(context).deleteAppCache,
    );
    if (res != 1) return;
    setState(() => _isClearing = true);
    final dir = Directory(VFileUtils.downloadPath());
    await dir.delete(recursive: true);
    await dir.create(recursive: true);
    await getDirSize();
    setState(() => _isClearing = false);
  }
}
