// lib/screens/shared/ai_chatbot_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({super.key});
  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  final List<Map<String, dynamic>> _history = [];
  bool _loading = false;

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg('Hello! I am your BDPHS AI Tutor. How can I help you today?', false));
    _history.add({
      'role': 'system',
      'content': 'You are a helpful school assistant for BDPHS school. Help students, teachers and admins with questions about studies, school activities, homework help, and general knowledge. Be friendly, encouraging and educational. Keep responses concise.',
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_Msg(text.trim(), true));
      _loading = true;
    });
    _scrollDown();

    _history.add({'role': 'user', 'content': text.trim()});

    try {
      final geminiHistory = _history
          .where((m) => m['role'] != 'system')
          .map((m) => {
            'role': m['role'] == 'assistant' ? 'model' : 'user',
            'parts': [{'text': m['content']}]
          }).toList();
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': geminiHistory}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'] as String;
        _history.add({'role': 'assistant', 'content': reply});
        setState(() => _msgs.add(_Msg(reply.trim(), false)));
      } else {
        final err = jsonDecode(response.body);
        final errMsg = err['error']['message'] ?? 'Unknown error';
        setState(() => _msgs.add(_Msg('Error: $errMsg', false)));
        _history.removeLast();
      }
    } catch (e) {
      setState(() => _msgs.add(_Msg('Network error. Please check your connection.', false)));
      _history.removeLast();
    } finally {
      setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final userName = user?.fullName ?? 'You';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.smart_toy_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Tutor', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            Text('BDPHS School Assistant', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
          ]),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {
              _msgs.clear();
              _history.clear();
              _msgs.add(_Msg('Hello! I am your BDPHS AI Tutor. How can I help you today?', false));
              _history.add({
                'role': 'system',
                'content': 'You are a helpful school assistant for BDPHS school. Help students, teachers and admins with questions about studies, school activities, homework help, and general knowledge. Be friendly, encouraging and educational. Keep responses concise.',
              });
            }),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final q in ['Study tips', 'Help with math', 'Explain a concept', 'Check my grammar', 'General knowledge'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q, style: GoogleFonts.poppins(fontSize: 12)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    onPressed: () => _send(q),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _msgs.length + (_loading ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _msgs.length) {
                return Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                    ),
                    child: Text('Typing...', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
                  ),
                ]);
              }
              final m = _msgs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!m.isUser) ...[
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: m.isUser ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(m.isUser ? 16 : 4),
                            bottomRight: Radius.circular(m.isUser ? 4 : 16)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)]),
                        child: Text(m.text, style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: m.isUser ? Colors.white : Colors.black87,
                            height: 1.5)),
                      ),
                    ),
                    if (m.isUser) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                onSubmitted: _send,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _loading ? null : () => _send(_ctrl.text),
              backgroundColor: _loading ? Colors.grey[300] : AppColors.primary,
              elevation: 0,
              child: _loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;
  _Msg(this.text, this.isUser);
}