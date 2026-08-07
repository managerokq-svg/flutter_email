import 'package:flutter/material.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';

class VBubbleThemeUtil {
  static VBubbleTheme dark([AppearanceSettings? settings]) {
    final s = settings ?? AppearanceSettings.defaults;
    return VBubbleTheme.fromStyle(VBubbleStyle.telegram,
            brightness: Brightness.dark)
        .copyWith(
      core: VBubbleCoreTheme(
        outgoing: VDirectionalBubbleColors(
          bubbleColor: s.darkSenderColor,
        ),
        incoming: VDirectionalBubbleColors(bubbleColor: s.darkReceiverColor),
      ),
      systemMessages: const VBubbleSystemTheme(
        backgroundColor: Color(0xE6182229),
        textColor: Color(0xFFD1D7DB),
        textStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
      ),
      dateChip: const VBubbleDateChipTheme(
        backgroundColor: Color(0xE6182229),
        textColor: Color(0xFF8696A0),
        textStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
      text: VBubbleTextTheme(
        outgoing: const VDirectionalTextTheme(
          primaryColor: Color(0xFFE9EDEF),
          secondaryColor: Color(0xFF8696A0),
          linkColor: Color(0xFF53BDEB),
        ),
        incoming: const VDirectionalTextTheme(
          primaryColor: Color(0xFFE9EDEF),
          secondaryColor: Color(0xFF8696A0),
          linkColor: Color(0xFF53BDEB),
        ),
        messageTextStyle: TextStyle(fontSize: s.messageFontSize),
        timeTextStyle: const TextStyle(fontSize: 10),
        senderNameStyle: TextStyle(
            fontSize: s.senderNameFontSize, fontWeight: FontWeight.w500),
        replyTextStyle: const TextStyle(fontSize: 14),
        captionTextStyle: const TextStyle(fontSize: 14),
        linkTextStyle:
            const TextStyle(fontSize: 14, decoration: TextDecoration.none),
      ),
      media: VBubbleMediaTheme(
        outgoing: VDirectionalMediaTheme(
          shimmerBaseColor: s.darkSenderColor.withValues(alpha: 0.3),
          shimmerHighlightColor: s.darkSenderColor.withValues(alpha: 0.1),
        ),
        incoming: VDirectionalMediaTheme(
          shimmerBaseColor: s.darkReceiverColor.withValues(alpha: 0.3),
          shimmerHighlightColor: s.darkReceiverColor.withValues(alpha: 0.1),
        ),
        progressTrackColor: const Color(0xFF374248),
        progressColor: const Color(0xFF25D366),
      ),
      reactions: VBubbleReactionTheme(
        backgroundColor: s.darkReceiverColor,
        selectedBackgroundColor: s.darkSenderColor,
        textColor: const Color(0xFFE9EDEF),
      ),
    );
  }

  static VBubbleTheme light([AppearanceSettings? settings]) {
    final s = settings ?? AppearanceSettings.defaults;
    return VBubbleTheme.fromStyle(VBubbleStyle.telegram,
            brightness: Brightness.light)
        .copyWith(
      core: VBubbleCoreTheme(
        outgoing: VDirectionalBubbleColors(
          bubbleColor: s.lightSenderColor,
        ),
        incoming: VDirectionalBubbleColors(bubbleColor: s.lightReceiverColor),
      ),
      text: VBubbleTextTheme(
        outgoing: const VDirectionalTextTheme(
          primaryColor: Color(0xFF111B21),
          secondaryColor: Color(0xFF667781),
          linkColor: Color(0xFF027EB5),
        ),
        incoming: const VDirectionalTextTheme(
          primaryColor: Color(0xFF111B21),
          secondaryColor: Color(0xFF667781),
          linkColor: Color(0xFF027EB5),
        ),
        messageTextStyle: TextStyle(fontSize: s.messageFontSize),
        timeTextStyle: const TextStyle(fontSize: 10),
        senderNameStyle: TextStyle(
            fontSize: s.senderNameFontSize, fontWeight: FontWeight.w500),
        replyTextStyle: const TextStyle(fontSize: 14),
        captionTextStyle: const TextStyle(fontSize: 14),
        linkTextStyle:
            const TextStyle(fontSize: 15.5, decoration: TextDecoration.none),
      ),
      media: VBubbleMediaTheme(
        outgoing: VDirectionalMediaTheme(
          shimmerBaseColor: s.lightSenderColor.withValues(alpha: 0.3),
          shimmerHighlightColor: s.lightSenderColor.withValues(alpha: 0.1),
        ),
        incoming: VDirectionalMediaTheme(
          shimmerBaseColor: s.lightReceiverColor.withValues(alpha: 0.3),
          shimmerHighlightColor: s.lightReceiverColor.withValues(alpha: 0.1),
        ),
        progressTrackColor: const Color(0xFFD9DADB),
        progressColor: const Color(0xFF25D366),
      ),
      reactions: VBubbleReactionTheme(
        backgroundColor: s.lightReceiverColor,
        selectedBackgroundColor: s.lightSenderColor,
        textColor: const Color(0xFF111B21),
        emojiSize: 12.0,
      ),
      systemMessages: const VBubbleSystemTheme(
        backgroundColor: Color(0xFFFFE9A3),
        textColor: Color(0xFF54656F),
        textStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400),
      ),
      dateChip: const VBubbleDateChipTheme(
        backgroundColor: Color(0xE6FFFFFF),
        textColor: Color(0xFF667781),
        textStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}
