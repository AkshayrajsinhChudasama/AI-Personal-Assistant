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
            colors: [Color(0xFF6A5AE0),Color(0xFF6A5AE0)],
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
      duration: const Duration(milliseconds: 950),
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
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _getColor(index),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  double _getHeightOffset(int index) {
    List<double> maxHeights = [3, 6, 9]; // Slight bounce effect per dot
    double progress = _controller.value;

    double startPoint = index * 0.25;
    double midPoint = startPoint + 0.125;
    double endPoint = startPoint + 0.25;

    if (progress < startPoint) {
      return 0;
    } else if (progress >= endPoint) {
      return 0;
    } else if (progress < midPoint) {
      double upProgress = (progress - startPoint) / 0.125;
      return maxHeights[index] * upProgress;
    } else {
      double downProgress = (endPoint - progress) / 0.125;
      return maxHeights[index] * downProgress;
    }
  }

  Color _getColor(int index) {
    double progress = _controller.value;
    double startPoint = index * 0.25;
    double endPoint = startPoint + 0.25;

    if (progress < startPoint) {
      return Colors.grey; // Default inactive color
    } else if (progress > endPoint) {
      return Colors.grey;
    } else {
      double intensity = (progress - startPoint) / 0.25;
      return Color.lerp(Colors.grey, Colors.black, intensity)!;
    }
  }
}
