// lib/screens/shared/more_screens.dart
// Contains: Calendar, Emergency Contacts, Complaint Box, Leaderboard,
//           ExamDates, YogaScreen, DietChartScreen, ExerciseScreen,
//           StudyTipsScreen, QuoteOfDayScreen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/extended_service.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

// ════════════════════════════════════════════════════
//  SCHOOL CALENDAR
// ════════════════════════════════════════════════════
class SchoolCalendarScreen extends StatefulWidget {
  const SchoolCalendarScreen({super.key});
  @override State<SchoolCalendarScreen> createState() => _SchoolCalendarScreenState();
}

class _SchoolCalendarScreenState extends State<SchoolCalendarScreen> {
  final _service = ExtendedService();
  String _filterType = 'all';
  final _types = ['all', 'holiday', 'exam', 'ptm', 'sports', 'cultural', 'other'];

  Color _eventColor(String type) {
    switch (type) {
      case 'holiday': return AppColors.success;
      case 'exam': return AppColors.error;
      case 'ptm': return AppColors.adminColor;
      case 'sports': return AppColors.info;
      case 'cultural': return AppColors.accent;
      default: return AppColors.primary;
    }
  }

  IconData _eventIcon(String type) {
    switch (type) {
      case 'holiday': return Icons.beach_access_rounded;
      case 'exam': return Icons.edit_note_rounded;
      case 'ptm': return Icons.groups_rounded;
      case 'sports': return Icons.sports_rounded;
      case 'cultural': return Icons.celebration_rounded;
      default: return Icons.event_rounded;
    }
  }

  void _showAddEvent(BuildContext context, UserModel user) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'holiday';
    DateTime date = DateTime.now();
    bool isSaving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        height: MediaQuery.of(ctx).size.height * 0.70,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 48, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 12, 0), child: Row(children: [
            Text('Add Calendar Event', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
          ])),
          const Divider(height: 20),
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppTextField(label: 'Event Title', hint: 'e.g. Diwali Holiday', controller: titleCtrl, prefixIcon: Icons.event_rounded),
              const SizedBox(height: 12),
              AppTextField(label: 'Description', hint: 'Details...', controller: descCtrl, prefixIcon: Icons.description_rounded),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(labelText: 'Event Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.category_rounded)),
                items: _types.skip(1).map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1), style: GoogleFonts.poppins()))).toList(),
                onChanged: (v) => setModal(() => type = v!),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: date,
                    firstDate: DateTime(2024), lastDate: DateTime(2027));
                  if (picked != null) setModal(() => date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd MMMM, yyyy').format(date), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, color: AppColors.textHint, size: 16),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (titleCtrl.text.trim().isEmpty) return;
                  setModal(() => isSaving = true);
                  await _service.addCalendarEvent(CalendarEvent(
                    id: '', title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                    eventType: type, addedBy: user.fullName, eventDate: date, createdAt: DateTime.now(),
                  ));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Add Event', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              )),
            ]),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canAdd = user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('School Calendar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _types.length,
            itemBuilder: (_, i) {
              final t = _types[i];
              final sel = _filterType == t;
              return GestureDetector(
                onTap: () => setState(() => _filterType = t),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.primary : AppColors.divider),
                  ),
                  child: Text(t == 'all' ? 'All' : t[0].toUpperCase() + t.substring(1),
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textSecondary)),
                ),
              );
            },
          ),
        ),
        Expanded(child: StreamBuilder<List<CalendarEvent>>(
          stream: _service.getCalendarEvents(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (_, __) => const ShimmerCard());
            }
            var events = snap.data ?? [];
            if (_filterType != 'all') events = events.where((e) => e.eventType == _filterType).toList();
            if (events.isEmpty) return const EmptyState(icon: Icons.event_note_outlined, title: 'No Events', subtitle: 'No school events scheduled');

            final Map<String, List<CalendarEvent>> grouped = {};
            for (final e in events) {
              final key = DateFormat('MMMM yyyy').format(e.eventDate);
              grouped.putIfAbsent(key, () => []).add(e);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: 4),
                    child: Text(entry.key, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  ),
                  ...entry.value.map((e) {
                    final color = _eventColor(e.eventType);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: color, width: 4)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('${e.eventDate.day}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                            Text(DateFormat('MMM').format(e.eventDate), style: GoogleFonts.poppins(fontSize: 9, color: color)),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                          if (e.description.isNotEmpty) Text(e.description, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(e.eventType[0].toUpperCase() + e.eventType.substring(1),
                              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                          ),
                        ])),
                        if (canAdd) IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                          onPressed: () => _service.deleteCalendarEvent(e.id),
                        ),
                      ]),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              )).toList(),
            );
          },
        )),
      ]),
      floatingActionButton: canAdd && user != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEvent(context, user),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Add Event', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

