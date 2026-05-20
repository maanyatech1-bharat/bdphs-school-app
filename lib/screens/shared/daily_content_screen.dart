// lib/screens/shared/daily_content_screen.dart
// Contains: Daily Inspiration, Assembly (Anthem+Prayer), Yoga (age-grouped),
//           Diet Chart (age-grouped), Exercise (age-grouped)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

// ══════════════════════════════════════
//  DAILY INSPIRATION SCREEN
// ══════════════════════════════════════
class DailyInspirationScreen extends StatelessWidget {
  const DailyInspirationScreen({super.key});

  static const List<Map<String, String>> _quotes = [
    {'q': 'पढ़ोगे लिखोगे बनोगे नवाब, खेलोगे कूदोगे होगे खराब।', 'a': 'लोकोक्ति', 'e': 'Study and write to become great; play recklessly and face ruin.'},
    {'q': 'Education is the most powerful weapon to change the world.', 'a': 'Nelson Mandela', 'e': 'शिक्षा दुनिया बदलने का सबसे शक्तिशाली हथियार है।'},
    {'q': 'हजारों मील की यात्रा एक कदम से शुरू होती है।', 'a': 'लाओ त्जे', 'e': 'A journey of a thousand miles begins with a single step.'},
    {'q': 'The future belongs to those who believe in the beauty of their dreams.', 'a': 'Eleanor Roosevelt', 'e': 'भविष्य उनका है जो अपने सपनों की सुंदरता पर विश्वास करते हैं।'},
    {'q': 'असफलता सफलता की पहली सीढ़ी है।', 'a': 'हिंदी कहावत', 'e': 'Failure is the first step to success.'},
    {'q': 'You are never too old to set another goal or to dream a new dream.', 'a': 'C.S. Lewis', 'e': 'नया लक्ष्य या नया सपना देखने के लिए आप कभी बूढ़े नहीं होते।'},
    {'q': 'मेहनत वो चाबी है जो किस्मत का ताला खोलती है।', 'a': 'हिंदी कहावत', 'e': 'Hard work is the key that unlocks the lock of destiny.'},
  ];

  Map<String, String> get _todaysQuote =>
      _quotes[DateTime.now().day % _quotes.length];

  static const List<Map<String, String>> _news = [
    {'title': '📚 NEP 2020: नई शिक्षा नीति लागू', 'desc': 'भारत में नई शिक्षा नीति के तहत छात्रों को व्यावसायिक शिक्षा मिलेगी।', 'category': 'Education'},
    {'title': '🚀 ISRO का नया मिशन', 'desc': 'भारत का अंतरिक्ष अनुसंधान संगठन चंद्रमा पर नया मिशन भेजने की तैयारी में।', 'category': 'Science'},
    {'title': '🏆 भारतीय खिलाड़ियों की जीत', 'desc': 'भारतीय टीम ने अंतर्राष्ट्रीय प्रतियोगिता में स्वर्ण पदक जीता।', 'category': 'Sports'},
    {'title': '🌿 पर्यावरण संरक्षण अभियान', 'desc': 'जम्मू-कश्मीर में वृक्षारोपण अभियान — 1 लाख पेड़ लगाने का लक्ष्य।', 'category': 'Environment'},
    {'title': '💡 डिजिटल इंडिया', 'desc': 'सरकार ने ग्रामीण क्षेत्रों में मुफ्त इंटरनेट देने की घोषणा की।', 'category': 'Technology'},
  ];

