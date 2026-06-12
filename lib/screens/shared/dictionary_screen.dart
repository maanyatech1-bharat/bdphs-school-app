// lib/screens/shared/dictionary_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});
  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String _fromLang = 'English';
  String _toLang = 'Hindi';

  // ── Uses same .env key as AI chatbot — never hardcoded ──
  String _apiKey = '';

  // Models to try in order
  final List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-pro',
  ];

  final List<String> _languages = [
    'English', 'Hindi', 'Urdu', 'Punjabi', 'Sanskrit'
  ];

  final List<Map<String, String>> _quickWords = [
    {'w': 'Beautiful', 'h': 'सुंदर'},
    {'w': 'Knowledge', 'h': 'ज्ञान'},
    {'w': 'Respect', 'h': 'सम्मान'},
    {'w': 'Courage', 'h': 'साहस'},
    {'w': 'Honesty', 'h': 'ईमानदारी'},
    {'w': 'Freedom', 'h': 'स्वतंत्रता'},
    {'w': 'Discipline', 'h': 'अनुशासन'},
    {'w': 'Friendship', 'h': 'मित्रता'},
    {'w': 'Education', 'h': 'शिक्षा'},
    {'w': 'Success', 'h': 'सफलता'},
    {'w': 'Nature', 'h': 'प्रकृति'},
    {'w': 'Science', 'h': 'विज्ञान'},
  ];

  @override
  void initState() {
    super.initState();
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
      debugPrint('🔑 Gemini key loaded: ${key.isNotEmpty ? "YES (length: ${key.length})" : "EMPTY"}');
      if (mounted) setState(() => _apiKey = key);
    } catch (e) {
      debugPrint('Remote config error: $e');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _lookup(String word) async {
    if (word.trim().isEmpty) return;
    if (_apiKey.isEmpty) {
      await _loadApiKey();
    }
    if (_apiKey.isEmpty) {
      setState(() {
        _result = {'error': 'API key not loaded yet. Please try again.'};
        _loading = false;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _result = null; });

    final prompt =
        'You are a bilingual dictionary. For the word "$word" '
        '(from $_fromLang to $_toLang), return ONLY a valid JSON object. '
        'Keep all values under 15 words each. '
        'Fields: word, pronunciation, translation, meaning_english, '
        'meaning_hindi, part_of_speech, example_english, example_hindi, '
        'synonyms (array of 3 strings), antonyms (array of 2 strings). '
        'No markdown. ONLY the raw JSON object.';

    // Try each model until one works
    for (final model in _models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey',
        );
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [{'parts': [{'text': prompt}]}],
            'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.1},
          }),
        ).timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
          String clean = text.trim()
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final start = clean.indexOf('{');
          final end = clean.lastIndexOf('}');
          if (start != -1 && end != -1) {
            clean = clean.substring(start, end + 1);
          }
          final parsed = jsonDecode(clean) as Map<String, dynamic>;
          setState(() { _result = parsed; _loading = false; });
          return; // success — stop trying models
        }
        // If 429 or 503 try next model, else break
        if (res.statusCode != 429 && res.statusCode != 503) break;
      } catch (_) {
        continue; // try next model
      }
    }

    // All models failed
    if (mounted) {
      setState(() {
        _result = {'error': 'Could not find "$word". Check your internet and try again.'};
        _loading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Copied to clipboard!'),
      backgroundColor: AppColors.success,
      duration: Duration(seconds: 1),
    ));
  }

  void _swapLanguages() {
    setState(() {
      final temp = _fromLang;
      _fromLang = _toLang;
      _toLang = temp;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Dictionary 📖',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Language selector + Search
          Container(
            color: AppColors.info.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Language row
              Row(children: [
                Expanded(child: _LangDropdown(
                    value: _fromLang, label: 'From',
                    options: _languages,
                    onChanged: (v) => setState(() { _fromLang = v!; _result = null; }))),
                GestureDetector(
                  onTap: _swapLanguages,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.info, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: AppColors.info.withValues(alpha: 0.3), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
                  ),
                ),
                Expanded(child: _LangDropdown(
                    value: _toLang, label: 'To',
                    options: _languages,
                    onChanged: (v) => setState(() { _toLang = v!; _result = null; }))),
              ]),
              const SizedBox(height: 12),
              // Search box
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Type a word...',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.info),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () { _ctrl.clear(); setState(() => _result = null); })
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: _lookup,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _lookup(_ctrl.text),
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: AppColors.info.withValues(alpha: 0.3), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ]),
            ]),
          ),

          // Content
          Expanded(
            child: _loading
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(color: AppColors.info),
                    const SizedBox(height: 12),
                    Text('Looking up...', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                  ]))
                : _result != null
                    ? _result!.containsKey('error')
                        ? Center(child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text('😕', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(_result!['error'],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      color: AppColors.error, fontSize: 14)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _lookup(_ctrl.text),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.info),
                                child: Text('Try Again',
                                    style: GoogleFonts.poppins(color: Colors.white)),
                              ),
                            ]),
                          ))
                        : _ResultView(result: _result!, onCopy: _copyToClipboard)
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text('Quick Words',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: _quickWords.map((w) => GestureDetector(
                              onTap: () { _ctrl.text = w['w']!; _lookup(w['w']!); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.info.withValues(alpha: 0.3)),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4)],
                                ),
                                child: Column(children: [
                                  Text(w['w']!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppColors.info)),
                                  Text(w['h']!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11, color: AppColors.textSecondary)),
                                ]),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.info.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.info.withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              const Text('💡', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                'Type any English or Hindi word to get meaning, translation, pronunciation and examples!',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.5),
                              )),
                            ]),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── RESULT VIEW ──────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final Map<String, dynamic> result;
  final void Function(String) onCopy;
  const _ResultView({required this.result, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final synonyms = (result['synonyms'] as List<dynamic>?) ?? [];
    final antonyms = (result['antonyms'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Main card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(result['word'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                if (result['pronunciation'] != null)
                  Text('/${result['pronunciation']}/',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.white70,
                          fontStyle: FontStyle.italic)),
                if (result['part_of_speech'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(result['part_of_speech'] ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
              ])),
              GestureDetector(
                onTap: () => onCopy(result['word'] ?? ''),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white24),
            const SizedBox(height: 16),
            Text('Translation',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w600)),
            Text(result['translation'] ?? '',
                style: GoogleFonts.poppins(
                    fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Expanded(child: _InfoCard('🇬🇧 English Meaning',
              result['meaning_english'] ?? '', AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: _InfoCard('🇮🇳 Hindi Meaning',
              result['meaning_hindi'] ?? '', AppColors.success)),
        ]),
        const SizedBox(height: 12),

        _ExampleCard('Example (English)',
            result['example_english'] ?? '', AppColors.primary, onCopy),
        const SizedBox(height: 10),
        _ExampleCard('Example (Hindi)',
            result['example_hindi'] ?? '', AppColors.success, onCopy),
        const SizedBox(height: 16),

        if (synonyms.isNotEmpty) ...[
          Text('Synonyms (Similar words)',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6,
              children: synonyms.map((s) =>
                  _WordChip(s.toString(), AppColors.primary)).toList()),
          const SizedBox(height: 12),
        ],

        if (antonyms.isNotEmpty) ...[
          Text('Antonyms (Opposite words)',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6,
              children: antonyms.map((s) =>
                  _WordChip(s.toString(), AppColors.error)).toList()),
          const SizedBox(height: 16),
        ],

        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onCopy(
                  '${result['word']} = ${result['translation']}\n'
                  'Meaning: ${result['meaning_english']}\n'
                  'Hindi: ${result['meaning_hindi']}\n'
                  'Example: ${result['example_english']}'),
              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
              label: Text('Copy All',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onCopy(
                  '${result['word']}: ${result['translation']}\n'
                  '${result['example_english']}\n'
                  '${result['example_hindi']}'),
              icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
              label: Text('Copy & Share',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 80),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title, content;
  final Color color;
  const _InfoCard(this.title, this.content, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 6),
          Text(content, style: GoogleFonts.poppins(
              fontSize: 13, height: 1.4, color: AppColors.textPrimary)),
        ]),
      );
}

class _ExampleCard extends StatelessWidget {
  final String title, sentence;
  final Color color;
  final void Function(String) onCopy;
  const _ExampleCard(this.title, this.sentence, this.color, this.onCopy);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text('"$sentence"', style: GoogleFonts.poppins(
                fontSize: 13, fontStyle: FontStyle.italic, height: 1.4)),
          ])),
          IconButton(
              icon: Icon(Icons.copy_rounded, size: 16, color: color),
              onPressed: () => onCopy(sentence)),
        ]),
      );
}

class _WordChip extends StatelessWidget {
  final String word;
  final Color color;
  const _WordChip(this.word, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(word, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );
}

class _LangDropdown extends StatelessWidget {
  final String value, label;
  final List<String> options;
  final void Function(String?) onChanged;
  const _LangDropdown({required this.value, required this.label,
      required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider)),
          child: DropdownButton<String>(
            value: value, isExpanded: true, underline: const SizedBox(),
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            items: options.map((o) =>
                DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: onChanged,
          ),
        ),
      ]);
}