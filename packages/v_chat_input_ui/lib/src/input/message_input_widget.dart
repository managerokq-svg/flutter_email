// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:place_picker_google/place_picker_google.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v_chat_input_ui/src/input/widgets/emoji_keyborad.dart';
import 'package:v_chat_input_ui/src/input/widgets/gif_picker.dart';
import 'package:v_chat_input_ui/src/input/widgets/link_preview_loader.dart';
import 'package:v_chat_input_ui/src/input/widgets/message_send_btn.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_record_button.dart';
import 'package:v_chat_input_ui/src/input/widgets/message_text_filed.dart';
import 'package:v_chat_input_ui/src/input/widgets/sticker_picker.dart';
import 'package:v_chat_input_ui/src/input/widgets/contact_picker_page.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_glass_container.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_mention_list.dart';
import 'package:v_chat_input_ui/src/v_widgets/extension.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:v_chat_mention_controller/v_chat_mention_controller.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';
import '../../v_chat_input_ui.dart';
import '../enums.dart';
import '../models/link_preview_data.dart';
import '../models/location_message_data.dart';
import '../models/message_voice_data.dart';
import '../permission_manager.dart';
import '../recorder/record_widget.dart';
import '../v_widgets/app_pick.dart';
import '../v_widgets/v_app_alert.dart';

/// Controller for managing the emoji keyboard state
class VMessageInputController extends ChangeNotifier {
  bool _isEmojiShowing = false;
  bool get isEmojiShowing => _isEmojiShowing;
  void setEmojiShowing(bool value) {
    if (_isEmojiShowing != value) {
      _isEmojiShowing = value;
      notifyListeners();
    }
  }
  void closeEmoji() {
    if (_isEmojiShowing) {
      _isEmojiShowing = false;
      notifyListeners();
    }
  }
  void toggleEmoji() {
    _isEmojiShowing = !_isEmojiShowing;
    notifyListeners();
  }
  /// Returns true if emoji was open and closed, false if emoji was already closed
  bool closeEmojiIfOpen() {
    if (_isEmojiShowing) {
      closeEmoji();
      return true;
    }
    return false;
  }
}

///this widget used to render the footer of messages page
class VMessageInputWidget extends StatefulWidget {
  ///callback when user send text
  final Function(String message, VLinkPreviewData? previewData) onSubmitText;
  ///callback when user send images or videos or mixed
  final Function(List<VPlatformFile> files) onSubmitMedia;
  ///callback when user send files
  final Function(List<VPlatformFile> files) onSubmitFiles;
  ///callback when user send location will call only if [googleMapsApiKey] has value
  final Function(LocationMessageData data) onSubmitLocation;
  ///callback when user submit voice
  final Function(MessageVoiceData data) onSubmitVoice;
  ///callback when user start typing or recording or stop
  final Function(RoomTypingEnum typing) onTypingChange;
  ///callback when user selects a sticker
  final Function(Map<String, dynamic> sticker)? onSubmitSticker;
  ///callback when user selects a GIF
  final Function(Map<String, dynamic> gif)? onSubmitGif;
  ///callback when user selects contacts (mobile only)
  final Function(VContactMessageData data)? onSubmitContacts;
  ///callback when user clicked send attachment
  final Future<AttachEnumRes?> Function()? onAttachIconPress;
  ///callback if you want to implement custom mention item builder
  final Widget Function(MentionModel)? mentionItemBuilder;
  ///callback when user start add '@' or '@...' if text is empty that means the user just start type '@'
  final Future<List<MentionModel>> Function(String)? onMentionSearch;
  /// widget to render if user select to reply
  final Widget? replyWidget;
  /// should be true in web to let user directly start chat
  final bool autofocus;
  /// widget to render if the chat has been closed my be this user leave group or has banned!
  final Widget? stopChatWidget;
  /// set max timeout for recording
  final Duration maxRecordTime;
  ///set text filed focusNode
  final FocusNode? focusNode;
  ///if not provided the the user cant see the option of send location
  final String? googleMapsApiKey;
  ///text-field hint
  final VInputLanguage language;
  ///google maps localizations
  final String googleMapsLangKey;
  final String roomId;
  final bool isAllowSendMedia;
  ///set max upload files size default it 50 mb
  final int maxMediaSize;
  ///controller to manage emoji keyboard state from parent
  final VMessageInputController? controller;