// ════════════════════════════════════════════════════
//  EMERGENCY CONTACTS  (with tap-to-call)
// ════════════════════════════════════════════════════
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$phone copied to clipboard'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final service = ExtendedService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Emergency Contacts', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.error, foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.emergency_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Tap the call button to dial immediately in an emergency.',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
            )),
          ]),
        ),
        Expanded(child: StreamBuilder<List<EmergencyContact>>(
          stream: service.getEmergencyContacts(),
          builder: (_, snap) {
            final contacts = snap.data ?? [];
            if (contacts.isEmpty && !isAdmin) return EmptyState(
              icon: Icons.contact_phone_rounded,
              title: 'No Contacts Added',
              subtitle: isAdmin ? 'Add emergency contacts' : 'Contact admin to add emergency numbers',
            );
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: contacts.length + (isAdmin ? 1 : 0),
              itemBuilder: (_, i) {
                if (isAdmin && i == contacts.length) {
                  return _AddContactCard(service: service);
                }
                final c = contacts[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                    border: i == 0 ? Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1.5) : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('${i + 1}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.error))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(c.designation, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                      if (c.alternatePhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Alt: ${c.alternatePhone}',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ])),
                    GestureDetector(
                      onTap: () => _call(context, c.phone),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.call_rounded, color: Colors.white, size: 20),
                            const SizedBox(height: 2),
                            Text(c.phone,
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                        onPressed: () => service.deleteEmergencyContact(c.id),
                      ),
                    ],
                  ]),
                );
              },
            );
          },
        )),
      ]),
    );
  }
}

class _AddContactCard extends StatefulWidget {
  final ExtendedService service;
  const _AddContactCard({required this.service});
  @override State<_AddContactCard> createState() => _AddContactCardState();
}

class _AddContactCardState extends State<_AddContactCard> {
  final nameCtrl = TextEditingController();
  final desigCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final altCtrl = TextEditingController();
  bool expanded = false;
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    if (!expanded) return GestureDetector(
      onTap: () => setState(() => expanded = true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, top: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.add_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Add Emergency Contact', style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Column(children: [
        AppTextField(label: 'Name', hint: 'Contact name', controller: nameCtrl, prefixIcon: Icons.person_rounded),
        const SizedBox(height: 8),
        AppTextField(label: 'Designation', hint: 'e.g. Principal', controller: desigCtrl, prefixIcon: Icons.badge_rounded),
        const SizedBox(height: 8),
        AppTextField(label: 'Phone', hint: '10-digit number', controller: phoneCtrl, prefixIcon: Icons.phone_rounded),
        const SizedBox(height: 8),
        AppTextField(label: 'Alternate Phone (Optional)', hint: '', controller: altCtrl, prefixIcon: Icons.phone_outlined),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() => expanded = false),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: saving ? null : () async {
              if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
              setState(() => saving = true);
              await widget.service.addEmergencyContact(EmergencyContact(
                id: '', name: nameCtrl.text.trim(), designation: desigCtrl.text.trim(),
                phone: phoneCtrl.text.trim(), alternatePhone: altCtrl.text.trim(), priority: 99,
              ));
              setState(() { saving = false; expanded = false; });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
          )),
        ]),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════
