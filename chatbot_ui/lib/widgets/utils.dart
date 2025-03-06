import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String sender;
  final bool? isLoading;

  const ChatBubble({
    super.key,
    required this.message,
    required this.sender,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = sender == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
            colors: [const Color(0xFF082686),const Color(0xFF082686)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFD1D9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: isLoading == true
            ? const TypingIndicator()
            : MarkdownBody(
          data: message,
          styleSheet: MarkdownStyleSheet.fromTheme(
            Theme.of(context).copyWith(
              textTheme: TextTheme(
                bodyMedium: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950), // Total duration for all dots
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _controller.forward(from: 0.0);
          }
        });
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_getHeightOffset(index)),
                child: child,
              );
            },
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }

  double _getHeightOffset(int index) {
    // Heights increase from left to right
    List<double> maxHeights = [3, 6, 9, 12];
    double progress = _controller.value;

    // Each dot gets 0.25 of total duration (500ms each)
    double startPoint = index * 0.25; // 0.0, 0.25, 0.5, 0.75
    double midPoint = startPoint + 0.125; // Halfway point for peak
    double endPoint = startPoint + 0.25; // End of dot's cycle

    if (progress < startPoint) {
      return 0; // Haven't started moving yet
    } else if (progress >= endPoint) {
      return 0; // Back to starting position
    } else if (progress < midPoint) {
      // Going up
      double upProgress = (progress - startPoint) / 0.125;
      return maxHeights[index] * upProgress;
    } else {
      // Going down
      double downProgress = (endPoint - progress) / 0.125;
      return maxHeights[index] * downProgress;
    }
  }
}