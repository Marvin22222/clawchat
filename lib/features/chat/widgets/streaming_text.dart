import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';

class StreamingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;
  final bool showCursor;

  const StreamingText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 20),
    this.onComplete,
    this.showCursor = true,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  String _displayedText = '';
  Timer? _timer;
  int _charIndex = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayedText = '';
      _charIndex = 0;
      _isComplete = false;
      _startStreaming();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStreaming() {
    _timer = Timer.periodic(widget.charDuration, (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isComplete = true;
        });
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: AppColors.textLight,
    );

    return RichText(
      text: TextSpan(
        style: widget.style ?? defaultStyle,
        children: [
          TextSpan(text: _displayedText),
          if (!_isComplete && widget.showCursor)
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: _BlinkingCursor(
                color: widget.style?.color ?? defaultStyle.color ?? AppColors.textLight,
              ),
            ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 530),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 20,
            margin: const EdgeInsets.only(left: 2, right: 2),
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// Paragraph streaming with smooth line breaks
class StreamingParagraph extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final VoidCallback? onComplete;
  final int charsPerChunk;
  final Duration chunkDelay;

  const StreamingParagraph({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 15),
    this.onComplete,
    this.charsPerChunk = 5,
    this.chunkDelay = const Duration(milliseconds: 10),
  });

  @override
  State<StreamingParagraph> createState() => _StreamingParagraphState();
}

class _StreamingParagraphState extends State<StreamingParagraph> {
  String _displayedText = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStreaming() {
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_charIndex < widget.text.length) {
        // Add chars in small chunks for smoother feel
        final endIndex = (_charIndex + widget.charsPerChunk).clamp(0, widget.text.length);
        setState(() {
          _displayedText = widget.text.substring(0, endIndex);
          _charIndex = endIndex;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 16,
      height: 1.5,
      color: AppColors.textLight,
    );

    return Text(
      _displayedText,
      style: widget.style ?? defaultStyle,
    );
  }
}

/// Code streaming with syntax-appropriate formatting
class StreamingCode extends StatefulWidget {
  final String code;
  final String language;
  final TextStyle? style;
  final Duration charDuration;

  const StreamingCode({
    super.key,
    required this.code,
    this.language = 'text',
    this.style,
    this.charDuration = const Duration(milliseconds: 5),
  });

  @override
  State<StreamingCode> createState() => _StreamingCodeState();
}

class _StreamingCodeState extends State<StreamingCode> {
  String _displayedCode = '';
  Timer? _timer;
  int _charIndex = 0;

  @override
  void initState() {
    super.initState();
    _startStreaming();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStreaming() {
    _timer = Timer.periodic(widget.charDuration, (timer) {
      if (_charIndex < widget.code.length) {
        setState(() {
          _displayedCode = widget.code.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          _displayedCode,
          style: widget.style ??
              const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: AppColors.success,
                height: 1.4,
              ),
        ),
      ),
    );
  }
}