//  COMPLAINT BOX
// ════════════════════════════════════════════════════
class ComplaintBoxScreen extends StatefulWidget {
  const ComplaintBoxScreen({super.key});
  @override State<ComplaintBoxScreen> createState() => _ComplaintBoxScreenState();
}

class _ComplaintBoxScreenState extends State<ComplaintBoxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _service = ExtendedService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Complaint & Feedback', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.adminColor, foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [Tab(text: isAdmin ? 'All Complaints' : 'Submit'), Tab(text: isAdmin ? 'Resolve' : 'My Complaints')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          isAdmin
              ? _AllComplaints(service: _service, adminId: user?.uid ?? '', adminName: user?.fullName ?? '')
              : _SubmitComplaint(service: _service, user: user),
          isAdmin
              ? _AllComplaints(service: _service, adminId: user?.uid ?? '', adminName: user?.fullName ?? '', pendingOnly: false)
              : _MyComplaints(service: _service, userId: user?.uid ?? ''),
        ],
      ),
    );
  }
}

class _SubmitComplaint extends StatefulWidget {
  final ExtendedService service;
  final UserModel? user;
  const _SubmitComplaint({required this.service, required this.user});
  @override State<_SubmitComplaint> createState() => _SubmitComplaintState();
}

class _SubmitComplaintState extends State<_SubmitComplaint> {
  final _descCtrl = TextEditingController();
  String _category = 'Academics';
  bool _anonymous = true;
  bool _submitting = false;
  final _categories = ['Academics','Facilities','Teacher Conduct','Bullying','Food','Infrastructure','Other'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.adminColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.lock_rounded, color: AppColors.adminColor, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Your complaints are safe. You can submit anonymously.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Category', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8,
          children: _categories.map((c) => GestureDetector(
            onTap: () => setState(() => _category = c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _category == c ? AppColors.adminColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _category == c ? AppColors.adminColor : AppColors.divider),
              ),
              child: Text(c, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
                color: _category == c ? Colors.white : AppColors.textSecondary)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 16),
        Text('Your Complaint / Feedback', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descCtrl, maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Describe your complaint or feedback in detail...',
            hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(14),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
          child: Row(children: [
            const Icon(Icons.visibility_off_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Submit Anonymously', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('Your name will not be shown to admin', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
            ])),
            Switch(value: _anonymous, onChanged: (v) => setState(() => _anonymous = v), activeColor: AppColors.adminColor),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : () async {
              if (_descCtrl.text.trim().isEmpty) return;
              setState(() => _submitting = true);
              await widget.service.submitComplaint(ComplaintModel(
                id: '', category: _category, description: _descCtrl.text.trim(),
                status: 'open', isAnonymous: _anonymous,
                submittedBy: _anonymous ? null : widget.user?.uid,
                submittedByName: _anonymous ? null : widget.user?.fullName,
                createdAt: DateTime.now(),
              ));
              _descCtrl.clear();
              setState(() => _submitting = false);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Complaint submitted successfully!'),
                backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
              ));
            },
            icon: const Icon(Icons.send_rounded, color: Colors.white),
            label: Text('Submit', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.adminColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }
}

