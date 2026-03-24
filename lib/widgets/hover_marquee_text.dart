import 'package:flutter/material.dart';

class HoverMarqueeText extends StatefulWidget {
  final String text;

  const HoverMarqueeText(this.text, {super.key});

  @override
  State<HoverMarqueeText> createState() => _HoverMarqueeTextState();
}

class _HoverMarqueeTextState extends State<HoverMarqueeText> {
  final ScrollController _controller = ScrollController();
  bool _isHovering = false;

  void _startScroll() async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (!_isHovering) return;

    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(seconds: 3),
      curve: Curves.linear,
    );
  }

  void _resetScroll() {
    _controller.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _isHovering = true;
        _startScroll();
      },
      onExit: (_) {
        _isHovering = false;
        _resetScroll();
      },
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(widget.text, maxLines: 1, overflow: TextOverflow.clip),
      ),
    );
  }
}
