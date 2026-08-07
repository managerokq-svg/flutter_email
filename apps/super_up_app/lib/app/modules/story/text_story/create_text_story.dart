import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/core/api_service/story/story_api_service.dart';
import 'package:super_up/app/core/models/story/create_story_dto.dart';
import 'package:super_up/app/core/utils/enums.dart';
import 'package:super_up_core/super_up_core.dart';

class CreateTextStory extends StatefulWidget {
  const CreateTextStory({super.key});

  @override
  State<CreateTextStory> createState() => _CreateTextStoryState();
}

class _CreateTextStoryState extends State<CreateTextStory> {
  final _api = GetIt.I.get<StoryApiService>();
  final _txtController = TextEditingController();
  final _focusNode = FocusNode();

  Color _backgroundColor = const Color(0xFF128C7E);
  StoryFontType _fontType = StoryFontType.normal;
  TextAlign _textAlign = TextAlign.center;

  static const List<Color> _colorPalette = [
    Color(0xFF128C7E), // WhatsApp green
    Color(0xFF075E54), // WhatsApp dark green
    Color(0xFF25D366), // WhatsApp light green
    Color(0xFF34B7F1), // WhatsApp blue
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF2196F3), // Blue
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF4CAF50), // Green
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFF9800), // Orange
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF212121), // Almost Black
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue variant
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _txtController.dispose();
    super.dispose();
  }

  TextStyle get _currentTextStyle {
    switch (_fontType) {
      case StoryFontType.normal:
        return const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 32,
          color: Colors.white,
        );
      case StoryFontType.bold:
        return const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: Colors.white,
        );
      case StoryFontType.italic:
        return const TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 32,
          color: Colors.white,
        );
    }
  }

  String get _fontTypeLabel {
    switch (_fontType) {
      case StoryFontType.normal:
        return 'Aa';
      case StoryFontType.bold:
        return 'B';
      case StoryFontType.italic:
        return 'I';
    }
  }

  IconData get _alignIcon {
    switch (_textAlign) {
      case TextAlign.left:
        return Icons.format_align_left;
      case TextAlign.center:
        return Icons.format_align_center;
      case TextAlign.right:
        return Icons.format_align_right;
      default:
        return Icons.format_align_center;
    }
  }

  void _cycleFont() {
    final values = StoryFontType.values;
    final currentIndex = values.indexOf(_fontType);
    _fontType = values[(currentIndex + 1) % values.length];
    setState(() {});
  }

  void _cycleAlign() {
    switch (_textAlign) {
      case TextAlign.left:
        _textAlign = TextAlign.center;
        break;
      case TextAlign.center:
        _textAlign = TextAlign.right;
        break;
      default:
        _textAlign = TextAlign.left;
    }
    setState(() {});
  }

  void _selectColor(Color color) {
    _backgroundColor = color;
    setState(() {});
  }

  void _wrapSelectedText(String prefix, String suffix) {
    final selection = _txtController.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final text = _txtController.text;
    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );
    _txtController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      ),
    );
  }

  void _wrapWithBold() => _wrapSelectedText('**', '**');
  void _wrapWithItalic() => _wrapSelectedText('*', '*');
  void _wrapWithCode() => _wrapSelectedText('`', '`');
  void _wrapWithMention() => _wrapSelectedText('@', '');
  void _wrapWithHashtag() => _wrapSelectedText('#', '');

  Future<void> _wrapWithLink() async {
    final selection = _txtController.selection;
    if (!selection.isValid || selection.isCollapsed) return;
    final text = _txtController.text;
    final selectedText = text.substring(selection.start, selection.end);
    final url = await _showLinkDialog();
    if (url == null || url.isEmpty) return;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '[$selectedText]($url)',
    );
    _txtController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + selectedText.length + url.length + 4,
      ),
    );
  }

  Future<String?> _showLinkDialog() async {
    final urlController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Link'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, urlController.text),
            child: Text(S.of(context).add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildTextInput()),
            _buildFormatToolbar(),
            _buildColorPalette(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(CupertinoIcons.clear, color: Colors.white, size: 28),
          ),
          const Spacer(),
          _buildToolButton(
            onTap: _cycleFont,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _fontTypeLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: _fontType == StoryFontType.bold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: _fontType == StoryFontType.italic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildToolButton(
            onTap: _cycleAlign,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(_alignIcon, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  Widget _buildTextInput() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: TextField(
          controller: _txtController,
          focusNode: _focusNode,
          textAlign: _textAlign,
          maxLines: 8,
          minLines: 1,
          maxLength: 500,
          style: _currentTextStyle,
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: S.of(context).createYourStory,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 32,
            ),
            border: InputBorder.none,
            counterStyle: const TextStyle(color: Colors.white54),
          ),
          contextMenuBuilder: (context, editableTextState) {
            return _buildCustomContextMenu(editableTextState);
          },
        ),
      ),
    );
  }

  Widget _buildCustomContextMenu(EditableTextState editableTextState) {
    final selection = editableTextState.textEditingValue.selection;
    final hasSelection = selection.isValid && !selection.isCollapsed;
    final List<ContextMenuButtonItem> buttonItems = [];
    // Add default items first
    buttonItems.addAll(editableTextState.contextMenuButtonItems);
    // Add custom formatting items only if text is selected
    if (hasSelection) {
      buttonItems.addAll([
        ContextMenuButtonItem(
          label: 'Bold',
          onPressed: () {
            ContextMenuController.removeAny();
            _wrapWithBold();
          },
        ),
        ContextMenuButtonItem(
          label: 'Italic',
          onPressed: () {
            ContextMenuController.removeAny();
            _wrapWithItalic();
          },
        ),
        ContextMenuButtonItem(
          label: 'Code',
          onPressed: () {
            ContextMenuController.removeAny();
            _wrapWithCode();
          },
        ),
        ContextMenuButtonItem(
          label: 'Link',
          onPressed: () {
            ContextMenuController.removeAny();
            _wrapWithLink();
          },
        ),
        ContextMenuButtonItem(
          label: '@Mention',
          onPressed: () {
            ContextMenuController.removeAny();
            _wrapWithMention();
          },
        ),
        ContextMenuButtonItem(
          label: '#Hashtag',
          onPressed: () {
            ContextMenuController.removeAny();
            _wrapWithHashtag();
          },
        ),
      ]);
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  Widget _buildFormatToolbar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFormatButton(
            icon: Icons.format_bold,
            label: 'B',
            onTap: _wrapWithBold,
            tooltip: 'Bold **text**',
          ),
          _buildFormatButton(
            icon: Icons.format_italic,
            label: 'I',
            onTap: _wrapWithItalic,
            tooltip: 'Italic *text*',
          ),
          _buildFormatButton(
            icon: Icons.code,
            label: '<>',
            onTap: _wrapWithCode,
            tooltip: 'Code `text`',
          ),
          _buildFormatButton(
            icon: Icons.link,
            label: null,
            onTap: _wrapWithLink,
            tooltip: 'Link [text](url)',
          ),
          _buildFormatButton(
            icon: Icons.alternate_email,
            label: null,
            onTap: _wrapWithMention,
            tooltip: 'Mention @user',
          ),
          _buildFormatButton(
            icon: Icons.tag,
            label: null,
            onTap: _wrapWithHashtag,
            tooltip: 'Hashtag #tag',
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: label != null
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildColorPalette() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _colorPalette.length,
        itemBuilder: (context, index) {
          final color = _colorPalette[index];
          final isSelected = color == _backgroundColor;
          return GestureDetector(
            onTap: () => _selectColor(color),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white24,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              S.of(context).shareYourStatus,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: _uploadTextStory,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadTextStory() async {
    final text = _txtController.text.trim();
    if (text.isEmpty) return;
    await vSafeApiCall(
      onLoading: () => VAppAlert.showLoading(context: context),
      request: () async {
        final dto = CreateStoryDto(
          storyType: StoryType.text,
          content: text,
          backgroundColor: _backgroundColor.toARGB32().toRadixString(16),
          storyFontType: _fontType,
          attachment: {
            'textAlign': _textAlign.name,
          },
        );
        return _api.createStory(dto);
      },
      onSuccess: (response) {
        context.pop();
        context.pop();
        VAppAlert.showSuccessSnackBar(
          context: context,
          message: S.of(context).storyCreatedSuccessfully,
        );
      },
      onError: (exception) {
        context.pop();
        VAppAlert.showErrorSnackBar(
          context: context,
          message: exception.toString(),
        );
      },
    );
  }
}
