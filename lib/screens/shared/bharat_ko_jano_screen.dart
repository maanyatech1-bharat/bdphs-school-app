// lib/screens/shared/bharat_ko_jano_screen.dart
// AI-powered daily quiz — 30 questions, 13 categories
// Uses Gemini API (same key as AI chatbot — from .env)

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import '../../theme/app_theme.dart';

// ════════════════════════════════════════════════════════════════════════════
//  MODEL
// ════════════════════════════════════════════════════════════════════════════
class _Question {
  final String question, questionHi, explanation, category;
  final List<String> options, optionsHi;
  final int correctIndex;

  const _Question({
    required this.question, required this.questionHi,
    required this.options, required this.optionsHi,
    required this.correctIndex, required this.explanation,
    required this.category,
  });

  factory _Question.fromJson(Map<String, dynamic> j) => _Question(
    question: j['question'] ?? '',
    questionHi: j['questionHi'] ?? j['question'] ?? '',
    options: List<String>.from(j['options'] ?? []),
    optionsHi: List<String>.from(j['optionsHi'] ?? j['options'] ?? []),
    correctIndex: j['correctIndex'] ?? 0,
    explanation: j['explanation'] ?? '',
    category: j['category'] ?? '🇮🇳 General',
  );
}

// ════════════════════════════════════════════════════════════════════════════
//  FALLBACK QUESTION BANK  (35 diverse questions, all categories)
// ════════════════════════════════════════════════════════════════════════════
const List<Map<String, dynamic>> _fallback = [
  // ── HISTORY ──────────────────────────────────────────────────────────────
  {'category':'🏛 History','question':'Who gave the slogan "Jai Hind"?','questionHi':'"जय हिंद" का नारा किसने दिया?','options':['Mahatma Gandhi','Subhas Chandra Bose','Bhagat Singh','Jawaharlal Nehru'],'optionsHi':['महात्मा गांधी','सुभाष चंद्र बोस','भगत सिंह','जवाहरलाल नेहरू'],'correctIndex':1,'explanation':'Netaji Subhas Chandra Bose coined "Jai Hind" as the patriotic slogan of the Indian National Army (INA).'},
  {'category':'🏛 History','question':'The Jallianwala Bagh massacre took place in which year?','questionHi':'जलियांवाला बाग हत्याकांड किस वर्ष हुआ?','options':['1915','1919','1921','1930'],'optionsHi':['1915','1919','1921','1930'],'correctIndex':1,'explanation':'On 13 April 1919, General Dyer ordered firing on unarmed civilians in Amritsar\'s Jallianwala Bagh.'},
  {'category':'🏛 History','question':'Who founded the Maurya Empire?','questionHi':'मौर्य साम्राज्य की स्थापना किसने की?','options':['Ashoka','Chandragupta Maurya','Bindusara','Chanakya'],'optionsHi':['अशोक','चंद्रगुप्त मौर्य','बिंदुसार','चाणक्य'],'correctIndex':1,'explanation':'Chandragupta Maurya founded the Maurya Empire around 321 BCE with Chanakya\'s guidance.'},
  // ── GEOGRAPHY ────────────────────────────────────────────────────────────
  {'category':'🗺 Geography','question':'Which is the largest desert in India?','questionHi':'भारत का सबसे बड़ा मरुस्थल कौन सा है?','options':['Thar Desert','Rann of Kutch','Deccan Plateau','Ladakh Cold Desert'],'optionsHi':['थार मरुस्थल','रण of कच्छ','दक्कन पठार','लद्दाख शीत मरुस्थल'],'correctIndex':0,'explanation':'The Thar Desert in Rajasthan is the largest desert in India and the 9th largest in the world.'},
  {'category':'🗺 Geography','question':'Which river is called the "Sorrow of Bihar"?','questionHi':'किस नदी को "बिहार का शोक" कहा जाता है?','options':['Ganga','Son','Kosi','Gandak'],'optionsHi':['गंगा','सोन','कोसी','गंडक'],'correctIndex':2,'explanation':'The Kosi river is called the Sorrow of Bihar due to its devastating and frequent floods.'},
  {'category':'🗺 Geography','question':'India shares its longest border with which country?','questionHi':'भारत की सबसे लंबी सीमा किस देश से लगती है?','options':['China','Pakistan','Nepal','Bangladesh'],'optionsHi':['चीन','पाकिस्तान','नेपाल','बांग्लादेश'],'correctIndex':3,'explanation':'India shares its longest border (approx. 4,156 km) with Bangladesh.'},
  // ── POLITY ───────────────────────────────────────────────────────────────
  {'category':'⚖ Polity','question':'Article 21A of Indian Constitution deals with?','questionHi':'भारतीय संविधान का अनुच्छेद 21A किससे संबंधित है?','options':['Freedom of Speech','Right to Education','Right to Work','Right to Food'],'optionsHi':['भाषण की स्वतंत्रता','शिक्षा का अधिकार','काम का अधिकार','भोजन का अधिकार'],'correctIndex':1,'explanation':'Article 21A provides free and compulsory education to children aged 6-14 years (86th Amendment, 2002).'},
  {'category':'⚖ Polity','question':'The Indian Constitution was adopted on?','questionHi':'भारतीय संविधान को कब अपनाया गया?','options':['15 Aug 1947','26 Jan 1950','26 Nov 1949','2 Oct 1948'],'optionsHi':['15 अगस्त 1947','26 जनवरी 1950','26 नवंबर 1949','2 अक्टूबर 1948'],'correctIndex':2,'explanation':'The Constitution was adopted on 26 November 1949 and came into effect on 26 January 1950 (Republic Day).'},
  // ── GITA ─────────────────────────────────────────────────────────────────
  {'category':'📖 Gita','question':'The Bhagavad Gita is set on which battlefield?','questionHi':'भगवद गीता किस युद्धभूमि पर स्थित है?','options':['Lanka','Mathura','Kurukshetra','Ayodhya'],'optionsHi':['लंका','मथुरा','कुरुक्षेत्र','अयोध्या'],'correctIndex':2,'explanation':'The Gita dialogue between Lord Krishna and Arjuna took place on the battlefield of Kurukshetra before the Mahabharata war.'},
  {'category':'📖 Gita','question':'How many chapters does the Bhagavad Gita have?','questionHi':'भगवद गीता में कितने अध्याय हैं?','options':['14','16','18','20'],'optionsHi':['14','16','18','20'],'correctIndex':2,'explanation':'The Bhagavad Gita has 18 chapters (Adhyayas) and 700 verses (shlokas).'},
  // ── MAHABHARATA ──────────────────────────────────────────────────────────
  {'category':'🏹 Mahabharata','question':'Who was the guru of both Pandavas and Kauravas?','questionHi':'पांडवों और कौरवों के गुरु कौन थे?','options':['Bhishma','Vidura','Dronacharya','Kripacharya'],'optionsHi':['भीष्म','विदुर','द्रोणाचार्य','कृपाचार्य'],'correctIndex':2,'explanation':'Dronacharya was the royal guru who taught archery and warfare to both Pandavas and Kauravas.'},
  {'category':'🏹 Mahabharata','question':'The Mahabharata war lasted for how many days?','questionHi':'महाभारत युद्ध कितने दिनों तक चला?','options':['14 days','16 days','18 days','21 days'],'optionsHi':['14 दिन','16 दिन','18 दिन','21 दिन'],'correctIndex':2,'explanation':'The Kurukshetra War lasted for 18 days, the same as the number of parvas in the Mahabharata.'},
  // ── RAMAYANA ─────────────────────────────────────────────────────────────
  {'category':'🏵 Ramayana','question':'Who built the bridge (Setu) to Lanka?','questionHi':'लंका तक सेतु किसने बनाया?','options':['Hanuman','Nala and Neela','Sugriva','Jambavan'],'optionsHi':['हनुमान','नल और नील','सुग्रीव','जाम्बवान'],'correctIndex':1,'explanation':'Nala and Neela, the divine architects among the Vanaras, built the Ram Setu bridge to Lanka.'},
  {'category':'🏵 Ramayana','question':'Ramayana has how many kandas (sections)?','questionHi':'रामायण में कितने कांड हैं?','options':['5','6','7','8'],'optionsHi':['5','6','7','8'],'correctIndex':2,'explanation':'Valmiki\'s Ramayana has 7 Kandas: Bala, Ayodhya, Aranya, Kishkindha, Sundara, Yuddha, and Uttara Kanda.'},
  // ── CULTURE ──────────────────────────────────────────────────────────────
  {'category':'💃 Culture','question':'Odissi classical dance belongs to which state?','questionHi':'ओडिसी शास्त्रीय नृत्य किस राज्य का है?','options':['Andhra Pradesh','West Bengal','Odisha','Assam'],'optionsHi':['आंध्र प्रदेश','पश्चिम बंगाल','ओडिशा','असम'],'correctIndex':2,'explanation':'Odissi originated in the temples of Odisha and is one of India\'s oldest classical dance forms.'},
  {'category':'💃 Culture','question':'Which is the classical dance form of Kerala?','questionHi':'केरल का शास्त्रीय नृत्य कौन सा है?','options':['Bharatanatyam','Mohiniyattam','Kuchipudi','Manipuri'],'optionsHi':['भरतनाट्यम','मोहिनीअट्टम','कुचिपुड़ी','मणिपुरी'],'correctIndex':1,'explanation':'Mohiniyattam is the classical dance of Kerala, performed by women and known for its graceful, swaying movements.'},
  // ── CLIMATE ──────────────────────────────────────────────────────────────
  {'category':'🌦 Climate','question':'Which place in India receives the highest annual rainfall?','questionHi':'भारत में सर्वाधिक वार्षिक वर्षा कहाँ होती है?','options':['Cherrapunji','Mawsynram','Agumbe','Coorg'],'optionsHi':['चेरापूंजी','मॉसिनराम','अगुंबे','कूर्ग'],'correctIndex':1,'explanation':'Mawsynram in Meghalaya receives the highest average annual rainfall (~11,871 mm) in the world.'},
  {'category':'🌦 Climate','question':'Southwest monsoon enters India through which state first?','questionHi':'दक्षिण-पश्चिम मानसून सबसे पहले किस राज्य में प्रवेश करता है?','options':['Tamil Nadu','Goa','Kerala','Karnataka'],'optionsHi':['तमिलनाडु','गोवा','केरल','कर्नाटक'],'correctIndex':2,'explanation':'The Southwest monsoon normally arrives in Kerala by June 1st, making it the first state to receive monsoon rains.'},
  // ── SCIENCE ──────────────────────────────────────────────────────────────
  {'category':'🔬 Science','question':'What is the chemical formula of water?','questionHi':'पानी का रासायनिक सूत्र क्या है?','options':['HO','H2O','H2O2','OH'],'optionsHi':['HO','H2O','H2O2','OH'],'correctIndex':1,'explanation':'Water (H2O) has 2 hydrogen atoms and 1 oxygen atom bonded together — essential for all life on Earth.'},
  {'category':'🔬 Science','question':'Which organ of the body produces insulin?','questionHi':'शरीर का कौन सा अंग इंसुलिन बनाता है?','options':['Liver','Kidney','Pancreas','Heart'],'optionsHi':['यकृत','गुर्दा','अग्नाशय','हृदय'],'correctIndex':2,'explanation':'The pancreas produces insulin, a hormone that regulates blood sugar levels in the body.'},
  {'category':'🔬 Science','question':'What is the powerhouse of the cell?','questionHi':'कोशिका का पावरहाउस क्या है?','options':['Nucleus','Ribosome','Mitochondria','Chloroplast'],'optionsHi':['केंद्रक','राइबोसोम','माइटोकॉन्ड्रिया','क्लोरोप्लास्ट'],'correctIndex':2,'explanation':'Mitochondria produce ATP (energy) through cellular respiration, earning the title "powerhouse of the cell".'},
  {'category':'🔬 Science','question':'Which planet is known as the Red Planet?','questionHi':'किस ग्रह को लाल ग्रह कहा जाता है?','options':['Venus','Jupiter','Mars','Saturn'],'optionsHi':['शुक्र','बृहस्पति','मंगल','शनि'],'correctIndex':2,'explanation':'Mars appears red due to iron oxide (rust) on its surface, earning the nickname "Red Planet".'},
  {'category':'🔬 Science','question':'Who discovered penicillin?','questionHi':'पेनिसिलिन की खोज किसने की?','options':['Marie Curie','Louis Pasteur','Alexander Fleming','Edward Jenner'],'optionsHi':['मैरी क्यूरी','लुई पाश्चर','अलेक्जेंडर फ्लेमिंग','एडवर्ड जेनर'],'correctIndex':2,'explanation':'Alexander Fleming discovered penicillin in 1928, revolutionizing medicine and saving millions of lives.'},
  // ── GREAT PERSONALITIES ──────────────────────────────────────────────────
  {'category':'🌟 Great Personalities','question':'Who is known as the "Missile Man of India"?','questionHi':'"भारत के मिसाइल मैन" के नाम से कौन जाने जाते हैं?','options':['Vikram Sarabhai','APJ Abdul Kalam','Homi Bhabha','Satish Dhawan'],'optionsHi':['विक्रम साराभाई','ए.पी.जे. अब्दुल कलाम','होमी भाभा','सतीश धवन'],'correctIndex':1,'explanation':'Dr. APJ Abdul Kalam, India\'s 11th President, is known as the Missile Man for his role in India\'s missile development program.'},
  {'category':'🌟 Great Personalities','question':'Who is known as the "Iron Man of India"?','questionHi':'"भारत के लौह पुरुष" के नाम से कौन जाने जाते हैं?','options':['Jawaharlal Nehru','Mahatma Gandhi','Sardar Vallabhbhai Patel','Bhagat Singh'],'optionsHi':['जवाहरलाल नेहरू','महात्मा गांधी','सरदार वल्लभभाई पटेल','भगत सिंह'],'correctIndex':2,'explanation':'Sardar Vallabhbhai Patel unified 562 princely states into the Indian Union after independence, earning the title "Iron Man of India".'},
  {'category':'🌟 Great Personalities','question':'Who is the "Father of the Indian Constitution"?','questionHi':'"भारतीय संविधान के जनक" कौन हैं?','options':['Jawaharlal Nehru','Mahatma Gandhi','B.R. Ambedkar','Rajendra Prasad'],'optionsHi':['जवाहरलाल नेहरू','महात्मा गांधी','बी.आर. अंबेडकर','राजेंद्र प्रसाद'],'correctIndex':2,'explanation':'Dr. B.R. Ambedkar chaired the Drafting Committee and is the principal architect of the Indian Constitution.'},
  // ── SPORTS ───────────────────────────────────────────────────────────────
  {'category':'🏅 Sports','question':'Who won India\'s first individual Olympic gold medal?','questionHi':'भारत का पहला व्यक्तिगत ओलंपिक स्वर्ण पदक किसने जीता?','options':['Milkha Singh','P.T. Usha','Abhinav Bindra','Saina Nehwal'],'optionsHi':['मिल्खा सिंह','पी.टी. उषा','अभिनव बिंद्रा','साइना नेहवाल'],'correctIndex':2,'explanation':'Abhinav Bindra won India\'s first individual Olympic gold medal in 10m Air Rifle at the 2008 Beijing Olympics.'},
  {'category':'🏅 Sports','question':'India won its first Cricket World Cup in which year?','questionHi':'भारत ने पहली बार क्रिकेट विश्व कप किस वर्ष जीता?','options':['1975','1979','1983','1987'],'optionsHi':['1975','1979','1983','1987'],'correctIndex':2,'explanation':'Under Kapil Dev\'s captaincy, India won the 1983 Cricket World Cup by defeating West Indies in the final.'},
  {'category':'🏅 Sports','question':'Neeraj Chopra won gold in which event at 2020 Tokyo Olympics?','questionHi':'नीरज चोपड़ा ने 2020 टोक्यो ओलंपिक में किस स्पर्धा में स्वर्ण जीता?','options':['High Jump','Discus Throw','Javelin Throw','Shot Put'],'optionsHi':['ऊंची कूद','चक्का फेंक','भाला फेंक','गोला फेंक'],'correctIndex':2,'explanation':'Neeraj Chopra won India\'s gold medal in Javelin Throw at the 2020 Tokyo Olympics with a throw of 87.58 metres.'},
  // ── CURRENT AFFAIRS ──────────────────────────────────────────────────────
  {'category':'📰 Current Affairs','question':'Chandrayaan-3 successfully landed near which part of the Moon?','questionHi':'चंद्रयान-3 चंद्रमा के किस भाग के पास सफलतापूर्वक उतरा?','options':['North Pole','Equator','South Pole','Dark Side'],'optionsHi':['उत्तरी ध्रुव','भूमध्य रेखा','दक्षिणी ध्रुव','अंधेरा पक्ष'],'correctIndex':2,'explanation':'On 23 August 2023, Chandrayaan-3 made India the first country to land a spacecraft near the Moon\'s South Pole.'},
  {'category':'📰 Current Affairs','question':'India hosted the G20 Summit in 2023 in which city?','questionHi':'भारत ने 2023 में G20 शिखर सम्मेलन किस शहर में आयोजित किया?','options':['Mumbai','Chennai','New Delhi','Bengaluru'],'optionsHi':['मुंबई','चेन्नई','नई दिल्ली','बेंगलुरु'],'correctIndex':2,'explanation':'India hosted the G20 Summit in New Delhi on 9-10 September 2023 under the theme "Vasudhaiva Kutumbakam".'},
  {'category':'📰 Current Affairs','question':'Who is the current (2025) President of India?','questionHi':'भारत की वर्तमान (2025) राष्ट्रपति कौन हैं?','options':['Ram Nath Kovind','Droupadi Murmu','Pranab Mukherjee','APJ Abdul Kalam'],'optionsHi':['राम नाथ कोविंद','द्रौपदी मुर्मू','प्रणब मुखर्जी','ए.पी.जे. अब्दुल कलाम'],'correctIndex':1,'explanation':'Droupadi Murmu became India\'s 15th President in July 2022 — the first tribal woman to hold this office.'},
  // ── J&K SPECIAL ──────────────────────────────────────────────────────────
  {'category':'🏔 J&K Special','question':'What is the summer capital of Jammu & Kashmir?','questionHi':'जम्मू एवं कश्मीर की ग्रीष्मकालीन राजधानी क्या है?','options':['Jammu','Srinagar','Leh','Katra'],'optionsHi':['जम्मू','श्रीनगर','लेह','कटरा'],'correctIndex':1,'explanation':'Srinagar is the summer capital of J&K UT, known as the "Venice of the East" for its beautiful Dal Lake.'},
  {'category':'🏔 J&K Special','question':'J&K became a Union Territory in which year?','questionHi':'जम्मू-कश्मीर किस वर्ष केंद्र शासित प्रदेश बना?','options':['2015','2017','2019','2021'],'optionsHi':['2015','2017','2019','2021'],'correctIndex':2,'explanation':'On 31 October 2019, J&K was bifurcated into two Union Territories: J&K (with legislature) and Ladakh (without legislature).'},
  {'category':'🏔 J&K Special','question':'Which famous lake is located in Srinagar, J&K?','questionHi':'श्रीनगर में कौन सी प्रसिद्ध झील स्थित है?','options':['Wular Lake','Manasbal Lake','Dal Lake','Nagin Lake'],'optionsHi':['वुलर झील','मानसबल झील','डल झील','नागिन झील'],'correctIndex':2,'explanation':'Dal Lake in Srinagar is world-famous for its houseboats, shikaras, and floating gardens — a crown jewel of Kashmir tourism.'},
  {'category':'🏔 J&K Special','question':'Vaishno Devi shrine is located in which district of J&K?','questionHi':'वैष्णो देवी मंदिर J&K के किस जिले में स्थित है?','options':['Jammu','Reasi','Udhampur','Kathua'],'optionsHi':['जम्मू','रियासी','उधमपुर','कठुआ'],'correctIndex':1,'explanation':'The Vaishno Devi shrine is located in the Trikuta Mountains in Reasi district, one of India\'s most visited pilgrimage sites.'},
  {'category':'🏔 J&K Special','question':'What is the traditional handicraft J&K is most famous for?','questionHi':'J&K किस पारंपरिक हस्तशिल्प के लिए सबसे प्रसिद्ध है?','options':['Silk Weaving','Pashmina Shawl','Chikankari','Madhubani Art'],'optionsHi':['रेशम बुनाई','पश्मीना शॉल','चिकनकारी','मधुबनी कला'],'correctIndex':1,'explanation':'Kashmiri Pashmina shawls, made from fine Changthangi goat wool, are world-renowned for their warmth and intricate embroidery.'},
];