class _AllComplaints extends StatelessWidget {
  final ExtendedService service;
  final String adminId, adminName;
  final bool pendingOnly;
  const _AllComplaints({required this.service, required this.adminId, required this.adminName, this.pendingOnly = true});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ComplaintModel>>(
      stream: service.getAllComplaints(),
      builder: (_, snap) {
        var complaints = snap.data ?? [];
        if (pendingOnly) complaints = complaints.where((c) => c.status == 'open').toList();
        if (complaints.isEmpty) return EmptyState(icon: Icons.check_circle_outline_rounded, title: pendingOnly ? 'No Open Complaints' : 'No Complaints', subtitle: '');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (_, i) {
            final c = complaints[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.adminColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(c.category, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.adminColor))),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.status == 'resolved' ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                    child: Text(c.status.toUpperCase(),
                      style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700,
                        color: c.status == 'resolved' ? AppColors.success : AppColors.warning))),
                ]),
                const SizedBox(height: 8),
                Text(c.description, style: GoogleFonts.poppins(fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(c.isAnonymous ? Icons.visibility_off_rounded : Icons.person_outline_rounded, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(c.isAnonymous ? 'Anonymous' : (c.submittedByName ?? 'Unknown'),
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                  const Spacer(),
                  Text(DateFormat('dd MMM').format(c.createdAt), style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                ]),
                if (c.status == 'open') ...[
                  const SizedBox(height: 10),
                  _ResolveButton(service: service, complaint: c),
                ],
                if (c.response != null) ...[
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                    child: Text('Response: ${c.response}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success))),
                ],
              ]),
            );
          },
        );
      },
    );
  }
}

class _ResolveButton extends StatefulWidget {
  final ExtendedService service;
  final ComplaintModel complaint;
  const _ResolveButton({required this.service, required this.complaint});
  @override State<_ResolveButton> createState() => _ResolveButtonState();
}

