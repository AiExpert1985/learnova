import 'package:flutter/material.dart';

class UrlInput extends StatefulWidget {
  final Function(String) onLoad;
  final bool isLoading;

  const UrlInput({super.key, required this.onLoad, required this.isLoading});

  @override
  State<UrlInput> createState() => _UrlInputState();
}

class _UrlInputState extends State<UrlInput> {
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleLoad() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    widget.onLoad(url);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'Paste YouTube URL...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              enabled: !widget.isLoading,
              onSubmitted: (_) => _handleLoad(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: widget.isLoading ? null : _handleLoad,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            color: Colors.green,
            iconSize: 32,
          ),
        ],
      ),
    );
  }
}
