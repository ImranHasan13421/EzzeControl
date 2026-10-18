import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';

class TextInputBar extends StatefulWidget {
  final Future<bool> Function(String text) onSendText;
  final bool isConnected;

  const TextInputBar({
    super.key,
    required this.onSendText,
    required this.isConnected,
  });

  @override
  State<TextInputBar> createState() => _TextInputBarState();
}

class _TextInputBarState extends State<TextInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text;
    if (text.isEmpty || !widget.isConnected || _isSending) return;

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    final success = await widget.onSendText(text);
    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _controller.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_voice_outlined, size: 20, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.isConnected && !_isSending,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Type or paste text to send to Windows...',
                hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 16, color: AppTheme.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _controller.clear();
                setState(() {});
              },
            ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: widget.isConnected && !_isSending ? _handleSend : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppTheme.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: _isSending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Send', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.send_rounded, size: 13),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
