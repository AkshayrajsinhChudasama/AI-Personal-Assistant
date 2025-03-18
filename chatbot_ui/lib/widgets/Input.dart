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

class _ChatInputFieldState extends State<ChatInputField> {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  double _rotation = 0.0;
  String selectedLocaleId = 'en_IN';

  final List<Map<String, String>> _indianLocales = [
    {'name': 'English (India)', 'locale': 'en_IN'},
    {'name': 'Hindi (India)', 'locale': 'hi_IN'},
    {'name': 'Gujarati (India)', 'locale': 'gu_IN'},
    {'name': 'Bengali (India)', 'locale': 'bn_IN'},
    {'name': 'Punjabi (India)', 'locale': 'pa_IN'},
    {'name': 'Tamil (India)', 'locale': 'ta_IN'},
    {'name': 'Telugu (India)', 'locale': 'te_IN'},
    {'name': 'Marathi (India)', 'locale': 'mr_IN'},
    {'name': 'Malayalam (India)', 'locale': 'ml_IN'},
    {'name': 'Kannada (India)', 'locale': 'kn_IN'},
    {'name': 'Urdu (India)', 'locale': 'ur_IN'},
    {'name': 'Odia (India)', 'locale': 'or_IN'},
    {'name': 'Assamese (India)', 'locale': 'as_IN'},
  ];

  Future<void> _startListening() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _rotation += 6.2832;
        });

        _speechToText.listen(
          localeId: selectedLocaleId,
          onResult: (result) async {
            String recognizedText = result.recognizedWords;
            if (recognizedText.isNotEmpty) {
              widget.controller.text = recognizedText;
            }
          },
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          pauseFor: const Duration(seconds: 10), // Mic waits 10s silence before stopping
          listenFor: const Duration(minutes: 2), // Maximum listen time 2 minutes
        );
      }
    } else {
      print("Microphone permission not granted.");
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _rotation += 6.2832;
    });
  }

  void _handleSubmit() {
    widget.onSend();
    _stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          DropdownButton<String>(
            value: selectedLocaleId,
            onChanged: (value) {
              setState(() {
                selectedLocaleId = value!;
              });
            },
            items: _indianLocales.map((locale) {
              return DropdownMenuItem(
                value: locale['locale'],
                child: Text(locale['name'] ?? locale['locale']!),
              );
            }).toList(),
          ),
          Row(
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
                  child: AnimatedRotation(
                    turns: _rotation / 6.2832,
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
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleSubmit,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF6A5AE0),
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
        ],
      ),
    );
  }
}