  @override
  Widget build(BuildContext context) {
    final quote = _todaysQuote;
    final today = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    final news = _news.sublist(0, 3);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Daily Inspiration',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(today,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 16),

          // ── Thought of the Day ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('💭', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Thought of the Day',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                Text('"${quote['q']}"',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Text('— ${quote['a']}',
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.white24),
                const SizedBox(height: 8),
                Text(quote['e'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white70, height: 1.4)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text: '"${quote['q']}" — ${quote['a']}'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Quote copied!'),
                        backgroundColor: AppColors.success));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.copy_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text('Copy Quote',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Today's News ────────────────────────────────────────
          Row(children: [
            const Text('📰', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text("Today's News",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ...news.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6)
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(n['category']!,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF7C3AED))),
                    ),
                    const SizedBox(height: 6),
                    Text(n['title']!,
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(n['desc']!,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4)),
                  ],
                ),
              )),
          const SizedBox(height: 20),

          // ── Quick Links ─────────────────────────────────────────
          Text('📱 Quick Links',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _QuickLink(
                  '🇮🇳 National Anthem',
                  const Color(0xFF059669),
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AssemblyScreen()))),
              // ✅ FIX: renamed to YogaAgeScreen — no more duplicate with more_screens.dart
              _QuickLink(
                  '🧘 Yoga Guide',
                  const Color(0xFFD97706),
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const YogaAgeScreen()))),
              _QuickLink(
                  '🥗 Diet Chart',
                  const Color(0xFF10B981),
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DietScreen()))),
              // ✅ FIX: renamed to ExerciseAgeScreen — no more duplicate with more_screens.dart
              _QuickLink(
                  '💪 Exercise',
                  const Color(0xFFEF4444),
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ExerciseAgeScreen()))),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Center(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color),
                textAlign: TextAlign.center),
          ),
        ),
      );
}

// ══════════════════════════════════════
//  ASSEMBLY SCREEN
// ══════════════════════════════════════
class AssemblyScreen extends StatefulWidget {
  const AssemblyScreen({super.key});
  @override
  State<AssemblyScreen> createState() => _AssemblyScreenState();
}

class _AssemblyScreenState extends State<AssemblyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Morning Assembly 🇮🇳',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'National Anthem'),
            Tab(text: 'Vande Mataram'),
            Tab(text: 'Prayer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _TextDisplay(
            title: 'जन गण मन — Jana Gana Mana',
            emoji: '🇮🇳',
            color: const Color(0xFFFF9933),
            content: '''जन गण मन अधिनायक जय हे,
भारत भाग्य विधाता।
पंजाब सिंध गुजरात मराठा,
द्राविड़ उत्कल बंग।
विंध्य हिमाचल यमुना गंगा,
उच्छल जलधि तरंग।
तव शुभ नामे जागे,
तव शुभ आशिष मांगे।
गाहे तव जय गाथा।
जन गण मंगलदायक जय हे,
भारत भाग्य विधाता।
जय हे! जय हे! जय हे!
जय जय जय जय हे!

— Jana Gana Mana adhinayaka jaya he,
Bharata-bhagya-vidhata.
Punjab Sindh Gujarat Maratha,
Dravida Utkala Banga.
Vindhya Himachala Yamuna Ganga,
Uchchala Jaladhi taranga.
Tava shubha name jage,
Tava shubha ashisa mange.
Gahe tava jaya-gatha.
Jana-gana-mangaladayaka jaya he,
Bharata-bhagya-vidhata.
Jaya he! Jaya he! Jaya he!
Jaya jaya jaya jaya he!

Composed by: Rabindranath Tagore
Adopted: 24 January 1950''',
          ),
          _TextDisplay(
            title: 'वंदे मातरम् — Vande Mataram',
            emoji: '🌸',
            color: const Color(0xFF138808),
            content: '''वंदे मातरम्!
सुजलाम् सुफलाम्
मलयज शीतलाम्
शस्यश्यामलाम् मातरम्!
वंदे मातरम्!

शुभ्र ज्योत्स्ना पुलकित यामिनीम्
फुल्लकुसुमित द्रुमदल शोभिनीम्
सुहासिनीम् सुमधुर भाषिणीम्
सुखदाम् वरदाम् मातरम्!
वंदे मातरम्!

— Vande Mataram!
Sujalam suphalam
Malayaja shitalam
Shashya shyamalam mataram!
Vande Mataram!

I bow to thee, Mother,
richly watered, richly fruited,
cool with the winds of the south,
dark with the crops of the harvests.

Composed by: Bankim Chandra Chattopadhyay
National Song of India''',
          ),
          _TextDisplay(
            title: 'School Prayer — प्रार्थना',
            emoji: '🙏',
            color: const Color(0xFF7C3AED),
            content: '''हे ईश्वर / O God,
हम सब को सद्बुद्धि दो।
Grant us wisdom and knowledge.

हम सच बोलें, सच सुनें,
May we speak truth and hear truth.

हम कर्तव्य पालन करें,
May we fulfill our duties.

हमारे माता-पिता और गुरुजनों की,
सेवा करने की शक्ति दो।
Give us strength to serve our
parents and teachers.

हमारा देश महान बने,
May our country become great.

हम अच्छे नागरिक बनें।
May we become good citizens.

🌸 OM SHANTI SHANTI SHANTI 🌸
ॐ शांति शांति शांति

— Morning Prayer
Blooming Dale Public High School
Jammu & Kashmir''',
          ),
        ],
      ),
    );
  }
}

