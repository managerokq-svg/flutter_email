// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_glass_container.dart';
import 'package:v_chat_input_ui/src/models/v_input_theme.dart';
import 'package:v_chat_mention_controller/v_chat_mention_controller.dart';
import 'package:v_platform/v_platform.dart';

import '../../v_widgets/auto_direction.dart';

final urlDetectReg = RegExp(
  r"(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)",
  caseSensitive: false,
  dotAll: true,
);

class MessageTextFiled extends StatefulWidget {
  final VChatTextMentionController textEditingController;
  final FocusNode focusNode;
  final bool isTyping;
  final bool autofocus;
  final bool isAllowSendMedia;
  final String hint;
  final VoidCallback onShowEmoji;
  final VoidCallback onCameraPress;
  final VoidCallback onAttachFilePress;
  final Function(String value) onSubmit;
  final Function(List<Uri> urls) onDetectLink;
  final bool isEmojiShowing;

  const MessageTextFiled({
    super.key,
    required this.textEditingController,
    required this.focusNode,
    required this.isAllowSendMedia,
    required this.onShowEmoji,
    required this.onCameraPress,
    required this.onAttachFilePress,
    required this.onDetectLink,
    required this.isTyping,
    required this.autofocus,
    required this.hint,
    required this.onSubmit,
    this.isEmojiShowing = false,
  });

  @override
  State<MessageTextFiled> createState() => _MessageTextFiledState();
}

class _MessageTextFiledState extends State<MessageTextFiled> {
  String txt = "";
  int lines = 1;

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_lineListener);
  }

  @override
  void dispose() {
    widget.textEditingController.removeListener(_lineListener);
    super.dispose();
  }

  bool get isMultiLine => lines != 1;

  @override
  Widget build(BuildContext context) {
    final theme = context.vInputTheme;
    final colors = context.telegramColors;
    return TelegramGlassContainer.pill(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        crossAxisAlignment:
            isMultiLine ? CrossAxisAlignment.end : CrossAxisAlignment.center,
        children: [
          // Text field - expanded
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AutoDirection(
                text: txt,
                child: TextField(
                  decoration: InputDecoration(
                    fillColor: Colors.transparent,
                    hintText: widget.hint,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    border: InputBorder.none,
                    hintStyle: theme.hintTextStyle,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  controller: widget.textEditingController,
                  focusNode: widget.focusNode,
                  autofocus: widget.autofocus,
                  maxLines: 5,
                  onChanged: (value) {
                    setState(() {
                      txt = value;
                    });
                    if (value.isNotEmpty) {
                      _urlMatcher(widget.textEditingController.text);
                    }
                  },
                  style: theme.textFieldTextStyle,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  onSubmitted: VPlatforms.isMobile
                      ? null
                      : (value) {
                          if (value.isNotEmpty) {
                            widget.onSubmit(value);
                          }
                          widget.focusNode.requestFocus();
                          widget.textEditingController.clear();
                        },
                  textInputAction:
                      !VPlatforms.isMobile ? null : TextInputAction.newline,
                  keyboardType: VPlatforms.isMobile
                      ? TextInputType.multiline
                      : TextInputType.text,
                ),
              ),
            ),
          ),
          // Right side icons (inside text field)
          Padding(
            padding: EdgeInsets.only(
              bottom: isMultiLine ? 8 : 0,
              right: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji/Sticker button - positioned on right like Telegram
                GestureDetector(
                  onTap: widget.onShowEmoji,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: widget.isEmojiShowing
                        ? Icon(
                            Icons.keyboard_alt_outlined,
                            size: 27,
                            color: colors.secondaryText,
                          )
                        : theme.emojiIcon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _lineListener() {
    final count = widget.textEditingController.text.split('\n').length;
    if (lines != count) {
      setState(() {
        lines = count;
      });
    }
  }

  void _urlMatcher(String txt) {
    final allMatches = urlDetectReg.allMatches(txt);
    if (allMatches.isEmpty) {
      widget.onDetectLink(<Uri>[]);
      return;
    }
    final list = <Uri>[];
    for (final e in allMatches) {
      final group = e.group(0);
      if (group != null && Uri.tryParse(group) != null) {
        list.add(Uri.parse(ensureHttpPrefix(group)));
      }
    }
    widget.onDetectLink(list);
  }

  String ensureHttpPrefix(String url) {
    if (!url.startsWith(RegExp(r'https?:\/\/'))) {
      return 'https://$url';
    }
    return url;
  }
}
