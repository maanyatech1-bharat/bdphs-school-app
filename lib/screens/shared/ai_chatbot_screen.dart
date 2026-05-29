// lib/screens/shared/ai_chatbot_screen.dart
// BDPHS AI Tutor — uses direct HTTP to Gemini REST API (no package issues)
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../theme/app_theme.dart';

// ─── Message ───────────────────────────────────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser;
  _Msg({required this.text, required this.isUser});
}

// ─── Categories ────────────────────────────────────────────────────────────────
class _Cat {
  final String label, emoji, prompt;
  const _Cat(this.label, this.emoji, this.prompt);
}

const _cats = [
  _Cat('General', '💬',
      'You are BDPHS AI Tutor at Blooming Dale Public High School, J&K. '
      'Answer helpfully in the same language the student uses (Hindi or English).'),
  _Cat('English↔Hindi', '🌐',
      'You are a translator. If input is English → translate to Hindi. '
      'If input is Hindi → translate to English. Be accurate.'),
  _Cat('Math Help', '➗',
      'You are a maths tutor for Class 1–10 Indian school students. '
      'Solve step by step clearly using simple language.'),
  _Cat('Science', '🔬',
      'You are a science tutor for Class 1–10 students. '
      'Cover Physics, Chemistry, Biology with simple examples.'),
  _Cat('Hindi', '📖',
      'You are a Hindi language tutor. Help with grammar, essays, '
      'letters, poems and comprehension for school students.'),
  _Cat('English', '✍️',
      'You are an English language tutor. Help with grammar, essays, '
      'letters, comprehension and vocabulary for school students.'),
  _Cat('GK', '🌍',
      'You are a GK tutor. Provide accurate GK, history, geography, '
      'civics and current affairs for Indian school students.'),
];

// ─── Confirmed working models for this API key ────────────────────────────────
const _models = [
  'gemini-2.5-flash',        // ✅ Best — stable & fast
  'gemini-2.0-flash',        // ✅ Fallback
  'gemini-2.0-flash-lite',   // ✅ Fallback
  'gemini-flash-latest',     // ✅ Fallback
  'gemini-2.5-flash-lite',   // ✅ Fallback
];

// ─── Screen ────────────────────────────────────────────────────────────────────
class AiChatbotScreen extends StatefulWidget {
  const AiChatbotScreen({super.key});
  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  int  _catIdx   = 0;
  bool _loading  = false;
  String _apiKey = '';
  bool _keyMissing = true;

