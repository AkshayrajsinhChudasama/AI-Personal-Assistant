import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:googleapis/androidpublisher/v3.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String sender;

  const ChatBubble({super.key, required this.message, required this.sender});

  @override
  Widget build(BuildContext context) {
    final bool isUser = sender == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6A5AE0), Color(0xFF836FFF)],
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
        child: MarkdownBody(
          // Use MarkdownBody to render markdown content
          data: message, // This is the markdown-formatted message
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context).copyWith(
            textTheme: TextTheme(
              bodyMedium: TextStyle(
                fontSize: 16,
                color: isUser ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          )),
        ),
      ),
    );
  }
}
