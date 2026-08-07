// Copyright 2025, the hatemragab project.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:s_translation/generated/l10n.dart';

/// Shows a dialog displaying all reactions on a message with user details
Future<void> showReactionsDialog({
  required BuildContext context,
  required String roomId,
  required String messageId,
}) {
  return showDialog(
    context: context,
    builder: (context) => ReactionsDialog(
      roomId: roomId,
      messageId: messageId,
    ),
  );
}

class ReactionsDialog extends StatefulWidget {
  final String roomId;
  final String messageId;

  const ReactionsDialog({
    super.key,
    required this.roomId,
    required this.messageId,
  });

  @override
  State<ReactionsDialog> createState() => _ReactionsDialogState();
}

class _ReactionsDialogState extends State<ReactionsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<VReactionDetail> _reactions = [];
  bool _isLoading = true;
  String? _error;
  List<String> _emojiTabs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _fetchReactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReactions() async {
    try {
      final reactions = await VChatController.I.nativeApi.remote.message
          .getMessageReactionsDetails(
        roomId: widget.roomId,
        messageId: widget.messageId,
      );
      final uniqueEmojis = reactions.map((r) => r.emoji).toSet().toList();
      setState(() {
        _reactions = reactions;
        _emojiTabs = uniqueEmojis;
        _isLoading = false;
        _tabController.dispose();
        _tabController = TabController(
          length: uniqueEmojis.length + 1, // +1 for "All" tab
          vsync: this,
        );
      });
    } catch (e, stack) {
      print('=== REACTIONS FETCH ERROR ===');
      print('Error: $e');
      print('Stack: $stack');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<VReactionDetail> _getFilteredReactions(int tabIndex) {
    if (tabIndex == 0) return _reactions;
    final emoji = _emojiTabs[tabIndex - 1];
    return _reactions.where((r) => r.emoji == emoji).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_isLoading) _buildLoading(),
            if (_error != null) _buildError(),
            if (!_isLoading && _error == null && _reactions.isNotEmpty) ...[
              _buildTabs(),
              Flexible(child: _buildReactionsList()),
            ],
            if (!_isLoading && _error == null && _reactions.isEmpty)
              _buildEmpty(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            S.of(context).reactions,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(S.of(context).failedToLoadReactions, style: const TextStyle(color: Colors.red)),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _fetchReactions();
            },
            child: Text(S.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(S.of(context).noReactionsYet),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).all),
              const SizedBox(width: 4),
              _buildCountBadge(_reactions.length),
            ],
          ),
        ),
        ..._emojiTabs.map((emoji) {
          final count = _reactions.where((r) => r.emoji == emoji).length;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                _buildCountBadge(count),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildReactionsList() {
    return TabBarView(
      controller: _tabController,
      children: List.generate(
        _emojiTabs.length + 1,
        (index) => _buildUserList(_getFilteredReactions(index)),
      ),
    );
  }

  Widget _buildUserList(List<VReactionDetail> reactions) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: reactions.length,
      itemBuilder: (context, index) {
        final reaction = reactions[index];
        return _buildUserTile(reaction);
      },
    );
  }

  Widget _buildUserTile(VReactionDetail reaction) {
    final imageUrl = SConstants.baseMediaUrl + reaction.user.userImage;
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
      ),
      title: Text(
        reaction.user.fullName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        reaction.emoji,
        style: const TextStyle(fontSize: 24),
      ),
      onTap: () {
        Navigator.of(context).pop();
        VChatController.I.vNavigator.messageNavigator.toUserProfilePage?.call(
          context,
          reaction.user.id,
        );
      },
    );
  }
}