// ════════════════════════════════════════════════════════════════════════════
//  AI SERVICE — Uses Gemini API (same key as AI chatbot, from .env)
// ════════════════════════════════════════════════════════════════════════════
class _QuizApiService {
  // Same models as AI chatbot — auto-fallback
  static const _models = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
  ];

  static String _cachedKey = '';

  static Future<void> loadKey() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.fetchAndActivate();
      _cachedKey = rc.getString('gemini_api_key');
    } catch (_) {}
  }

  static String get _apiKey => _cachedKey;

  static Future<List<_Question>> fetchDailyQuestions({
    required String category,
    required int dateSeed,
    int count = 30,
  }) async {
    if (_apiKey.isEmpty) return [];

    final categoryInstruction = category == 'All'
        ? '''Mix questions EQUALLY from ALL 13 categories:
1. Indian History  2. Indian Geography  3. Indian Polity & Constitution
4. Bhagavad Gita  5. Mahabharata  6. Ramayana
7. Indian Culture & Dance  8. Indian Climate & Weather
9. Science (Physics, Chemistry, Biology)
10. Great Personalities of India
11. Sports (Indian & International)
12. Current Affairs India 2023-2025
13. J&K (Jammu & Kashmir) Special'''
        : 'Focus ONLY on: $category';

    final prompt = '''
You are a quiz master creating exactly $count multiple-choice questions for Indian school students in J&K.
Daily seed for variation: $dateSeed

$categoryInstruction

STRICT: Return ONLY a raw JSON array. No explanation, no markdown, no code fences.

Each object must have EXACTLY these fields:
{
  "category": "emoji + category name",
  "question": "question in English",
  "questionHi": "question in Hindi Devanagari script",
  "options": ["A","B","C","D"],
  "optionsHi": ["A Hindi","B Hindi","C Hindi","D Hindi"],
  "correctIndex": 0,
  "explanation": "1-2 sentence explanation in English"
}

Rules:
- Exactly $count questions
- Mix easy/medium/hard difficulty
- All 4 options must be plausible
- correctIndex is 0-based (0=A, 1=B, 2=C, 3=D)
- Factually accurate only
- Hindi must be proper Devanagari script
- Seed $dateSeed ensures different questions each day
''';

    for (final model in _models) {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
            .httpsCallable('askGemini');
        final result = await callable.call({
          'model': model,
          'body': {
            'contents': [{'parts': [{'text': prompt}]}],
            'generationConfig': {'maxOutputTokens': 6000, 'temperature': 0.7},
          },
        }).timeout(const Duration(seconds: 40));

        {
          final data = result.data;
          final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
          String clean = text
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          final start = clean.indexOf('[');
          final end = clean.lastIndexOf(']');
          if (start != -1 && end != -1) {
            clean = clean.substring(start, end + 1);
          }
          final List<dynamic> parsed = jsonDecode(clean);
          final questions = parsed
              .map((q) => _Question.fromJson(q as Map<String, dynamic>))
              .toList();
          if (questions.isNotEmpty) return questions;
        }
        // No result — try next model
        continue;
      } catch (_) {
        continue;
      }
    }
    return []; // Fall back to offline questions
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SCREEN
// ════════════════════════════════════════════════════════════════════════════
class BharatKoJanoScreen extends StatefulWidget {
  const BharatKoJanoScreen({super.key});
  @override
  State<BharatKoJanoScreen> createState() => _BharatKoJanoScreenState();
}

