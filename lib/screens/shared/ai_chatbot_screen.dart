// lib/screens/shared/ai_chatbot_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});
  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<Message> _messages = [];
  bool _loading = false;
  bool _initializing = true;
  String _selectedMode = 'General';
  String _workingModel = '';
  String _initError = '';

  static const String _apiKey = 'AIzaSyBl9FZpLQeHaf1S2DlvFOKlJZ0mVdQ3mW0';

  final List<String> _modes = [
    'General', 'English↔Hindi', 'Math Help',
    'Science', 'Grammar', 'GK Quiz',
    'Yoga & Health', 'Diet & Nutrition', 'Bharat Ko Jano', 'Study Tips',
  ];

  @override
  void initState() {
    super.initState();
    _findWorkingModel();
  }

  // Step 1: List all available models, pick first generateContent model
  Future<void> _findWorkingModel() async {
    setState(() { _initializing = true; _initError = ''; });
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final models = (data['models'] as List<dynamic>?) ?? [];
        // Find first model that supports generateContent
        for (final m in models) {
          final name = m['name'] as String? ?? '';
          final methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
          if (methods.contains('generateContent') && name.contains('gemini')) {
            // Extract model id from "models/gemini-xxx" → "gemini-xxx"
            setState(() {
              _workingModel = name.replaceFirst('models/', '');
              _initializing = false;
            });
            return;
          }
        }
        setState(() {
          _initError = 'No Gemini models found.\nAvailable: ${models.map((m) => m['name']).join(', ')}';
          _initializing = false;
        });
      } else {
        setState(() {
          _initError = 'API Error ${res.statusCode}: ${res.body}';
          _initializing = false;
        });
      }
    } catch (e) {
      setState(() {
        _initError = 'Connection failed: $e';
        _initializing = false;
      });
    }
  }

  String _getSystemPrompt(String mode, String name, String cls) {
    final base = 'You are BDPHS AI Tutor, a friendly teacher for students of '
        'Blooming Dale Public High School, Jammu & Kashmir, India. '
        'Student name: $name, Class: $cls. '
        'Always use simple, easy language. '
        'If student writes in Hindi, reply in Hindi. '
        'Keep answers short and clear for school children.';
    switch (mode) {
      case 'English↔Hindi':
        return '$base You are English-Hindi translator. '
            'Give: 1) Hindi meaning 2) English meaning 3) Example sentence.';
      case 'Math Help':
        return '$base You are a Math tutor. Solve step by step clearly.';
      case 'Science':
        return '$base You are a Science teacher. Use simple real-life examples.';
      case 'Grammar':
        return '$base You are English Grammar teacher. Explain rules simply.';
      case 'GK Quiz':
        return '$base You are a GK quiz master for Indian school students.';
      case 'Yoga & Health':
        return '$base You are a Yoga and Health guide. '
            'Suggest age-appropriate yoga poses and health tips for school students. '
            'Explain poses simply with steps and benefits.';
      case 'Diet & Nutrition':
        return '$base You are a Nutrition expert for school children. '
            'Suggest balanced diet plans, healthy food habits, and nutrition tips. '
            'Focus on simple Indian food available in J&K.';
      case 'Bharat Ko Jano':
        return '$base You are a guide for Indian national symbols. '
            'Explain National Anthem, National Song, their meaning, history and importance. '
            'Help students learn and understand them.';
      case 'Study Tips':
        return '$base You are a study skills coach for school students. '
            'Give proven study tips, memory techniques, exam preparation advice. '
            'Motivate students and help them build good study habits.';
      default:
        return '$base Help with any school subject or homework.';
    }
  }

  Future<void> _send(String text, String name, String cls) async {
    if (text.trim().isEmpty || _workingModel.isEmpty) return;
    _ctrl.clear();

    setState(() {
      _messages.add(Message(text: text, isUser: true));
      _loading = true;
    });
    _scrollDown();

    try {
      final systemPrompt = _getSystemPrompt(_selectedMode, name, cls);

      // Build conversation history
      final contents = <Map<String, dynamic>>[];
      for (int i = 0; i < _messages.length; i++) {
        final m = _messages[i];
        if (i == 0) {
          // First message includes system prompt
          contents.add({
            'role': 'user',
            'parts': [{'text': 'Context: $systemPrompt\n\nQuestion: ${m.text}'}],
          });
        } else {
          contents.add({
            'role': m.isUser ? 'user' : 'model',
            'parts': [{'text': m.text}],
          });
        }
      }

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_workingModel:generateContent?key=$_apiKey',
      );

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {'maxOutputTokens': 600, 'temperature': 0.7},
        }),
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final reply = candidates[0]['content']['parts'][0]['text'] as String? ?? 'No response';
          setState(() => _messages.add(Message(text: reply, isUser: false)));
        }
      } else {
        final errData = jsonDecode(res.body);
        final msg = errData['error']?['message'] ?? 'Status ${res.statusCode}';
        setState(() => _messages.add(Message(text: 'Error: $msg', isUser: false)));
      }
    } catch (e) {
      setState(() => _messages.add(Message(text: 'Connection error. Try again.', isUser: false)));
    }

    setState(() => _loading = false);
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final name = user?.fullName ?? 'Student';
    final cls = user is StudentModel ? (user as StudentModel).className : 'Class 1';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BDPHS AI Tutor', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            Text(_workingModel.isEmpty ? 'Connecting...' : _workingModel,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
          ]),
        ]),
        backgroundColor: AppColors.adminColor, foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () { setState(() { _messages.clear(); }); _findWorkingModel(); },
          ),
        ],
      ),
      body: _initializing
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: AppColors.adminColor),
              const SizedBox(height: 16),
              Text('Finding best AI model...', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            ]))
          : _initError.isNotEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('⚠️', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('AI Setup Issue', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.error)),
                const SizedBox(height: 8),
                Text(_initError, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _findWorkingModel,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text('Try Again', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ]),
            ))
          : Column(children: [
              // Mode chips
              Container(
                color: AppColors.adminColor.withValues(alpha: 0.06), height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _modes.length,
                  itemBuilder: (_, i) {
                    final mode = _modes[i];
                    final sel = _selectedMode == mode;
                    return GestureDetector(
                      onTap: () => setState(() {
  _selectedMode = mode;
  _messages.clear();
}),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.adminColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.adminColor : AppColors.divider),
                        ),
                        child: Text(mode, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textSecondary)),
                      ),
                    );
                  },
                ),
              ),
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? _WelcomeView(studentName: name, mode: _selectedMode, onSuggestion: (q) => _send(q, name, cls))
                    : ListView.builder(
                        controller: _scroll, padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_loading ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _messages.length) return const _TypingIndicator();
                          return _MessageBubble(message: _messages[i]);
                        },
                      ),
              ),
              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                decoration: BoxDecoration(color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -4))]),
                child: SafeArea(top: false, child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl, maxLines: 3, minLines: 1,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _selectedMode == 'English↔Hindi' ? 'Type a word to translate...'
                            : _selectedMode == 'Math Help' ? 'Type a math problem...'
                            : 'Ask anything in Hindi or English...',
                        hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
                        filled: true, fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (t) => _send(t, name, cls),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : () => _send(_ctrl.text, name, cls),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: _loading ? AppColors.divider : AppColors.adminColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_loading ? Icons.hourglass_empty_rounded : Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ])),
              ),
            ]),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final String studentName, mode;
  final void Function(String) onSuggestion;
  const _WelcomeView({required this.studentName, required this.mode, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> sugg = {
      'General': ['What is photosynthesis?', 'Who is APJ Abdul Kalam?', 'Why is the sky blue?', 'What is democracy?'],
      'English↔Hindi': ['Beautiful', 'Knowledge', 'Respect', 'Independence'],
      'Math Help': ['Solve: 15 × 24', 'LCM of 12 and 18?', 'Area of circle radius 7', 'Pythagoras theorem?'],
      'Science': ['What is photosynthesis?', 'How do magnets work?', 'What is evaporation?', 'Newton 1st law'],
      'Grammar': ['has vs have', 'What is a noun?', 'was vs were', 'What is a simile?'],
      'GK Quiz': ['Indian history quiz', 'World capitals quiz', 'Science facts quiz', 'Indian sports quiz'],
      'Yoga & Health': ['Yoga poses for Class 10 students', 'Morning yoga routine for kids', 'How to improve concentration with yoga', 'Breathing exercises for students'],
      'Diet & Nutrition': ['Healthy breakfast for school students', 'What to eat before exams?', 'Iron rich foods for growing children', 'How much water should students drink?'],
      'Bharat Ko Jano': ['Meaning of Jana Gana Mana', 'Who wrote Vande Mataram?', 'History of Indian national anthem', 'National anthem in Hindi'],
      'Study Tips': ['How to study effectively?', 'Memory tricks for exams', 'How to avoid distraction while studying?', 'Best time to study'],
    };
    final list = sugg[mode] ?? sugg['General']!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 16),
      const Center(child: Text('🤖', style: TextStyle(fontSize: 64))),
      const SizedBox(height: 16),
      Text('Namaste, $studentName! 🙏', textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.adminColor)),
      const SizedBox(height: 8),
      Text('Main aapka AI Tutor hoon!\nKuch bhi poochho — Hindi ya English mein.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
      const SizedBox(height: 24),
      Text('Try asking:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      ...list.map((s) => GestureDetector(
        onTap: () => onSuggestion(s),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.adminColor.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
          child: Row(children: [
            const Text('💬 ', style: TextStyle(fontSize: 14)),
            Expanded(child: Text(s, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary))),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.adminColor.withValues(alpha: 0.5)),
          ]),
        ),
      )),
    ]);
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});
  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.adminColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16)))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.adminColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
              ),
              child: Text(message.text, style: GoogleFonts.poppins(fontSize: 13, height: 1.5,
                  color: isUser ? Colors.white : AppColors.textPrimary)),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(width: 32, height: 32,
              decoration: BoxDecoration(color: AppColors.adminColor, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 18)),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 32, height: 32,
      decoration: BoxDecoration(color: AppColors.adminColor.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16)))),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Thinking...', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textHint)),
        const SizedBox(width: 8),
        const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminColor)),
      ]),
    ),
  ]);
}