class _TextDisplay extends StatelessWidget {
  final String title, content, emoji;
  final Color color;
  const _TextDisplay(
      {required this.title,
      required this.content,
      required this.emoji,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w800, color: color),
                textAlign: TextAlign.center),
            const Divider(height: 24),
            Text(content,
                style: GoogleFonts.poppins(
                    fontSize: 14, height: 1.9, color: AppColors.textPrimary)),
          ]),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$title copied!'), backgroundColor: color));
            },
            icon: const Icon(Icons.copy_rounded),
            label: Text('Copy Text',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: color),
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════
//  YOGA AGE-GROUP SCREEN
//  ✅ FIX: renamed from YogaScreen → YogaAgeScreen
//          (avoids conflict with YogaScreen in more_screens.dart)
// ══════════════════════════════════════
class YogaAgeScreen extends StatefulWidget {
  const YogaAgeScreen({super.key});
  @override
  State<YogaAgeScreen> createState() => _YogaAgeScreenState();
}

class _YogaAgeScreenState extends State<YogaAgeScreen> {
  String _selectedAge = 'Class 1-5 (6-11 years)';

  final Map<String, List<Map<String, dynamic>>> _yogaByAge = {
    'Nursery-KG (3-5 years)': [
      {'name': 'Butterfly Pose', 'hindi': 'तितली आसन', 'emoji': '🦋', 'steps': 'Sit with feet together. Hold ankles. Move knees up and down like butterfly wings.', 'benefit': 'Stretches inner thighs, improves focus', 'duration': '1-2 min'},
      {'name': 'Tree Pose', 'hindi': 'वृक्षासन', 'emoji': '🌳', 'steps': 'Stand straight. Place one foot on inner thigh. Balance with hands joined above head.', 'benefit': 'Improves balance and concentration', 'duration': '30 sec each side'},
      {'name': 'Cat-Cow Pose', 'hindi': 'मार्जरी आसन', 'emoji': '🐈', 'steps': 'On hands and knees. Arch back up (cat), then down (cow). Breathe slowly.', 'benefit': 'Strengthens spine, good for posture', 'duration': '1-2 min'},
    ],
    'Class 1-5 (6-11 years)': [
      {'name': 'Sun Salutation', 'hindi': 'सूर्य नमस्कार', 'emoji': '☀️', 'steps': '12 poses in sequence. Start standing, fold forward, plank, cobra, downward dog, and back. Do slowly.', 'benefit': 'Full body workout, improves flexibility', 'duration': '5-10 min (3 rounds)'},
      {'name': 'Warrior Pose', 'hindi': 'वीरभद्रासन', 'emoji': '⚔️', 'steps': 'Step one foot forward. Bend front knee. Raise arms above head. Look forward proudly!', 'benefit': 'Builds strength, confidence', 'duration': '1 min each side'},
      {'name': 'Child\'s Pose', 'hindi': 'बालासन', 'emoji': '🧘', 'steps': 'Kneel down. Sit back on heels. Stretch arms forward. Rest forehead on floor. Breathe deeply.', 'benefit': 'Relaxes body and mind, reduces stress', 'duration': '2-3 min'},
      {'name': 'Cobra Pose', 'hindi': 'भुजंगासन', 'emoji': '🐍', 'steps': 'Lie on stomach. Place palms near shoulders. Slowly lift chest up. Look forward or slightly up.', 'benefit': 'Strengthens back, opens chest', 'duration': '30 sec × 3'},
    ],
    'Class 6-10 (12-16 years)': [
      {'name': 'Sun Salutation', 'hindi': 'सूर्य नमस्कार', 'emoji': '☀️', 'steps': '12 poses — do 6-12 rounds for full benefit. Flow smoothly with breath.', 'benefit': 'Complete body fitness', 'duration': '10-15 min'},
      {'name': 'Triangle Pose', 'hindi': 'त्रिकोणासन', 'emoji': '📐', 'steps': 'Stand wide. Turn right foot out. Reach right hand to shin/floor. Left arm up. Look at left hand.', 'benefit': 'Strengthens legs, improves digestion', 'duration': '1 min each side'},
      {'name': 'Pranayama', 'hindi': 'प्राणायाम', 'emoji': '🌬️', 'steps': 'Anulom-Vilom: Close right nostril, breathe in left. Close left, breathe out right. Repeat.', 'benefit': 'Calms mind, improves concentration for studies', 'duration': '5-10 min'},
      {'name': 'Meditation', 'hindi': 'ध्यान', 'emoji': '🧘', 'steps': 'Sit comfortably. Close eyes. Focus on breathing. When mind wanders, gently bring back.', 'benefit': 'Reduces exam stress, improves memory', 'duration': '5-15 min'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final yogas = _yogaByAge[_selectedAge] ?? [];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Yoga Guide 🧘',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD97706),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          color: const Color(0xFFD97706).withValues(alpha: 0.1),
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _selectedAge,
            decoration: InputDecoration(
              labelText: 'Select Age Group / Class',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _yogaByAge.keys
                .map((k) => DropdownMenuItem(
                    value: k, child: Text(k, style: GoogleFonts.poppins())))
                .toList(),
            onChanged: (v) => setState(() => _selectedAge = v!),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: yogas.length,
            itemBuilder: (_, i) {
              final y = yogas[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withValues(alpha: 0.08),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                      ),
                      child: Row(children: [
                        Text(y['emoji'] as String,
                            style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(y['name'] as String,
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              Text(y['hindi'] as String,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFFD97706),
                                      fontWeight: FontWeight.w600)),
                              Row(children: [
                                const Icon(Icons.timer_rounded,
                                    size: 13, color: AppColors.textHint),
                                const SizedBox(width: 3),
                                Text(y['duration'] as String,
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textHint)),
                              ]),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Steps:',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(y['steps'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, height: 1.6)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(y['benefit'] as String,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════
//  DIET SCREEN
// ══════════════════════════════════════
class DietScreen extends StatefulWidget {
  const DietScreen({super.key});
  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  String _selectedClass = 'Class 1-5';
  final List<String> _classes = ['Nursery-KG', 'Class 1-5', 'Class 6-10'];

  final Map<String, Map<String, dynamic>> _dietData = {
    'Nursery-KG': {
      'age': '3-6 years',
      'calories': '1200-1400 kcal/day',
      'meals': {
        'Breakfast 7-8 AM': ['🥛 1 glass warm milk with Horlicks/Complan', '🍞 2 slices bread with butter or jam', '🍌 1 banana or seasonal fruit'],
        'Mid-Morning 10 AM': ['🍎 1 apple or orange', '🥜 Small handful of peanuts'],
        'Lunch 1 PM': ['🍚 1 cup rice or 2 chapati', '🫘 Dal (lentil soup)', '🥦 1 sabzi (vegetable)', '🥛 1 cup curd/dahi'],
        'Evening Snack 4 PM': ['🍞 Bread with peanut butter', '🥛 1 glass milk or lassi'],
        'Dinner 7 PM': ['🫓 2 chapati', '🥗 Sabzi', '🫘 Dal or egg'],
      },
    },
    'Class 1-5': {
      'age': '6-11 years',
      'calories': '1600-2000 kcal/day',
      'meals': {
        'Breakfast 7 AM': ['🥛 1 glass milk', '🍳 2 eggs OR 2 paranthas with dahi', '🍌 1 banana', '🌾 Handful of dry fruits'],
        'Tiffin/Snack 10 AM': ['🍱 Home tiffin: Roti-sabzi or rice-dal', '🍎 1 seasonal fruit', '🥤 Water — at least 2-3 glasses by now'],
        'Lunch 1 PM': ['🍚 2 cups rice or 3 chapati', '🫘 Dal + Rajma/Chhole once a week', '🥦 Green vegetable', '🥛 Curd or lassi', '🥗 Salad'],
        'Evening 4 PM': ['🍞 Bread-butter or biscuits', '🥛 Milk or lassi', '🍌 Fruit'],
        'Dinner 7:30 PM': ['🫓 3 chapati', '🥗 Mixed vegetable sabzi', '🫘 Dal', '🥛 1 glass milk before sleep'],
      },
    },
    'Class 6-10': {
      'age': '12-16 years',
      'calories': '2000-2500 kcal/day',
      'meals': {
        'Early Morning 6 AM': ['💧 2 glasses warm water', '🌾 Soaked almonds (5-7) + walnuts (2-3)', '🍌 1 banana (before exercise)'],
        'Breakfast 7:30 AM': ['🥛 1 glass milk with Horlicks', '🍳 3 eggs or 3 paranthas', '🌾 Porridge/Oats once a week', '🍎 1 fruit'],
        'Tiffin 10 AM': ['🍱 Heavy tiffin: Rice-dal-sabzi', '🥗 Sprouts chaat or sandwich'],
        'Lunch 1:30 PM': ['🍚 3 cups rice or 4 chapati', '🫘 Rajma/Dal/Chicken/Paneer', '🥦 2 vegetables', '🥛 Curd', '🥗 Salad'],
        'Evening 5 PM': ['🏃 After sports/exercise:', '🥤 Lassi or coconut water', '🍞 2 slices bread + peanut butter', '🍌 Banana'],
        'Dinner 8 PM': ['🫓 4 chapati', '🍲 Sabzi + Dal', '🐓 Non-veg (optional) 3x/week', '🥛 Milk before sleep'],
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    final diet = _dietData[_selectedClass]!;
    final meals = diet['meals'] as Map<String, List<String>>;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Diet Chart 🥗',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(
                labelText: 'Select Class Group',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _classes
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c, style: GoogleFonts.poppins())))
                  .toList(),
              onChanged: (v) => setState(() => _selectedClass = v!),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _InfoChip(Icons.person_rounded,
                      'Age: ${diet['age']}', const Color(0xFF10B981))),
              const SizedBox(width: 8),
              Expanded(
                  child: _InfoChip(Icons.local_fire_department_rounded,
                      diet['calories'] as String, Colors.orange)),
            ]),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meals.length,
            itemBuilder: (_, i) {
              final mealName = meals.keys.elementAt(i);
              final items = meals.values.elementAt(i);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.restaurant_rounded,
                            color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Text(mealName,
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF10B981))),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items
                            .map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(item,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13, height: 1.5)),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ),
        ]),
      );
}