  @override
  void initState() {
    super.initState();
    _apiKey     = '';
    _keyMissing = true;
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ));
      await rc.fetchAndActivate();
      final key = rc.getString('gemini_api_key');
      if (mounted) {
        setState(() {
          _apiKey     = key;
          _keyMissing = key.isEmpty || key == 'YOUR_GEMINI_API_KEY';
        });
        if (!_keyMissing) _addWelcome();
      }
    } catch (e) {
      if (mounted) setState(() => _keyMissing = true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addWelcome() {
    _msgs.add(_Msg(
      text: 'Namaste! 🙏 I am BDPHS AI Tutor.\n\n'
            'I can help you with:\n'
            '• Math problems & solutions\n'
            '• Science concepts\n'
            '• English & Hindi\n'
            '• General Knowledge\n'
            '• Translation\n\n'
            'Select a subject above and ask me anything! 😊',
      isUser: false,
    ));
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  // ✅ Direct HTTP call — works with any valid Gemini API key
  Future<String?> _callGemini(String userText) async {
    final systemPrompt = _cats[_catIdx].prompt;

    // Build conversation — prepend system prompt to first user message
    final contents = <Map<String, dynamic>>[];
    for (final m in _msgs) {
      contents.add({
        'role': m.isUser ? 'user' : 'model',
        'parts': [{'text': m.text}],
      });
    }
    contents.add({'role': 'user', 'parts': [{'text': userText}]});

    // Make sure first message is from user (required by Gemini)
    if (contents.isNotEmpty && contents.first['role'] != 'user') {
      contents.removeAt(0);
    }

    // Prepend system prompt to current message
    final fullText = '$systemPrompt\n\nUser: $userText';
    final simpleContents = [
      {'role': 'user', 'parts': [{'text': fullText}]}
    ];

    for (final model in _models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$_apiKey',
        );
        final res = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': simpleContents,
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1024,
            },
          }),
        ).timeout(const Duration(seconds: 30));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
              as String?;
          if (text != null && text.isNotEmpty) return text;
        }

        // Show the actual error from Google
        try {
          final err = jsonDecode(res.body);
          final msg = err['error']?['message'] as String? ?? '';
          if (msg.isNotEmpty) {
            // Model not found → try next
            if (msg.contains('not found') || msg.contains('not supported') ||
                res.statusCode == 404) {
              continue;
            }
            // Real error (invalid key, quota, etc.)
            return '⚠️ Error ${res.statusCode}: $msg';
          }
        } catch (_) {}

        if (res.statusCode == 404 || res.statusCode == 400) continue;
      } catch (e) {
        // Network error — show details
        final detail = e.toString();
        if (detail.contains('SocketException') ||
            detail.contains('Connection refused') ||
            detail.contains('timeout')) {
          return '⚠️ No internet connection. Please check your network and try again.';
        }
        continue;
      }
    }
    return '⚠️ All models unavailable. Please check your API key at aistudio.google.com';
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    _ctrl.clear();

    setState(() {
      _msgs.add(_Msg(text: text, isUser: true));
      _loading = true;
    });
    _scrollDown();

    final reply = await _callGemini(text);
    setState(() {
      _msgs.add(_Msg(
          text: reply ?? 'Sorry, no response received.',
          isUser: false));
      _loading = false;
    });
    _scrollDown();
  }

  void _clearChat() {
    setState(() { _msgs.clear(); _addWelcome(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BDPHS AI Tutor',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text('gemini-2.5-flash',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Clear chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: _keyMissing ? _setupScreen() : Column(children: [
        // Category chips
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: List.generate(_cats.length, (i) {
              final cat = _cats[i];
              final sel = _catIdx == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _catIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF7C3AED)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? const Color(0xFF7C3AED)
                              : Colors.grey.shade300),
                    ),
                    child: Text('${cat.emoji} ${cat.label}',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white
                                : AppColors.textPrimary)),
                  ),
                ),
              );
            })),
          ),
        ),
        const Divider(height: 1),

        // Messages
        Expanded(child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          itemCount: _msgs.length + (_loading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _msgs.length) return _typingIndicator();
            return _bubble(_msgs[i]);
          },
        )),

        // Input
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ask anything in Hindi or English...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textHint),
                  filled: true, fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: Color(0xFF7C3AED), width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loading ? null : _send,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: _loading ? Colors.grey.shade300
                      : const Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _loading ? Icons.hourglass_empty_rounded
                      : Icons.send_rounded,
                  color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(_Msg msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(bottom: 8,
          left: isUser ? 48 : 0, right: isUser ? 0 : 48),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Color(0xFF7C3AED), size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF7C3AED) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6)],
            ),
            child: Text(msg.text,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isUser ? Colors.white : AppColors.textPrimary,
                    height: 1.5)),
          )),
        ],
      ),
    );
  }

  Widget _typingIndicator() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Color(0xFF7C3AED), size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6)],
            ),
            child: Row(children: [
              _dot(0), _dot(200), _dot(400),
            ]),
          ),
        ]),
      );

  Widget _dot(int delay) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: Duration(milliseconds: 600 + delay),
        builder: (_, v, __) => Container(
          width: 7, height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Color.lerp(Colors.grey.shade300,
                const Color(0xFF7C3AED), v),
            shape: BoxShape.circle,
          ),
        ),
      );

  Widget _setupScreen() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.warning_amber_rounded,
          size: 72, color: Color(0xFFD97706)),
      const SizedBox(height: 16),
      Text('AI Setup Required',
          style: GoogleFonts.poppins(fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFDC2626))),
      const SizedBox(height: 12),
      Text('Add your Gemini API key to the .env file',
          style: GoogleFonts.poppins(fontSize: 14),
          textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('In Terminal run:',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'echo "GEMINI_API_KEY=your_key" > .env',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 10),
          Text('Get key at: aistudio.google.com/app/apikey',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    ]),
  ));
}