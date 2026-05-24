// lib/screens/shared/chat_screen.dart
// Class Group Chat + Private Teacher-Student Chat
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

// ─── Chat Home (tabs: Group Chat | Private Chats) ─────────────────────────────
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: Text('Messages',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: '👥 Class Chat'),
            Tab(text: '💬 Private'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ClassGroupChat(user: user),
          _PrivateChatList(user: user),
        ],
      ),
    );
  }
}

// ─── Class Group Chat ─────────────────────────────────────────────────────────
class _ClassGroupChat extends StatefulWidget {
  final dynamic user;
  const _ClassGroupChat({required this.user});
  @override
  State<_ClassGroupChat> createState() => _ClassGroupChatState();
}

class _ClassGroupChatState extends State<_ClassGroupChat> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  String _selectedClass = '';
  bool _sending = false;

  static const _classes = [
    'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    if (user?.role == UserRole.student) {
      _selectedClass = user?.className ?? 'Class 10';
    } else {
      _selectedClass = 'Class 10';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _chatId => 'class_${_selectedClass.replaceAll(' ', '_')}';

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'text':       text,
        'senderId':   widget.user?.uid ?? '',
        'senderName': widget.user?.fullName ?? '',
        'senderRole': _roleStr(widget.user?.role),
        'timestamp':  FieldValue.serverTimestamp(),
        'type':       'text',
      });
      // Update last message in chat doc
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .set({
        'className':   _selectedClass,
        'lastMessage': text,
        'lastTime':    FieldValue.serverTimestamp(),
        'type':        'group',
      }, SetOptions(merge: true));
      _scrollDown();
    } catch (_) {}
    setState(() => _sending = false);
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user      = widget.user;
    final isTeacher = user?.role == UserRole.teacher;
    final isAdmin   = user?.role == UserRole.admin;
    final isStudent = user?.role == UserRole.student;

    return Column(children: [
      // Class selector (teacher/admin can switch classes)
      if (isTeacher || isAdmin)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10),
          child: DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Select Class Chat',
              isDense: true,
              prefixIcon: const Icon(Icons.group_rounded, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
            ),
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textPrimary),
            items: _classes.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c,
                    style: GoogleFonts.poppins(fontSize: 13)))).toList(),
            onChanged: (v) => setState(() => _selectedClass = v!),
          ),
        ),

      // Chat header
      Container(
        color: const Color(0xFF059669).withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(children: [
          const Icon(Icons.group_rounded,
              size: 16, color: Color(0xFF059669)),
          const SizedBox(width: 8),
          Text('$_selectedClass Group Chat',
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669))),
        ]),
      ),

      // Messages
      Expanded(child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
                color: Color(0xFF059669)));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 64,
                    color: const Color(0xFF059669).withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text('No messages yet',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Start the conversation!',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ));
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
          return ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d       = docs[i].data() as Map<String, dynamic>;
              final isMe    = d['senderId'] == user?.uid;
              final name    = d['senderName'] as String? ?? '';
              final role    = d['senderRole'] as String? ?? 'student';
              final text    = d['text'] as String? ?? '';
              final ts      = (d['timestamp'] as Timestamp?)?.toDate();

              // Date separator
              Widget? separator;
              if (i == 0 || _isDifferentDay(
                  (docs[i - 1].data() as Map)['timestamp'] as Timestamp?,
                  d['timestamp'] as Timestamp?)) {
                separator = _dateSeparator(ts);
              }

              return Column(children: [
                if (separator != null) separator,
                _bubble(
                  text: text,
                  name: name,
                  role: role,
                  time: ts,
                  isMe: isMe,
                ),
              ]);
            },
          );
        },
      )),

      // Input
      _inputBar(onSend: _send, ctrl: _ctrl, sending: _sending),
    ]);
  }
}

// ─── Private Chat List ─────────────────────────────────────────────────────────
class _PrivateChatList extends StatelessWidget {
  final dynamic user;
  const _PrivateChatList({required this.user});

  @override
  Widget build(BuildContext context) {
    final isStudent = user?.role == UserRole.student;
    final isTeacher = user?.role == UserRole.teacher;
    final isAdmin   = user?.role == UserRole.admin;

    return Column(children: [
      // Header info
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_rounded,
                color: Color(0xFF059669), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isStudent ? 'Chat with your Teachers'
                    : isTeacher ? 'Student Queries'
                    : 'All Private Chats',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                isStudent
                    ? 'Tap a teacher to start chatting'
                    : 'Students who messaged you',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          )),
        ]),
      ),
      const Divider(height: 1),

      // For students: show list of teachers to chat with
      if (isStudent)
        Expanded(child: _TeacherList(user: user))
      // For teachers/admin: show incoming chats
      else
        Expanded(child: _IncomingChats(user: user)),
    ]);
  }
}

