import 'package:flutter/material.dart';
import 'package:chatbot_ui/services/notificationController.dart';
import 'package:chatbot_ui/widgets/Input.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api.dart';
import '../services/notification.dart';
import '../utils/colors.dart';
import '../widgets/utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String chatHistory = '';
  String stage = 'new';
  List<Map<String, dynamic>> messages = [];

  late AnimationController _menuController;
  late Animation<double> _menuAnimation;
  bool isMenuOpen = false;

  FlutterTts flutterTts = FlutterTts();
  bool isSpeechEnabled = false; // Track speech button state
  bool isSpeaking = false; // Track if speech is currently in progress

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeInOut,
    );
    _initializeTTS();
    loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _menuController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _initializeTTS() {
    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((message) {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  // Load messages from API
  void loadMessages() async {
    String? email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      var response = await ChatAPI().retriveMessages(email);
      if (response['code'] == 200) {
        List<dynamic> data = response['data'] as List<dynamic>;
        List<Map<String, dynamic>> mappedMessages = data.map<Map<String, dynamic>>((msg) {
          return {
            'sender': msg['by']?.toString() ?? '',
            'message': msg['msg']?.toString() ?? '',
            'dateTime': DateTime.parse(msg['dateTime']?.toString() ?? DateTime.now().toString())
          };
        }).toList();

        setState(() {
          messages = mappedMessages;
        });
      } else {
        setState(() {
          messages = [];
        });
      }
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  List<Widget> buildMessageList() {
    Map<String, List<Map<String, dynamic>>> groupedMessages = {};

    for (var message in messages) {
      String formattedDate = formatDate(message['dateTime']);
      if (groupedMessages[formattedDate] == null) {
        groupedMessages[formattedDate] = [];
      }
      groupedMessages[formattedDate]?.add(message);
    }

    List<Widget> messageWidgets = [];

    groupedMessages.forEach((date, messageList) {
      messageWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            date,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
      messageList.forEach((message) {
        messageWidgets.add(
          Column(
            crossAxisAlignment: message['sender'] == 'user' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ChatBubble(
                message: message['message'],
                sender: message['sender'],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Text(
                  formatTime(message['dateTime']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      });
    });

    return messageWidgets;
  }

  // Method to handle text-to-speech
  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1);
      await flutterTts.speak(text);
    }
  }

  Future<void> _toggleSpeech() async {
    if (isSpeechEnabled) {
      await flutterTts.stop(); // Stop speaking immediately
    } else if (messages.isNotEmpty) {
      await _speak(messages.last['message']); // Speak last message
    }

    setState(() {
      isSpeechEnabled = !isSpeechEnabled;
    });
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _closeMenu,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chat Application",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF6A5AE0),
          leading: IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _menuAnimation,
            ),
            onPressed: _toggleMenu,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
            IconButton(
              icon: Icon(Icons.volume_up, color: isSpeechEnabled ? Colors.green : Colors.white),
              onPressed: _toggleSpeech,
              tooltip: isSpeechEnabled ? 'Speech Enabled' : 'Speech Disabled',
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      children: buildMessageList(),
                    ),
                  ),
                  ChatInputField(controller: _messageController, onSend: _sendMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


Future<void> _sendMessage() async {
    String message = _messageController.text.trim();
    String? email = FirebaseAuth.instance.currentUser?.email;

    if (message.isNotEmpty) {
      DateTime now = DateTime.now();
      setState(() {
        messages.add({
          'sender': 'user',
          'message': message,
          'dateTime': now,
        });
        chatHistory += '\nUser: $message';
        _scrollToBottom();
        _messageController.clear();
      });
      var data = await ChatAPI().sendMessageToApi(message, chatHistory, stage, email!);
      var apiResponse = data['text'];

      setState(() {
        chatHistory += '\nBot: $apiResponse';
        if (data['text'] != null) {
          stage = data['text'];
        } else {
          stage = 'new';
        }
        messages.add({
          'sender': 'api',
          'message': '$apiResponse',
          'dateTime': DateTime.now(),
        });
      });

      // Speak the bot's response if speech is enabled
      if (isSpeechEnabled && apiResponse.isNotEmpty) {
        _speak(apiResponse);  // Speak the response
      }

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _closeMenu() {
    if (isMenuOpen) {
      setState(() {
        isMenuOpen = false;
        _menuController.reverse();
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'expiration_time');
      await FirebaseAuth.instance.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during sign out: $e')),
      );
    }
  }

  Future<void> _clearHistory() async {
    if (messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No messages to delete')),
      );
      return;
    }
    bool? confirmDelete = await _showConfirmationDialog();

    if (confirmDelete == true) {
      String? email = FirebaseAuth.instance.currentUser?.email;

      if (email != null) {
        var response = await ChatAPI().deleteMessages(email); // Call API to delete all messages

        if (response['code'] == 200) {
          setState(() {
            messages.clear();
            chatHistory = '';
            stage = 'new';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All messages deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting all messages')),
          );
        }
      }
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('This action will delete all your messages permanently.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User pressed No
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User pressed Yes
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
