// lib/screens/shared/notices_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});
  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _isStudent;

  @override
  void initState() {
    super.initState();
    _isStudent = context.read<AppAuthProvider>().currentUser?.role == UserRole.student;
    _tabController = TabController(length: _isStudent ? 2 : 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canPost = user?.role == UserRole.admin ||
        (user?.role == UserRole.teacher &&
            user?.approvalStatus == ApprovalStatus.approved);

    // FIX: check if we can go back (pushed via Navigator) or not (root tab)
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            // FIX: no expandedHeight — use plain AppBar style to avoid
            // FlexibleSpaceBar title colliding with the TabBar tabs
            automaticallyImplyLeading: canPop,
            leading: canPop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            backgroundColor: AppColors.primary,
            // FIX: title in the AppBar row, not in FlexibleSpaceBar
            title: Text(
              'Notices',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                const Tab(text: 'All'),
                const Tab(text: 'Students'),
                if (!_isStudent) const Tab(text: 'Teachers'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _NoticesList(audience: 'all', canManage: canPost),
            _NoticesList(audience: 'students', canManage: canPost),
            if (!_isStudent)
              _NoticesList(audience: 'teachers', canManage: canPost),
          ],
        ),
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => _showPostSheet(context, user),
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Post Notice',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _showPostSheet(BuildContext context, UserModel? user) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String audience = 'all';
    bool isPinned = false;
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.campaign_rounded,
                          color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('Post New Notice',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        label: 'Notice Title',
                        hint: 'Enter a clear title',
                        controller: titleCtrl,
                        prefixIcon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 16),
                      Text('Content',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: contentCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Write notice content here...',
                          hintStyle: GoogleFonts.poppins(
                              color: AppColors.textHint, fontSize: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.divider)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.divider)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Audience
                      Text('Target Audience',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final a in [
                            ['All', 'all'],
                            ['Students', 'students'],
                            ['Teachers', 'teachers']
                          ])
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setModal(() => audience = a[1]),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                  decoration: BoxDecoration(
                                    color: audience == a[1]
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: audience == a[1]
                                          ? AppColors.primary
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(a[0],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: audience == a[1]
                                              ? Colors.white
                                              : AppColors.textSecondary)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Pin toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.push_pin_rounded,
                                color: AppColors.accent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Pin Notice',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  Text('Pinned notices appear at the top',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            Switch(
                              value: isPinned,
                              onChanged: (v) =>
                                  setModal(() => isPinned = v),
                              activeColor: AppColors.accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isPosting
                              ? null
                              : () async {
                                  if (titleCtrl.text.trim().isEmpty ||
                                      contentCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Please fill title and content'),
                                      backgroundColor: AppColors.error,
                                    ));
                                    return;
                                  }
                                  setModal(() => isPosting = true);
                                  try {
                                    await NoticeService().postNotice(
                                      title: titleCtrl.text.trim(),
                                      content: contentCtrl.text.trim(),
                                      postedBy: user!.uid,
                                      postedByName: user.fullName,
                                      targetAudience: audience,
                                      isPinned: isPinned,
                                    );
                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Notice posted successfully!'),
                                        backgroundColor: AppColors.success,
                                      ));
                                    }
                                  } catch (e) {
                                    setModal(() => isPosting = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isPosting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('Post Notice',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── NOTICES LIST ─────────────────────────────────────────────────────────────
class _NoticesList extends StatelessWidget {
  final String audience;
  final bool canManage;
  const _NoticesList({required this.audience, required this.canManage});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NoticeModel>>(
      stream: NoticeService().getNotices(audience: audience),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const ShimmerCard());
        }
        final notices = snapshot.data ?? [];
        if (notices.isEmpty) {
          return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No Notices Yet',
              subtitle: 'No announcements have been posted.');
        }
        final pinned = notices.where((n) => n.isPinned).toList();
        final regular = notices.where((n) => !n.isPinned).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            if (pinned.isNotEmpty) ...[
              _SectionLabel(label: '📌 Pinned'),
              ...pinned
                  .map((n) => _NoticeCard(notice: n, canManage: canManage)),
              const SizedBox(height: 8),
            ],
            if (regular.isNotEmpty) ...[
              if (pinned.isNotEmpty) _SectionLabel(label: '🔔 Recent'),
              ...regular
                  .map((n) => _NoticeCard(notice: n, canManage: canManage)),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
      );
}

// ─── NOTICE CARD ──────────────────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final bool canManage;
  const _NoticeCard({required this.notice, required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: notice.isPinned
            ? Border.all(
                color: AppColors.accent.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              color: notice.isPinned
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (notice.isPinned) ...[
                  const Icon(Icons.push_pin_rounded,
                      size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(notice.title,
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 18, color: AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                          value: 'pin',
                          child: Text(notice.isPinned ? 'Unpin' : 'Pin',
                              style: GoogleFonts.poppins(fontSize: 13))),
                      PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.error))),
                    ],
                    onSelected: (val) async {
                      if (val == 'delete') {
                        await NoticeService().deleteNotice(notice.id);
                      } else {
                        await NoticeService()
                            .togglePin(notice.id, !notice.isPinned);
                      }
                    },
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(notice.content,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6)),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(notice.postedByName,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textHint)),
                const Spacer(),
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(DateFormat('dd MMM, hh:mm a').format(notice.createdAt),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textHint)),
                const SizedBox(width: 8),
                _AudienceBadge(audience: notice.targetAudience),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudienceBadge extends StatelessWidget {
  final String audience;
  const _AudienceBadge({required this.audience});
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (audience) {
      case 'students':
        color = AppColors.studentColor;
        label = 'Students';
        break;
      case 'teachers':
        color = AppColors.teacherColor;
        label = 'Teachers';
        break;
      default:
        color = AppColors.primary;
        label = 'All';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}