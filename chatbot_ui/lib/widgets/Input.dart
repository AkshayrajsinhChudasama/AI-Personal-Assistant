import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({super.key, required this.controller, required this.onSend});

  @override
  _ChatInputFieldState createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> with SingleTickerProviderStateMixin {
  stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  double _rotation = 0.0;  // For rotating the mic icon

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startListening() async {
    PermissionStatus status = await Permission.microphone.request();

    if (status.isGranted) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _rotation += 6.2832;  // Full 360-degree rotation (2 * pi radians)
        });

        _speechToText.listen(
          onResult: (result) {
            widget.controller.text = result.recognizedWords;
          },
        );
      } else {
        print("Speech recognition not available.");
      }
    } else {
      print("Microphone permission not granted.");
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _rotation += 6.2832;  // Complete another full rotation (reset the rotation)
    });
  }

  void _handleSubmit() {
    widget.onSend();
    _stopListening();  // Ensure the mic stops when submitting
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? Colors.red : const Color(0xFF6A5AE0),
                boxShadow: _isListening
                    ? [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ]
                    : const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: AnimatedRotation(
                  turns: _rotation / 6.2832,  // Convert radians to full turns (1 turn = 2*pi radians)
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 24,
                    key: ValueKey<bool>(_isListening),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "How can I help you?",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSubmit,  // Call the new handleSubmit method
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6A5AE0), Color(0xFF836FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