// ─── Teacher List (for students to pick who to chat) ─────────────────────────
class _TeacherList extends StatelessWidget {
  final dynamic user;
  const _TeacherList({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .where('approvalStatus', isEqualTo: 'approved')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              color: Color(0xFF059669)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No teachers found',
              style: GoogleFonts.poppins(color: AppColors.textSecondary)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d    = docs[i].data() as Map<String, dynamic>;
            final uid  = docs[i].id;
            final name = d['fullName'] as String? ?? 'Teacher';
            final cls  = d['className'] as String? ?? '';
            return _contactTile(
              context: context,
              name: name,
              subtitle: cls.isNotEmpty ? 'Class Teacher: $cls' : 'Teacher',
              role: 'teacher',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PrivateChatRoom(
                  currentUser: user,
                  otherUserId: uid,
                  otherUserName: name,
                  otherUserRole: 'teacher',
                ),
              )),
            );
          },
        );
      },
    );
  }
}

// ─── Incoming Chats (for teachers) ────────────────────────────────────────────
class _IncomingChats extends StatelessWidget {
  final dynamic user;
  const _IncomingChats({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('private_chats')
          .where('participants', arrayContains: user?.uid ?? '')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
              color: Color(0xFF059669)));
        }
        var docs = snap.data?.docs ?? [];
        docs = List.from(docs)..sort((a, b) {
          final at = (a.data() as Map)['lastTime'] as Timestamp?;
          final bt = (b.data() as Map)['lastTime'] as Timestamp?;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });

        if (docs.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_rounded, size: 64,
                  color: const Color(0xFF059669).withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No messages yet',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Student messages will appear here',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d         = docs[i].data() as Map<String, dynamic>;
            final myUid     = user?.uid ?? '';
            final others    = (d['participantNames'] as Map<String, dynamic>? ?? {});
            final otherUid  = (d['participants'] as List<dynamic>? ?? [])
                .firstWhere((p) => p != myUid, orElse: () => '');
            final otherName = others[otherUid] as String? ?? 'Student';
            final otherRole = d['participantRoles']?[otherUid] as String? ?? 'student';
            final lastMsg   = d['lastMessage'] as String? ?? '';
            final lastTime  = (d['lastTime'] as Timestamp?)?.toDate();
            final unread    = (d['unread_$myUid'] as int? ?? 0);

            return _contactTile(
              context: context,
              name: otherName,
              subtitle: lastMsg.isNotEmpty ? lastMsg : 'Tap to chat',
              role: otherRole,
              unread: unread,
              time: lastTime,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PrivateChatRoom(
                  currentUser: user,
                  otherUserId: otherUid.toString(),
                  otherUserName: otherName,
                  otherUserRole: otherRole,
                ),
              )),
            );
          },
        );
      },
    );
  }
}

// ─── Private Chat Room ─────────────────────────────────────────────────────────
class PrivateChatRoom extends StatefulWidget {
  final dynamic currentUser;
  final String  otherUserId;
  final String  otherUserName;
  final String  otherUserRole;
  const PrivateChatRoom({
    super.key,
    required this.currentUser,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
  });
  @override
  State<PrivateChatRoom> createState() => _PrivateChatRoomState();
}

class _PrivateChatRoomState extends State<PrivateChatRoom> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  String get _chatId {
    final ids = [widget.currentUser?.uid ?? '', widget.otherUserId]..sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final myUid = widget.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('private_chats')
        .doc(_chatId)
        .set({'unread_$myUid': 0}, SetOptions(merge: true));
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      final myUid    = widget.currentUser?.uid ?? '';
      final myName   = widget.currentUser?.fullName ?? '';
      final myRole   = _roleStr(widget.currentUser?.role);
      final otherUid = widget.otherUserId;

      await FirebaseFirestore.instance
          .collection('private_chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'text':       text,
        'senderId':   myUid,
        'senderName': myName,
        'senderRole': myRole,
        'timestamp':  FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('private_chats')
          .doc(_chatId)
          .set({
        'participants':     [myUid, otherUid],
        'participantNames': {
          myUid:    myName,
          otherUid: widget.otherUserName,
        },
        'participantRoles': {
          myUid:    myRole,
          otherUid: widget.otherUserRole,
        },
        'lastMessage':       text,
        'lastTime':          FieldValue.serverTimestamp(),
        'unread_$otherUid':  FieldValue.increment(1),
        'unread_$myUid':     0,
      }, SetOptions(merge: true));

      _scrollDown();
    } catch (_) {}
    setState(() => _sending = false);
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              widget.otherUserName.isNotEmpty
                  ? widget.otherUserName[0].toUpperCase() : '?',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherUserName,
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(_cap(widget.otherUserRole),
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.white70)),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('private_chats')
              .doc(_chatId)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                  color: Color(0xFF059669)));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64,
                      color: const Color(0xFF059669).withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Say hello! 👋',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Start a conversation with ${widget.otherUserName}',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary)),
                ],
              ));
            }
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollDown());
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d    = docs[i].data() as Map<String, dynamic>;
                final isMe = d['senderId'] == widget.currentUser?.uid;
                final ts   = (d['timestamp'] as Timestamp?)?.toDate();
                Widget? sep;
                if (i == 0 || _isDifferentDay(
                    (docs[i - 1].data() as Map)['timestamp'] as Timestamp?,
                    d['timestamp'] as Timestamp?)) {
                  sep = _dateSeparator(ts);
                }
                return Column(children: [
                  if (sep != null) sep,
                  _bubble(
                    text: d['text'] as String? ?? '',
                    name: d['senderName'] as String? ?? '',
                    role: d['senderRole'] as String? ?? '',
                    time: ts,
                    isMe: isMe,
                  ),
                ]);
              },
            );
          },
        )),
        _inputBar(onSend: _send, ctrl: _ctrl, sending: _sending),
      ]),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────