  const VMessageInputWidget({
    super.key,
    required this.onSubmitText,
    required this.onSubmitMedia,
    required this.isAllowSendMedia,
    required this.roomId,
    required this.onSubmitVoice,
    required this.onSubmitFiles,
    required this.onSubmitLocation,
    required this.onTypingChange,
    this.onSubmitSticker,
    this.onSubmitGif,
    this.onSubmitContacts,
    this.maxMediaSize = 50 * 1024 * 1024,
    this.replyWidget,
    this.autofocus = false,
    this.focusNode,
    this.mentionItemBuilder,
    this.maxRecordTime = const Duration(minutes: 30),
    this.onAttachIconPress,
    this.stopChatWidget,
    this.onMentionSearch,
    this.googleMapsApiKey,
    this.language = const VInputLanguage(),
    this.googleMapsLangKey = "en",
    this.controller,
  });

  @override
  State<VMessageInputWidget> createState() => _VMessageInputWidgetState();
}

class _VMessageInputWidgetState extends State<VMessageInputWidget> {
  bool _internalEmojiShowing = false;
  String _text = "";
  RoomTypingEnum _typingType = RoomTypingEnum.stop;
  final _textEditingController = VChatTextMentionController();
  late FocusNode _focusNode;
  late bool _isOwnFocusNode;
  bool get _isEmojiShowing =>
      widget.controller?.isEmojiShowing ?? _internalEmojiShowing;
  set _isEmojiShowing(bool value) {
    if (widget.controller != null) {
      widget.controller!.setEmojiShowing(value);
    } else {
      setState(() {
        _internalEmojiShowing = value;
      });
    }
  }
  bool get _isRecording => _typingType == RoomTypingEnum.recording;
  bool get _isTyping => _typingType == RoomTypingEnum.typing;
  final _recordStateKey = GlobalKey<RecordWidgetState>();
  final _recordButtonKey = GlobalKey<TelegramRecordButtonState>();
  bool _showMentionList = false;
  final _mentionsWithPhoto = <MentionModel>[];
  // Recording state
  bool _isRecordingLocked = false;
  double _recordDragProgress = 0.0;
  ///links
  VLinkPreviewData? _previewData;
  var _currentUrls = <Uri>[];
  Uri? _currentUrl;
  // Draft functionality
  Timer? _draftSaveTimer;
  static const String _draftPrefix = 'draft_';

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _isOwnFocusNode = false;
    } else {
      _focusNode = FocusNode();
      _isOwnFocusNode = true;
    }
    _loadDraft();
    // Listen to controller changes
    widget.controller?.addListener(_onControllerChanged);
    _textEditingController.addListener(_textEditListener);
    _textEditingController.onSearch = (String? value) async {
      _mentionsWithPhoto.clear();
      if (value == null && _showMentionList) {
        setState(() {
          _showMentionList = false;
        });
        return;
      }
      if (widget.onMentionSearch != null && value != null) {
        final res = await widget.onMentionSearch!(value);
        if (res.isNotEmpty) {
          _mentionsWithPhoto.addAll(res);
          _showMentionList = true;
        } else {
          _showMentionList = false;
        }
        setState(() {});
      }
    };
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _isEmojiShowing = false;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (_typingType != RoomTypingEnum.stop) {
      widget.onTypingChange(RoomTypingEnum.stop);
    }
    widget.controller?.removeListener(_onControllerChanged);
    _draftSaveTimer?.cancel();
    _textEditingController.dispose();
    if (_isOwnFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stopChatWidget != null) {
      _typingType = RoomTypingEnum.stop;
      _isEmojiShowing = false;
      _textEditingController.clear();
      _text = "";
      _currentUrls = [];
      _currentUrl = null;
      return widget.stopChatWidget!;
    }
    final theme = context.vInputTheme;
    final colors = context.telegramColors;
    return PopScope(
      canPop: !_isEmojiShowing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isEmojiShowing) {
          setState(() {
            _isEmojiShowing = false;
          });
        }
      },
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Content above input bar (mentions, link preview, reply, recording)
                  _buildContentAboveInput(colors),
                  // Main input bar - Telegram style layout
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 4,
                      bottom: 8,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Leading button - Attachment (like Telegram)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: TelegramGlassIconButton(
                              icon: theme.attachIcon!,
                              onTap: widget.isAllowSendMedia
                                  ? () => _onAttachFilePress(context, widget.language)
                                  : null,
                              isEnabled: widget.isAllowSendMedia,
                              size: theme.buttonSize,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Text field - expanded (pill shape)
                          Expanded(
                            child: _isRecording
                                ? _buildRecordingContainer(colors)
                                : MessageTextFiled(
                                    isEmojiShowing: _isEmojiShowing,
                                    isAllowSendMedia: widget.isAllowSendMedia,
                                    autofocus: widget.autofocus,
                                    onDetectLink: (urls) {
                                      if (urls.isEmpty) {
                                        _previewData = null;
                                        _currentUrl = null;
                                      } else {
                                        _currentUrl = urls.last;
                                      }
                                      if (_currentUrls.isEmpty && urls.isEmpty) {
                                        return;
                                      }
                                      _currentUrls = urls;
                                      setState(() {});
                                    },
                                    focusNode: _focusNode,
                                    hint: widget.language.textFieldHint,
                                    isTyping: _typingType == RoomTypingEnum.typing,
                                    onSubmit: (v) {
                                      if (v.isNotEmpty) {
                                        widget.onSubmitText(
                                          _textEditingController.markupText,
                                          _previewData,
                                        );
                                        _deleteDraft();
                                        _text = "";
                                        _currentUrl = null;
                                        _currentUrls = [];
                                        _textEditingController.clear();
                                        _changeTypingType(RoomTypingEnum.stop);
                                      }
                                    },
                                    textEditingController: _textEditingController,
                                    onShowEmoji: _showEmoji,
                                    onAttachFilePress: () =>
                                        _onAttachFilePress(context, widget.language),
                                    onCameraPress: () => _onCameraPress(context),
                                  ),
                          ),
                          const SizedBox(width: 6),
                          // Trailing button - Send or Record (like Telegram)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: _buildTrailingButton(theme),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Emoji/Sticker/GIF picker
                  if (_isEmojiShowing) _buildEmojiPicker(colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds content displayed above the input bar
  Widget _buildContentAboveInput(TelegramColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mention list
          if (_showMentionList && _mentionsWithPhoto.isNotEmpty)
            TelegramMentionList(
              mentions: _mentionsWithPhoto,
              mentionItemBuilder: widget.mentionItemBuilder,
              onMentionTap: (mention) {
                _textEditingController.addMention(
                  MentionData(
                    id: mention.peerId,
                    display: mention.name,
                  ),
                );
              },
            ),
          // Link preview
          if (_currentUrl != null)
            LinkPreviewLoader(
              uri: _currentUrl!,
              roomId: widget.roomId,
              onGetData: (data) {
                _previewData = data;
              },
            ),
          // Reply widget
          if (widget.replyWidget != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: widget.replyWidget!,
            ),
        ],
      ),
    );
  }

  /// Builds recording container with Telegram style
  Widget _buildRecordingContainer(TelegramColorScheme colors) {
    return TelegramGlassContainer.pill(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: RecordWidget(
        key: _recordStateKey,
        onMaxTime: () async {
          await _handleRecordingSend();
        },
        maxTime: widget.maxRecordTime,
        isLocked: _isRecordingLocked,
        dragProgress: _recordDragProgress,
        onCancel: _handleRecordingCancel,
      ),
    );
  }

  /// Builds the trailing button (Send or Record)
  Widget _buildTrailingButton(VInputTheme theme) {
    // If typing text, show send button
    if (_isTyping) {
      return MessageSendBtn(
        onSend: () {
          if (_text.isNotEmpty && _text.trim().isNotEmpty) {
            widget.onSubmitText(
              _textEditingController.markupText,
              _previewData,
            );
            _deleteDraft();
            _text = "";
            _currentUrl = null;
            _currentUrls = [];
            _textEditingController.clear();
          }
        },
      );
    }
    // If recording and locked, show send button
    if (_isRecording && _isRecordingLocked) {
      return MessageSendBtn(
        onSend: _handleRecordingSend,
      );
    }
    // Default: show record button with Telegram gestures
    // Keep it visible even during recording to maintain gesture handling
    return TelegramRecordButton(
      key: _recordButtonKey,
      size: theme.buttonSize,
      icon: theme.recordBtn!,
      isEnabled: !VPlatforms.isDeskTop,
      onRecordStart: _handleRecordingStart,
      onRecordCancel: _handleRecordingCancel,
      onRecordSend: _handleRecordingSend,
      onRecordLock: _handleRecordingLock,
    );
  }

  /// Handles recording start - supports both tap and long-press modes
  Future<void> _handleRecordingStart() async {
    if (VPlatforms.isDeskTop) return;
    // Check permission first
    final isAllowRecord = await PermissionManager.isAllowRecord();
    if (isAllowRecord) {
      _recordDragProgress = 0.0;
      _changeTypingType(RoomTypingEnum.recording);
    } else {
      // Ask for permission
      final granted = await PermissionManager.askForRecord();
      if (granted) {
        _recordDragProgress = 0.0;
        _changeTypingType(RoomTypingEnum.recording);
      } else {
        // Permission denied - reset button state
        _recordButtonKey.currentState?.resetToIdle();
        _isRecordingLocked = false;
      }
    }
  }

  /// Handles recording cancellation
  void _handleRecordingCancel() {
    _isRecordingLocked = false;
    _recordDragProgress = 0.0;
    _changeTypingType(RoomTypingEnum.stop);
    // Also reset button state
    _recordButtonKey.currentState?.resetToIdle();
  }

  /// Handles recording send
  Future<void> _handleRecordingSend() async {
    // Check if recording widget exists and has actual recorded data
    if (_recordStateKey.currentState != null) {
      try {
        final voiceData = await _recordStateKey.currentState!.stopRecord();
        // Only send if recording duration is at least 300ms
        if (voiceData.duration >= 300) {
          widget.onSubmitVoice(voiceData);
        }
      } catch (e) {
        debugPrint('Recording send failed: $e');
      }
    }
    _isRecordingLocked = false;
    _recordDragProgress = 0.0;
    _changeTypingType(RoomTypingEnum.stop);
    // Reset button state
    _recordButtonKey.currentState?.resetToIdle();
  }

  /// Handles recording lock (hands-free/tap mode)
  void _handleRecordingLock() {
    setState(() {
      _isRecordingLocked = true;
    });
  }

  /// Builds emoji/sticker/gif picker with Telegram style
  Widget _buildEmojiPicker(TelegramColorScheme colors) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: colors.glassBackground,
        border: Border(
          top: BorderSide(
            color: colors.secondaryText.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colors.secondaryText.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: TabBar(
                tabs: [
                  Tab(
                    icon: Icon(
                      Icons.emoji_emotions_outlined,
                      color: colors.secondaryText,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.sticky_note_2_outlined,
                      color: colors.secondaryText,
                    ),
                  ),
                  Tab(
                    icon: Icon(
                      Icons.gif_box_outlined,
                      color: colors.secondaryText,
                    ),
                  ),
                ],
                labelColor: colors.accent,
                unselectedLabelColor: colors.secondaryText,
                indicatorColor: colors.accent,
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  EmojiKeyboard(
                    controller: _textEditingController,
                    isEmojiShowing: true,
                  ),
                  StickerPicker(
                    onStickerSelected: (sticker) {
                      widget.onSubmitSticker?.call(sticker);
                    },
                  ),
                  GifPicker(
                    onGifSelected: (gif) {
                      widget.onSubmitGif?.call(gif);
                      setState(() => _isEmojiShowing = false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEmoji() async {
    _focusNode.unfocus();
    _focusNode.canRequestFocus = true;
    await Future.delayed(const Duration(milliseconds: 50));
    _isEmojiShowing = !_isEmojiShowing;
  }

  void _onAttachFilePress(BuildContext context, VInputLanguage language) async {
    late AttachEnumRes? res;
    if (widget.onAttachIconPress != null) {
      res = await widget.onAttachIconPress!();
    } else {
      final x = await VAppAlert.showModalSheet(
        content: [
          ModelSheetItem<AttachEnumRes>(
            title: language.media,
            id: AttachEnumRes.media,
            iconData: Icon(PhosphorIcons.image()),
          ),
          ModelSheetItem<AttachEnumRes>(
            title: language.files,
            id: AttachEnumRes.files,
            iconData: Icon(PhosphorIcons.file()),
          ),
          if (widget.googleMapsApiKey != null && VPlatforms.isMobile)
            ModelSheetItem<AttachEnumRes>(
              title: language.location,
              iconData: Icon(PhosphorIcons.mapPin()),
              id: AttachEnumRes.location,
            ),
          if (VPlatforms.isMobile && widget.onSubmitContacts != null)
            ModelSheetItem<AttachEnumRes>(
              title: language.contacts,
              iconData: Icon(PhosphorIcons.addressBook()),
              id: AttachEnumRes.contacts,
            ),
        ],
        context: context,
        title: language.shareMediaAndLocation,
        cancelText: language.cancel,
      );
      if (x == null) return null;
      res = x.id as AttachEnumRes;
    }
    if (res != null) {
      switch (res) {
        case AttachEnumRes.media:
          final files = await VAppPick.getMedia(context: context);
          if (files != null) {
            if (files.isNotEmpty) widget.onSubmitMedia(files);
          }
          break;
        case AttachEnumRes.files:
          final files = await VAppPick.getFiles();
          if (files != null) {
            final resFiles = _processFilesToSubmit(files);
            if (resFiles.isNotEmpty) widget.onSubmitFiles(files);
          }
          break;
        case AttachEnumRes.location:
          if (widget.googleMapsApiKey == null) return;
          final result = await context.toPage(
            PlacePicker(
              apiKey: widget.googleMapsApiKey!,
              onPlacePicked: (result) {
                Navigator.of(context).pop(result);
              },
            ),
          );
          if (result != null) {
            final location = LocationMessageData(
              latLng: latlong.LatLng(
                result.latLng?.latitude ?? 0.0,
                result.latLng?.longitude ?? 0.0,
              ),
              linkPreviewData: LinkPreviewData(
                title: result.name ?? 'Selected Location',
                desc: result.formattedAddress ?? '',
                link:
                    "https://maps.google.com/?q=${result.latLng?.latitude ?? 0.0},${result.latLng?.longitude ?? 0.0}",
              ),
            );
            widget.onSubmitLocation(location);
          }
          break;
        case AttachEnumRes.contacts:
          await _onPickContacts();
          break;
      }
    }
  }

  void _onCameraPress(BuildContext context) async {
    final isCameraAllowed = await PermissionManager.isCameraAllowed();
    if (!isCameraAllowed) {
      final x = await PermissionManager.askForCamera();
      if (!x) return;
    }
    final entity = await VAppPick.pickFromWeAssetCamera(
      onXFileCaptured: (p0, p1) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        _sendWeChatImage(VPlatformFile.fromPath(
          fileLocalPath: p0.path,
        ));
        return true;
      },
      context: context,
    );
    if (entity == null) return;
    widget.onSubmitMedia([entity]);
  }

  Future<void> _sendWeChatImage(VPlatformFile entity) async {
    widget.onSubmitMedia([entity]);
  }

  Future<void> _onPickContacts() async {
    final contacts = await Navigator.of(context).push<List<Contact>>(
      MaterialPageRoute(
        builder: (_) => ContactPickerPage(
          title: widget.language.contacts,
        ),
      ),
    );
    if (contacts == null || contacts.isEmpty) return;
    final contactData = VContactMessageData(
      contacts: contacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => VContactItem(
                name: c.displayName,
                phones: c.phones.map((p) => p.number).toList(),
              ))
          .toList(),
    );
    widget.onSubmitContacts?.call(contactData);
  }

  void _textEditListener() {
    _text = _textEditingController.text;
    // Save draft with debounce
    _saveDraftDebounced(_text);
    if (_text.isNotEmpty && _typingType != RoomTypingEnum.typing) {
      _changeTypingType(RoomTypingEnum.typing);
    } else if (_text.isEmpty && _typingType != RoomTypingEnum.stop) {
      _changeTypingType(RoomTypingEnum.stop);
    }
  }

  void _changeTypingType(RoomTypingEnum typingType) {
    if (typingType != _typingType) {
      setState(() {
        _typingType = typingType;
      });
      widget.onTypingChange(typingType);
    }
  }

  List<VPlatformFile> _processFilesToSubmit(List<VPlatformFile> files) {
    final res = <VPlatformFile>[];
    for (final sourceFile in files) {
      if (sourceFile.fileSize > widget.maxMediaSize) {
        VAppAlert.showErrorSnackBar(
          msg: widget.language.thereIsFileHasSizeBiggerThanAllowedSize,
          context: context,
        );
        continue;
      }
      res.add(sourceFile);
    }
    return res;
  }

  // Draft functionality methods
  String _getDraftKey() {
    return '$_draftPrefix${widget.roomId}';
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftText = prefs.getString(_getDraftKey());
      if (draftText != null && draftText.trim().isNotEmpty) {
        _textEditingController.text = draftText;
        _text = draftText;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // Handle any errors silently
    }
  }

  void _saveDraftDebounced(String draftText) {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDraft(draftText);
    });
  }

  Future<void> _saveDraft(String draftText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (draftText.trim().isEmpty) {
        await prefs.remove(_getDraftKey());
      } else {
        await prefs.setString(_getDraftKey(), draftText);
      }
    } catch (e) {
      // Handle any errors silently
    }
  }

  Future<void> _deleteDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getDraftKey());
      _draftSaveTimer?.cancel();
    } catch (e) {
      // Handle any errors silently
    }
  }
}