class _BharatKoJanoScreenState extends State<BharatKoJanoScreen>
    with TickerProviderStateMixin {
  bool _quizStarted = false;
  bool _quizFinished = false;
  bool _hindi = false;
  bool _loading = false;
  String _loadingMsg = 'Preparing questions…';

  String _selectedCategory = 'All';
  List<_Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;

  Timer? _timer;
  int _timeLeft = 20;

  late AnimationController _fadeCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  static const _green     = Color(0xFF059669);
  static const _darkGreen = Color(0xFF065F46);
  static const _saffron   = Color(0xFFFF6B35);
  static const _navy      = Color(0xFF1E3A5F);

  final _categories = [
    'All',
    '🏛 History',
    '🗺 Geography',
    '⚖ Polity',
    '📖 Gita',
    '🏹 Mahabharata',
    '🏵 Ramayana',
    '💃 Culture',
    '🌦 Climate',
    '🔬 Science',
    '🌟 Great Personalities',
    '🏅 Sports',
    '📰 Current Affairs',
    '🏔 J&K Special',
  ];

  static const int _questionCount = 30;

  @override
  void initState() {
    super.initState();
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.93, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  int get _dateSeed {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  Future<void> _startQuiz() async {
    setState(() {
      _loading = true;
      _loadingMsg = _hindi ? 'AI प्रश्न तैयार कर रहा है…' : 'AI is generating questions…';
    });

    await _QuizApiService.loadKey();
    List<_Question> questions = await _QuizApiService.fetchDailyQuestions(
      category: _selectedCategory, dateSeed: _dateSeed, count: _questionCount,
    );

    if (questions.isEmpty) {
      setState(() => _loadingMsg = _hindi ? 'स्थानीय प्रश्न लोड हो रहे हैं…' : 'Loading offline questions…');
      await Future.delayed(const Duration(milliseconds: 400));
      List<Map<String, dynamic>> pool = _selectedCategory == 'All'
          ? List.from(_fallback)
          : _fallback.where((q) => q['category'] == _selectedCategory).toList();
      if (pool.isEmpty) pool = List.from(_fallback);
      pool.shuffle(Random(_dateSeed));
      questions = pool.take(_questionCount).map(_Question.fromJson).toList();
    }

    _fadeCtrl.reset();
    setState(() {
      _questions = questions;
      _currentIndex = 0; _score = 0;
      _selectedAnswer = null; _answered = false;
      _quizStarted = true; _quizFinished = false; _loading = false;
    });
    _fadeCtrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) { t.cancel(); if (!_answered) _selectAnswer(-1); }
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    setState(() {
      _selectedAnswer = index; _answered = true;
      if (index == _questions[_currentIndex].correctIndex) _score++;
    });
    _scaleCtrl.reset(); _scaleCtrl.forward();
  }

  void _nextQuestion() {
    _fadeCtrl.reset();
    if (_currentIndex + 1 >= _questions.length) {
      setState(() => _quizFinished = true);
    } else {
      setState(() { _currentIndex++; _selectedAnswer = null; _answered = false; });
      _startTimer();
    }
    _fadeCtrl.forward();
  }

  void _resetQuiz() {
    _timer?.cancel();
    _fadeCtrl.reset();
    setState(() { _quizStarted = false; _quizFinished = false; _questions = []; });
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _loading
          ? _buildLoading()
          : FadeTransition(
              opacity: _fadeAnim,
              child: !_quizStarted ? _buildHome()
                  : _quizFinished ? _buildResults()
                  : _buildQuiz(),
            ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: _navy, foregroundColor: Colors.white, elevation: 0,
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bharat Ko Jano 🇮🇳',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      if (_quizStarted && !_quizFinished)
        Text('${_currentIndex + 1} / ${_questions.length}  •  Score: $_score',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
    ]),
    actions: [
      GestureDetector(
        onTap: () => setState(() => _hindi = !_hindi),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_hindi ? 'EN' : 'हि',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        ),
      ),
    ],
  );

  Widget _buildLoading() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(width: 80, height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_saffron, _green],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('🇮🇳', style: TextStyle(fontSize: 40)))),
      const SizedBox(height: 24),
      const SizedBox(width: 36, height: 36,
          child: CircularProgressIndicator(strokeWidth: 3, color: _green)),
      const SizedBox(height: 16),
      Text(_loadingMsg,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(_hindi ? 'AI द्वारा ताज़े प्रश्न • $_questionCount सवाल'
          : 'AI-powered • $_questionCount questions daily',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
    ],
  ));

  Widget _buildHome() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Hero banner
      Container(
        width: double.infinity, padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_navy, Color(0xFF2D5986)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.3),
              blurRadius: 16, offset: const Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🇮🇳', style: TextStyle(fontSize: 40)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _green.withValues(alpha: 0.5))),
              child: Text(_hindi ? 'AI • रोज नए प्रश्न' : 'AI • Fresh Daily',
                  style: GoogleFonts.poppins(fontSize: 10,
                      color: Colors.greenAccent, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(_hindi ? 'भारत को जानो 🎯' : 'Know Your India! 🎯',
              style: GoogleFonts.poppins(fontSize: 24,
                  fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            _hindi
                ? 'इतिहास • भूगोल • विज्ञान • खेल • गीता • महाभारत\nरामायण • J&K • समसामयिक • महान विभूतियां'
                : 'History • Geography • Science • Sports • Gita\nMahabharata • Ramayana • J&K • Current Affairs',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60, height: 1.5)),
        ]),
      ),
      const SizedBox(height: 18),

      // Stats row
      Row(children: [
        _statCard('$_questionCount', _hindi ? 'प्रश्न' : 'Questions', Icons.quiz_rounded, _green),
        const SizedBox(width: 10),
        _statCard('20s', _hindi ? 'प्रति प्रश्न' : 'Per Question', Icons.timer_rounded, _saffron),
        const SizedBox(width: 10),
        _statCard('13', _hindi ? 'श्रेणियां' : 'Categories', Icons.category_rounded, _navy),
      ]),
      const SizedBox(height: 22),

      // Category selector
      Text(_hindi ? 'श्रेणी चुनें:' : 'Select Category:',
          style: GoogleFonts.poppins(fontSize: 15,
              fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _categories.map((cat) {
          final sel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? _navy : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: sel ? _navy : AppColors.divider, width: sel ? 2 : 1),
                boxShadow: sel ? [BoxShadow(color: _navy.withValues(alpha: 0.25),
                    blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Text(cat, style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.textPrimary)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 28),

      // Start button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startQuiz,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4, shadowColor: _green.withValues(alpha: 0.4)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🚀', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Text(_hindi ? 'क्विज शुरू करें' : 'Start Quiz',
                style: GoogleFonts.poppins(fontSize: 18,
                    fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
      ),
      const SizedBox(height: 14),

      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _saffron.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _saffron.withValues(alpha: 0.2))),
        child: Row(children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(
            _hindi
                ? '$_questionCount प्रश्न, 20 सेकंड प्रति प्रश्न। हर दिन नए AI प्रश्न!'
                : '$_questionCount questions, 20 seconds each. New AI questions every day!',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))),
        ]),
      ),
    ]),
  );

  Widget _statCard(String value, String label, IconData icon, Color color) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ]),
    ));

  Widget _buildQuiz() {
    final q        = _questions[_currentIndex];
    final question = _hindi ? q.questionHi : q.question;
    final options  = _hindi ? q.optionsHi  : q.options;
    final progress = (_currentIndex + 1) / _questions.length;
    final timerColor = _timeLeft <= 5
        ? const Color(0xFFDC2626)
        : _timeLeft <= 10 ? _saffron : _green;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: ScaleTransition(scale: _scaleAnim, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress + Timer
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Q${_currentIndex + 1} of ${_questions.length}',
                    style: GoogleFonts.poppins(fontSize: 12,
                        color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                Text('Score: $_score',
                    style: GoogleFonts.poppins(fontSize: 12,
                        color: _green, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress, backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(_green),
                  minHeight: 7)),
            ])),
            const SizedBox(width: 14),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: timerColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: timerColor, width: 2.5)),
              child: Center(child: Text('$_timeLeft',
                  style: GoogleFonts.poppins(fontSize: 18,
                      fontWeight: FontWeight.w900, color: timerColor))),
            ),
          ]),
          const SizedBox(height: 12),

          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: _navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20)),
            child: Text(q.category, style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w700, color: _navy)),
          ),
          const SizedBox(height: 12),

          // Question card
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 14, offset: const Offset(0, 4))]),
            child: Text(question, style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, height: 1.5)),
          ),
          const SizedBox(height: 14),

          // Options
          ...List.generate(options.length, (i) {
            final isCorrect  = i == q.correctIndex;
            final isSelected = _selectedAnswer == i;
            Color bg = Colors.white;
            Color border = AppColors.divider;
            Color txt = AppColors.textPrimary;
            Color lbl = AppColors.textSecondary;
            Widget? trail;

            if (_answered) {
              if (isCorrect) {
                bg = _green.withValues(alpha: 0.08); border = _green;
                txt = _darkGreen; lbl = _green;
                trail = const Icon(Icons.check_circle_rounded, color: _green, size: 22);
              } else if (isSelected) {
                bg = const Color(0xFFDC2626).withValues(alpha: 0.07);
                border = const Color(0xFFDC2626);
                txt = const Color(0xFFDC2626); lbl = const Color(0xFFDC2626);
                trail = const Icon(Icons.cancel_rounded,
                    color: Color(0xFFDC2626), size: 22);
              } else {
                // ✅ Fixed: use AppColors.background instead of AppColors.surface
                bg = AppColors.background;
                txt = AppColors.textHint; lbl = AppColors.textHint;
              }
            }

            return GestureDetector(
              onTap: () => _selectAnswer(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 1.5),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
                child: Row(children: [
                  Container(width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: lbl.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Center(child: Text(String.fromCharCode(65 + i),
                        style: GoogleFonts.poppins(fontSize: 13,
                            fontWeight: FontWeight.w800, color: lbl)))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(options[i], style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: txt))),
                  if (trail != null) trail,
                ]),
              ),
            );
          }),

          if (_answered) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.lightbulb_rounded,
                    color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(q.explanation,
                    style: GoogleFonts.poppins(fontSize: 13,
                        color: AppColors.textSecondary, height: 1.5))),
              ]),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13))),
                child: Text(
                  _currentIndex + 1 >= _questions.length
                      ? (_hindi ? 'परिणाम देखें 🎯' : 'See Results 🎯')
                      : (_hindi ? 'अगला प्रश्न →' : 'Next Question →'),
                  style: GoogleFonts.poppins(fontSize: 15,
                      fontWeight: FontWeight.w700, color: Colors.white)),
              )),
          ],
        ],
      )),
    );
  }

  Widget _buildResults() {
    final pct   = (_score / _questions.length) * 100;
    final grade = pct >= 90 ? 'A+' : pct >= 80 ? 'A'
        : pct >= 70 ? 'B+' : pct >= 60 ? 'B' : pct >= 50 ? 'C' : 'D';
    final emoji = pct >= 90 ? '🏆' : pct >= 70 ? '⭐' : pct >= 50 ? '👍' : '📚';
    final msg   = pct >= 90
        ? (_hindi ? 'असाधारण! सच्चे भारत ज्ञानी!' : 'Outstanding! True Bharat Gyani!')
        : pct >= 70
        ? (_hindi ? 'शाबाश! आप भारत को अच्छी तरह जानते हैं!' : 'Great job! You know India well!')
        : pct >= 50
        ? (_hindi ? 'अच्छा प्रयास! सीखते रहिए!' : 'Good effort! Keep learning!')
        : (_hindi ? 'अभ्यास ही सफलता की कुंजी है!' : 'Practice makes perfect!');
    final color = pct >= 70 ? _green : pct >= 50 ? _saffron : const Color(0xFFDC2626);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_navy, color],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: _navy.withValues(alpha: 0.35),
                blurRadius: 20, offset: const Offset(0, 8))]),
          child: Column(children: [
            Text('$_score / ${_questions.length}',
                style: GoogleFonts.poppins(fontSize: 52,
                    fontWeight: FontWeight.w900, color: Colors.white)),
            Text('${pct.toStringAsFixed(1)}%  •  Grade $grade',
                style: GoogleFonts.poppins(fontSize: 16,
                    color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14,
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          _resStat('✅', '$_score', _hindi ? 'सही' : 'Correct', _green),
          const SizedBox(width: 10),
          _resStat('❌', '${_questions.length - _score}',
              _hindi ? 'गलत' : 'Wrong', const Color(0xFFDC2626)),
          const SizedBox(width: 10),
          _resStat('🎯', grade, _hindi ? 'ग्रेड' : 'Grade', _navy),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _resetQuiz,
            icon: const Icon(Icons.home_rounded),
            label: Text(_hindi ? 'होम' : 'Home',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              side: const BorderSide(color: _navy, width: 2),
              foregroundColor: _navy),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: _startQuiz,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text(_hindi ? 'फिर खेलें' : 'Play Again',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          )),
        ]),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _resetQuiz,
          child: Text(_hindi ? '📂 दूसरी श्रेणी चुनें' : '📂 Try a Different Category',
              style: GoogleFonts.poppins(fontSize: 13,
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _resStat(String emoji, String value, String label, Color color) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: GoogleFonts.poppins(
            fontSize: 11, color: AppColors.textSecondary)),
      ]),
    ));
}