// ══════════════════════════════════════
//  EXERCISE AGE-GROUP SCREEN
//  ✅ FIX: renamed from ExerciseScreen → ExerciseAgeScreen
//          (avoids conflict with ExerciseScreen in more_screens.dart)
// ══════════════════════════════════════
class ExerciseAgeScreen extends StatefulWidget {
  const ExerciseAgeScreen({super.key});
  @override
  State<ExerciseAgeScreen> createState() => _ExerciseAgeScreenState();
}

class _ExerciseAgeScreenState extends State<ExerciseAgeScreen> {
  String _selectedClass = 'Class 1-5';
  final List<String> _classes = ['Nursery-KG', 'Class 1-5', 'Class 6-10'];

  final Map<String, List<Map<String, dynamic>>> _exercises = {
    'Nursery-KG': [
      {'name': 'Running in Place', 'hindi': 'जगह पर दौड़', 'emoji': '🏃', 'reps': '1-2 minutes', 'desc': 'Run on the spot lifting knees high. Fun for small children!', 'benefit': 'Heart health, energy'},
      {'name': 'Jumping Jacks', 'hindi': 'उछल-कूद', 'emoji': '⭐', 'reps': '10-15 times', 'desc': 'Jump with arms and legs wide, then back together. Count loudly!', 'benefit': 'Full body movement'},
      {'name': 'Animal Walk', 'hindi': 'जानवरों की चाल', 'emoji': '🦁', 'reps': '5 minutes', 'desc': 'Walk like a bear (on all fours), hop like a frog, waddle like a duck!', 'benefit': 'Fun fitness for toddlers'},
    ],
    'Class 1-5': [
      {'name': 'Morning Jog', 'hindi': 'सुबह की दौड़', 'emoji': '🏃', 'reps': '10-15 min', 'desc': 'Light jog around the ground. Maintain steady pace. Breathe through nose.', 'benefit': 'Builds stamina, healthy lungs'},
      {'name': 'Push-ups (Modified)', 'hindi': 'पुश-अप', 'emoji': '💪', 'reps': '5-10 × 2 sets', 'desc': 'Knee push-ups for beginners. Keep back straight. Go down slowly, push up.', 'benefit': 'Strengthens arms and chest'},
      {'name': 'Jumping Jacks', 'hindi': 'जंपिंग जैक', 'emoji': '⭐', 'reps': '20-30 times', 'desc': 'Classic exercise! Jump, spread arms and legs, then close. Keep rhythm.', 'benefit': 'Cardio, coordination'},
      {'name': 'Skipping/Jump Rope', 'hindi': 'रस्सी कूदना', 'emoji': '🎗️', 'reps': '5-10 minutes', 'desc': 'Skip rope or jump without rope. Excellent for lower body strength.', 'benefit': 'Best cardio for children'},
      {'name': 'Plank', 'hindi': 'तख्ता', 'emoji': '🏋️', 'reps': '15-30 sec × 2', 'desc': 'Lie down. Push up on hands. Keep body straight like a plank. Hold!', 'benefit': 'Core strength, posture'},
    ],
    'Class 6-10': [
      {'name': 'Morning Run', 'hindi': 'सुबह की दौड़', 'emoji': '🏃', 'reps': '20-30 minutes', 'desc': 'Run at comfortable pace. Increase distance weekly. This is the BEST exercise!', 'benefit': 'Heart health, mental clarity for studies'},
      {'name': 'Push-ups', 'hindi': 'पुश-अप', 'emoji': '💪', 'reps': '15-20 × 3 sets', 'desc': 'Full push-ups. Keep core tight. Slow down = more benefit. Work up to 50/day!', 'benefit': 'Upper body strength'},
      {'name': 'Squats', 'hindi': 'स्क्वाट', 'emoji': '🦵', 'reps': '20-25 × 3 sets', 'desc': 'Stand, feet shoulder-width. Lower down like sitting on chair. Push up through heels.', 'benefit': 'Leg strength, metabolism'},
      {'name': 'Plank', 'hindi': 'तख्ता', 'emoji': '🏋️', 'reps': '1 minute × 3 sets', 'desc': 'Hold plank position. Focus on keeping hips level. Add time each week.', 'benefit': 'Core strength, back pain prevention'},
      {'name': 'Skipping', 'hindi': 'रस्सी कूदना', 'emoji': '🎗️', 'reps': '15-20 minutes', 'desc': 'Best cardio! Try different patterns — both feet, alternate feet, double unders.', 'benefit': 'Full cardio, coordination, weight management'},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final exercises = _exercises[_selectedClass] ?? [];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Exercise Guide 💪',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Select Class Group',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _classes
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(c, style: GoogleFonts.poppins())))
                .toList(),
            onChanged: (v) => setState(() => _selectedClass = v!),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: exercises.length,
            itemBuilder: (_, i) {
              final e = exercises[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['emoji'] as String,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e['name'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                          Text(e['hindi'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFFEF4444),
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(e['reps'] as String,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEF4444))),
                          ),
                          const SizedBox(height: 6),
                          Text(e['desc'] as String,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.5)),
                          const SizedBox(height: 6),
                          Text('✅ ${e['benefit']}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}