Widget _bubble({
  required String text,
  required String name,
  required String role,
  required DateTime? time,
  required bool isMe,
}) {
  final roleColor = role == 'teacher' ? const Color(0xFF2563EB)
      : role == 'admin' ? const Color(0xFFDC2626)
      : const Color(0xFF059669);

  return Padding(
    padding: EdgeInsets.only(
        bottom: 8, left: isMe ? 48 : 0, right: isMe ? 0 : 48),
    child: Row(
      mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: roleColor)),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(name, style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: roleColor)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_cap(role), style: GoogleFonts.poppins(
                        fontSize: 8, fontWeight: FontWeight.w700,
                        color: roleColor)),
                  ),
                ]),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF059669) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 4)],
              ),
              child: Text(text, style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  height: 1.4)),
            ),
            if (time != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                child: Text(DateFormat('hh:mm a').format(time),
                    style: GoogleFonts.poppins(
                        fontSize: 9, color: AppColors.textHint)),
              ),
          ],
        )),
      ],
    ),
  );
}

Widget _inputBar({
  required Future<void> Function() onSend,
  required TextEditingController ctrl,
  required bool sending,
}) {
  return Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: ctrl,
          maxLines: null,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Type a message...',
            hintStyle: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textHint),
            filled: true,
            fillColor: Colors.grey.shade50,
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
                    color: Color(0xFF059669), width: 1.5)),
          ),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: sending ? null : onSend,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: sending ? Colors.grey.shade300
                : const Color(0xFF059669),
            shape: BoxShape.circle,
          ),
          child: Icon(
            sending ? Icons.hourglass_empty_rounded
                : Icons.send_rounded,
            color: Colors.white, size: 20),
        ),
      ),
    ]),
  );
}

Widget _contactTile({
  required BuildContext context,
  required String name,
  required String subtitle,
  required String role,
  required VoidCallback onTap,
  int unread = 0,
  DateTime? time,
}) {
  final roleColor = role == 'teacher' ? const Color(0xFF2563EB)
      : role == 'admin' ? const Color(0xFFDC2626)
      : const Color(0xFF059669);

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 6),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: roleColor.withValues(alpha: 0.12),
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: roleColor)),
      ),
      title: Row(children: [
        Expanded(child: Text(name, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700))),
        if (time != null)
          Text(DateFormat('hh:mm a').format(time),
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textHint)),
      ]),
      subtitle: Row(children: [
        Expanded(child: Text(subtitle,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (unread > 0)
          Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(
                color: Color(0xFF059669), shape: BoxShape.circle),
            child: Center(child: Text('$unread',
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.white,
                    fontWeight: FontWeight.w800))),
          ),
      ]),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: roleColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(_cap(role), style: GoogleFonts.poppins(
            fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
      ),
    ),
  );
}

Widget _dateSeparator(DateTime? date) {
  if (date == null) return const SizedBox.shrink();
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d     = DateTime(date.year, date.month, date.day);
  String label;
  if (d == today) label = 'Today';
  else if (d == today.subtract(const Duration(days: 1))) label = 'Yesterday';
  else label = DateFormat('dd MMM yyyy').format(date);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: GoogleFonts.poppins(
            fontSize: 11, color: AppColors.textHint,
            fontWeight: FontWeight.w600)),
      ),
      const Expanded(child: Divider()),
    ]),
  );
}

bool _isDifferentDay(Timestamp? a, Timestamp? b) {
  if (a == null || b == null) return false;
  final da = a.toDate();
  final db = b.toDate();
  return da.year != db.year || da.month != db.month || da.day != db.day;
}

String _roleStr(dynamic role) {
  if (role == UserRole.admin)   return 'admin';
  if (role == UserRole.teacher) return 'teacher';
  return 'student';
}

String _cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);