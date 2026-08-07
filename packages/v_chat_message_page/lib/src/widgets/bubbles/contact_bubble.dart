// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:s_translation/generated/l10n.dart';

class VContactBubble extends BaseBubble {
  final VContactMessageData contactData;
  final void Function(VContactItem contact)? onContactTap;
  final void Function(VContactItem contact)? onAddContact;

  @override
  String get messageType => 'contact';

  const VContactBubble({
    super.key,
    required super.messageId,
    required super.isMeSender,
    required super.time,
    required this.contactData,
    this.onContactTap,
    this.onAddContact,
    super.status,
    super.isSameSender,
    super.avatar,
    super.senderName,
    super.senderColor,
    super.replyTo,
    super.forwardedFrom,
    super.reactions,
    super.isEdited,
    super.isPinned,
    super.isStarred,
    super.isHighlighted,
  });

  @override
  Widget buildContent(BuildContext context) {
    final theme = context.bubbleTheme;
    final contacts = contactData.contacts;
    final header = buildBubbleHeader(context);
    final hasHeader = header != null;
    final showTail = !isSameSender;
    final textColor = isMeSender ? theme.outgoingTextColor : theme.incomingTextColor;
    return VBubbleWrapper(
      isMeSender: isMeSender,
      showTail: showTail,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: header,
              ),
            ...contacts.asMap().entries.map((entry) => _CompactContactCard(
                  contact: entry.value,
                  textColor: textColor,
                  showDivider: entry.key < contacts.length - 1,
                  onTap: onContactTap != null ? () => onContactTap!(entry.value) : null,
                  onAddContact: onAddContact != null ? () => onAddContact!(entry.value) : null,
                )),
            buildMeta(context),
          ],
        ),
      ),
    );
  }
}

class _CompactContactCard extends StatelessWidget {
  final VContactItem contact;
  final Color textColor;
  final bool showDivider;
  final VoidCallback? onTap;
  final VoidCallback? onAddContact;

  const _CompactContactCard({
    required this.contact,
    required this.textColor,
    required this.showDivider,
    this.onTap,
    this.onAddContact,
  });

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).phoneCopied(phone)), duration: const Duration(seconds: 1)),
    );
  }

  void _showPhoneOptions(BuildContext context, String phone) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                leading: const Icon(Icons.call, color: Colors.green),
                title: Text(S.of(context).callPhone(phone)),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchPhone(phone);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.sms, color: Colors.blue),
                title: Text(S.of(context).smsPhone(phone)),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchSms(phone);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.copy),
                title: Text(S.of(context).copy),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyPhone(context, phone);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryPhone = contact.phones.isNotEmpty ? contact.phones.first : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: textColor.withValues(alpha: 0.12),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name & Phone
              Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contact.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (primaryPhone != null)
                        GestureDetector(
                          onTap: () => _launchPhone(primaryPhone),
                          onLongPress: () => _showPhoneOptions(context, primaryPhone),
                          child: Text(
                            primaryPhone,
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.7),
                              decoration: TextDecoration.underline,
                              decorationColor: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Action buttons
              if (primaryPhone != null) ...[
                _MiniIconButton(
                  icon: Icons.call,
                  color: Colors.green,
                  onTap: () => _launchPhone(primaryPhone),
                ),
                _MiniIconButton(
                  icon: Icons.sms,
                  color: Colors.blue,
                  onTap: () => _launchSms(primaryPhone),
                ),
              ],
            ],
          ),
        ),
        // Additional phones (if more than one)
        if (contact.phones.length > 1)
          ...contact.phones.skip(1).map((phone) => Padding(
                padding: const EdgeInsets.only(left: 46, top: 2, bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _launchPhone(phone),
                        onLongPress: () => _showPhoneOptions(context, phone),
                        child: Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.7),
                            decoration: TextDecoration.underline,
                            decorationColor: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    _MiniIconButton(
                      icon: Icons.call,
                      color: Colors.green,
                      size: 16,
                      onTap: () => _launchPhone(phone),
                    ),
                    _MiniIconButton(
                      icon: Icons.sms,
                      color: Colors.blue,
                      size: 16,
                      onTap: () => _launchSms(phone),
                    ),
                  ],
                ),
              )),
        if (showDivider)
          Divider(height: 8, thickness: 0.5, color: textColor.withValues(alpha: 0.2)),
      ],
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _MiniIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