class _ResolveButtonState extends State<_ResolveButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final ctrl = TextEditingController();
        showDialog(context: context, builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Resolve Complaint', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: TextField(controller: ctrl, maxLines: 3,
            decoration: InputDecoration(hintText: 'Your response...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.poppins())),
            ElevatedButton(
              onPressed: () async { Navigator.pop(context); await widget.service.resolveComplaint(widget.complaint.id, ctrl.text.trim()); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: Text('Resolve', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ));
      },
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Text('Mark as Resolved', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _MyComplaints extends StatelessWidget {
  final ExtendedService service;
  final String userId;
  const _MyComplaints({required this.service, required this.userId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ComplaintModel>>(
      stream: service.getUserComplaints(userId),
      builder: (_, snap) {
        final complaints = snap.data ?? [];
        if (complaints.isEmpty) return const EmptyState(icon: Icons.feedback_outlined, title: 'No Complaints', subtitle: 'You have not submitted any complaints');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (_, i) {
            final c = complaints[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(c.category, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.adminColor)),
                  const Spacer(),
                  Text(c.status.toUpperCase(), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700,
                    color: c.status == 'resolved' ? AppColors.success : AppColors.warning)),
                ]),
                const SizedBox(height: 6),
                Text(c.description, style: GoogleFonts.poppins(fontSize: 13)),
                if (c.response != null) ...[
                  const SizedBox(height: 8),
                  Text('Response: ${c.response}', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success)),
                ],
              ]),
            );
          },
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════
//  STUDENT LEADERBOARD
// ════════════════════════════════════════════════════
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedClass = 'Class 1';
  final _classes = ['Nursery','LKG','UKG','Class 1','Class 2','Class 3','Class 4','Class 5','Class 6','Class 7','Class 8','Class 9','Class 10'];
  final _schoolService = SchoolService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Leaderboard', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.accent, foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: DropdownButtonFormField<String>(
              value: _selectedClass,
              decoration: InputDecoration(filled: true, fillColor: Colors.white.withValues(alpha: 0.15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
              dropdownColor: AppColors.primary,
              style: GoogleFonts.poppins(color: Colors.white),
              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedClass = v!),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<ResultModel>>(
        stream: _schoolService.getClassResults(_selectedClass, 'F1'),
        builder: (_, snap) {
          final results = snap.data ?? [];
          final Map<String, List<double>> studentScores = {};
          for (final r in results) {
            studentScores.putIfAbsent(r.studentId, () => []).add(r.percentage);
          }
          final leaderboard = studentScores.entries.map((e) {
            final avg = e.value.reduce((a, b) => a + b) / e.value.length;
            final r = results.firstWhere((r) => r.studentId == e.key);
            return {'name': r.studentName, 'avg': avg, 'count': e.value.length};
          }).toList()..sort((a, b) => (b['avg'] as double).compareTo(a['avg'] as double));

          if (leaderboard.isEmpty) return const EmptyState(icon: Icons.leaderboard_outlined, title: 'No Results Yet', subtitle: 'Results will appear after marks are entered');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaderboard.length,
            itemBuilder: (_, i) {
              final item = leaderboard[i];
              final rank = i + 1;
              final avg = item['avg'] as double;
              final medals = ['🥇', '🥈', '🥉'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: rank <= 3 ? AppColors.accent.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: rank <= 3 ? Border.all(color: AppColors.accent.withValues(alpha: 0.3)) : null,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
                ),
                child: Row(children: [
                  SizedBox(
                    width: 40,
                    child: Text(rank <= 3 ? medals[rank - 1] : '#$rank',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: rank <= 3 ? 22 : 14, fontWeight: FontWeight.w800,
                        color: rank <= 3 ? AppColors.accent : AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item['name'] as String,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${avg.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800,
                        color: avg >= 75 ? AppColors.success : avg >= 50 ? AppColors.warning : AppColors.error)),
                    Text('${item['count']} exams', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint)),
                  ]),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  EXAM DATES
// ════════════════════════════════════════════════════
class ExamDatesScreen extends StatelessWidget {
  const ExamDatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Exam Dates', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.error, foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CalendarEvent>>(
        stream: ExtendedService().getCalendarEvents(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final exams = (snap.data ?? []).where((e) => e.eventType == 'exam').toList()
            ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

          if (exams.isEmpty) {
            return const EmptyState(
              icon: Icons.edit_note_outlined,
              title: 'No Exam Dates',
              subtitle: 'Exam schedule will be posted here by admin',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (_, i) {
              final e = exams[i];
              final daysLeft = e.eventDate.difference(DateTime.now()).inDays;
              final isPast = daysLeft < 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: isPast ? AppColors.textHint : AppColors.error, width: 4)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: (isPast ? AppColors.textHint : AppColors.error).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${e.eventDate.day}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800,
                          color: isPast ? AppColors.textHint : AppColors.error)),
                      Text(DateFormat('MMM').format(e.eventDate),
                        style: GoogleFonts.poppins(fontSize: 10,
                          color: isPast ? AppColors.textHint : AppColors.error)),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700,
                      color: isPast ? AppColors.textSecondary : AppColors.textPrimary)),
                    if (e.description.isNotEmpty)
                      Text(e.description, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    Text(DateFormat('EEEE, d MMMM yyyy').format(e.eventDate),
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                  ])),
                  if (!isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: daysLeft <= 3 ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(children: [
                        Text('$daysLeft', style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: daysLeft <= 3 ? AppColors.error : AppColors.primary)),
                        Text('days', style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textHint)),
                      ]),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.textHint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text('Done', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  YOGA SCREEN
// ════════════════════════════════════════════════════
class YogaScreen extends StatelessWidget {
  const YogaScreen({super.key});

  // ✅ FIX: explicit Map<String, String> type to avoid Object inference
  static const List<Map<String, String>> _poses = [
    {'name': 'Tadasana (Mountain Pose)', 'duration': '30 sec', 'benefit': 'Improves posture and balance', 'emoji': '🧍'},
    {'name': 'Vrikshasana (Tree Pose)', 'duration': '30 sec each side', 'benefit': 'Strengthens legs and focus', 'emoji': '🌳'},
    {'name': 'Balasana (Child Pose)', 'duration': '1 min', 'benefit': 'Relieves stress and fatigue', 'emoji': '🙇'},
    {'name': 'Bhujangasana (Cobra Pose)', 'duration': '30 sec', 'benefit': 'Strengthens spine and chest', 'emoji': '🐍'},
    {'name': 'Shavasana (Corpse Pose)', 'duration': '5 min', 'benefit': 'Deep relaxation and stress relief', 'emoji': '😌'},
    {'name': 'Anulom Vilom (Breathing)', 'duration': '5 min', 'benefit': 'Calms mind and improves focus', 'emoji': '🌬'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Yoga & Mindfulness', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Daily Yoga Routine', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Practice these poses every morning for 15-20 minutes',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 16),
          ..._poses.map((pose) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
            ),
            child: Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(pose['emoji']!, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pose['name']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(pose['benefit']!, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF059669).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(pose['duration']!, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
              ),
            ]),
          )),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  DIET CHART SCREEN
// ════════════════════════════════════════════════════
class DietChartScreen extends StatelessWidget {
  const DietChartScreen({super.key});

  // ✅ FIX: explicit Map<String, String> — color stored as hex string, parsed at runtime
  static const List<Map<String, String>> _meals = [
    {'time': '7:00 AM', 'meal': 'Breakfast', 'items': 'Oats / Poha / Idli with fruits and milk', 'emoji': '🌅', 'color': 'D97706'},
    {'time': '10:30 AM', 'meal': 'Mid-Morning Snack', 'items': 'Banana / Apple / Handful of nuts', 'emoji': '🍎', 'color': '059669'},
    {'time': '1:00 PM', 'meal': 'Lunch', 'items': 'Roti, Dal, Sabzi, Rice, Salad, Curd', 'emoji': '☀', 'color': '2563EB'},
    {'time': '4:00 PM', 'meal': 'Evening Snack', 'items': 'Sprouts / Chana / Roasted makhana', 'emoji': '🌤', 'color': '7C3AED'},
    {'time': '8:00 PM', 'meal': 'Dinner', 'items': 'Light Roti, Dal, Vegetables (avoid heavy food)', 'emoji': '🌙', 'color': '0891B2'},
  ];

  Color _hexColor(String hex) => Color(int.parse('FF$hex', radix: 16));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Diet Chart', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Healthy Student Diet Plan', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('A balanced diet boosts memory, focus and energy', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 16),
          ..._meals.map((meal) {
            final color = _hexColor(meal['color']!);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: color, width: 4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(meal['emoji']!, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(meal['meal']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(meal['time']!, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 4),
                  Text(meal['items']!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                ])),
              ]),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.water_drop_rounded, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Drink 8-10 glasses of water daily. Stay hydrated for better concentration!',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))),
            ]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  EXERCISE SCREEN
// ════════════════════════════════════════════════════
class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  // ✅ FIX: explicit Map<String, String> type
  static const List<Map<String, String>> _exercises = [
    {'name': 'Jumping Jacks', 'sets': '3 sets x 30 reps', 'benefit': 'Full body warm-up', 'emoji': '⭐'},
    {'name': 'Push-Ups', 'sets': '3 sets x 10 reps', 'benefit': 'Upper body strength', 'emoji': '💪'},
    {'name': 'Squats', 'sets': '3 sets x 15 reps', 'benefit': 'Leg strength & endurance', 'emoji': '🏋'},
    {'name': 'Plank', 'sets': '3 sets x 30 sec', 'benefit': 'Core strength & stability', 'emoji': '🔥'},
    {'name': 'Running / Jogging', 'sets': '15-20 minutes', 'benefit': 'Cardio & stamina', 'emoji': '🏃'},
    {'name': 'Stretching', 'sets': '10 minutes', 'benefit': 'Flexibility & cool down', 'emoji': '🤸'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Exercise & Fitness', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Daily Exercise Routine', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('30 minutes of exercise keeps you fit and focused', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 16),
          ..._exercises.asMap().entries.map((entry) {
            final i = entry.key;
            final ex = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${i + 1}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex['name']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(ex['benefit']!, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(ex['sets']!, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)), textAlign: TextAlign.center),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  STUDY TIPS SCREEN
// ════════════════════════════════════════════════════
class StudyTipsScreen extends StatelessWidget {
  const StudyTipsScreen({super.key});

  // ✅ FIX: explicit Map<String, String> type + fixed curly apostrophe on line 1209
  static const List<Map<String, String>> _tips = [
    {'title': 'Pomodoro Technique', 'tip': 'Study for 25 minutes, then take a 5-minute break. After 4 sessions, take a longer break.', 'emoji': '⏱'},
    {'title': 'Active Recall', 'tip': 'After reading, close the book and try to recall everything you just learned. This strengthens memory.', 'emoji': '🧠'},
    {'title': 'Spaced Repetition', 'tip': 'Review notes after 1 day, 3 days, 1 week, then 2 weeks. This greatly improves long-term retention.', 'emoji': '📅'},
    // ✅ KEY FIX: replaced curly apostrophe (you've → youve / rephrased) and removed emoji ZWJ sequence
    {'title': 'Teach to Learn', 'tip': 'Explain what you have studied to a friend or even yourself. If you can teach it, you truly understand it.', 'emoji': '👩'},
    {'title': 'Eliminate Distractions', 'tip': 'Put your phone in another room, study in a quiet place, and use website blockers if needed.', 'emoji': '📵'},
    {'title': 'Mind Maps', 'tip': 'Create visual diagrams connecting ideas. This helps you see the big picture and remember connections.', 'emoji': '🗺'},
    {'title': 'Healthy Sleep', 'tip': 'Sleep 7-8 hours. Your brain consolidates memories during sleep — cramming all night is counterproductive.', 'emoji': '😴'},
    {'title': 'Stay Hydrated', 'tip': 'Drink water regularly. Even mild dehydration reduces concentration and memory performance.', 'emoji': '💧'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Study Tips', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0891B2), foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0E7490)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Smart Study Techniques', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Science-backed methods to study better, not harder', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 16),
          ..._tips.asMap().entries.map((entry) {
            final tip = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF0891B2).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(tip['emoji']!, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tip['title']!, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0891B2))),
                  const SizedBox(height: 4),
                  Text(tip['tip']!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
                ])),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  QUOTE OF THE DAY SCREEN
// ════════════════════════════════════════════════════
class QuoteOfDayScreen extends StatelessWidget {
  const QuoteOfDayScreen({super.key});

  // ✅ FIX: explicit Map<String, String> type
  static const List<Map<String, String>> _quotes = [
    {'quote': 'Education is the most powerful weapon which you can use to change the world.', 'author': 'Nelson Mandela'},
    {'quote': 'The beautiful thing about learning is that no one can take it away from you.', 'author': 'B.B. King'},
    {'quote': 'Success is no accident. It is hard work, perseverance, learning, studying, sacrifice and most of all, love of what you are doing.', 'author': 'Pele'},
    {'quote': 'The more that you read, the more things you will know. The more that you learn, the more places you will go.', 'author': 'Dr. Seuss'},
    {'quote': 'It does not matter how slowly you go as long as you do not stop.', 'author': 'Confucius'},
    {'quote': 'Believe you can and you are halfway there.', 'author': 'Theodore Roosevelt'},
    {'quote': 'Your attitude, not your aptitude, will determine your altitude.', 'author': 'Zig Ziglar'},
  ];

  @override
  Widget build(BuildContext context) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final todayQuote = _quotes[dayOfYear % _quotes.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Quote of the Day', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('Today\'s Quote', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Text('"${todayQuote['quote']}"',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, height: 1.6)),
              const SizedBox(height: 16),
              Row(children: [
                Container(width: 30, height: 2, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(1))),
                const SizedBox(width: 10),
                Text('— ${todayQuote['author']}',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, fontStyle: FontStyle.italic)),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          Text('More Inspiring Quotes', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._quotes.where((q) => q != todayQuote).map((q) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: const Border(left: BorderSide(color: Color(0xFF7C3AED), width: 3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('"${q['quote']}"',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
              const SizedBox(height: 8),
              Text('— ${q['author']}',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w600)),
            ]),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}