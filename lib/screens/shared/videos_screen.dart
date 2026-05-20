// lib/screens/shared/videos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/auth_provider.dart';
import '../../services/school_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class VideosScreen extends StatelessWidget {
  const VideosScreen({super.key});

  void _showAddVideo(BuildContext context, String uid, String name) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'youtube';
    bool isSaving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) => Container(
        height: MediaQuery.of(ctx).size.height * 0.70,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 48, height: 4,
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(children: [
              const Icon(Icons.video_library_rounded, color: AppColors.error),
              const SizedBox(width: 10),
              Text('Post Video / Event', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          const Divider(height: 20),
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Type selector
              Row(children: [
                _TypeBtn(label: '▶ YouTube', value: 'youtube', selected: type, onTap: () => setModal(() => type = 'youtube'), color: Colors.red),
                const SizedBox(width: 8),
                _TypeBtn(label: 'f Facebook', value: 'facebook', selected: type, onTap: () => setModal(() => type = 'facebook'), color: const Color(0xFF1877F2)),
                const SizedBox(width: 8),
                _TypeBtn(label: '🔗 Other', value: 'other', selected: type, onTap: () => setModal(() => type = 'other'), color: AppColors.primary),
              ]),
              const SizedBox(height: 14),
              AppTextField(label: 'Title', hint: 'e.g. Annual Day 2024', controller: titleCtrl, prefixIcon: Icons.title_rounded),
              const SizedBox(height: 12),
              AppTextField(label: 'Video URL / Link', hint: 'Paste YouTube or Facebook link', controller: urlCtrl, prefixIcon: Icons.link_rounded),
              const SizedBox(height: 12),
              AppTextField(label: 'Description (Optional)', hint: 'About this video...', controller: descCtrl, prefixIcon: Icons.description_rounded),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Text('💡 Paste the full YouTube link e.g.\nhttps://youtube.com/watch?v=xxxxx',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : () async {
                    if (titleCtrl.text.trim().isEmpty || urlCtrl.text.trim().isEmpty) return;
                    setModal(() => isSaving = true);
                    await SchoolService().postVideo(SchoolVideo(
                      id: '', title: titleCtrl.text.trim(), description: descCtrl.text.trim(),
                      url: urlCtrl.text.trim(), videoType: type,
                      postedBy: uid, postedByName: name, createdAt: DateTime.now(),
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.post_add_rounded, color: Colors.white),
                  label: Text('Post Video', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppAuthProvider>().currentUser;
    final canPost = user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Videos & Events', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFCC0000),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SchoolVideo>>(
        stream: SchoolService().getVideos(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(padding: const EdgeInsets.all(16), itemCount: 4, itemBuilder: (_, __) => const ShimmerCard());
          }
          final videos = snapshot.data ?? [];
          if (videos.isEmpty) return const EmptyState(
            icon: Icons.video_library_outlined, title: 'No Videos Yet',
            subtitle: 'School event videos and links will appear here',
          );
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (_, i) {
              final v = videos[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 160,
                      color: Colors.black87,
                      child: Stack(fit: StackFit.expand, children: [
                        if (v.youtubeId != null)
                          Image.network(
                            'https://img.youtube.com/vi/${v.youtubeId}/hqdefault.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _VideoPlaceholder(type: v.videoType),
                          )
                        else _VideoPlaceholder(type: v.videoType),
                        Center(child: Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.9), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                        )),
                        Positioned(top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _typeColor(v.videoType).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
                            child: Text(_typeLabel(v.videoType), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v.title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      if (v.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(v.description, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(v.postedByName, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                        const Spacer(),
                        Text(DateFormat('dd MMM yyyy').format(v.createdAt), style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: v.url));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Link copied! Open in YouTube/Browser'),
                              backgroundColor: AppColors.success,
                            ));
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                          label: Text('Copy Link', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )),
                        if (canPost) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            onPressed: () => SchoolService().deleteVideo(v.id),
                          ),
                        ],
                      ]),
                    ]),
                  ),
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: canPost && user != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddVideo(context, user.uid, user.fullName),
              backgroundColor: Colors.red,
              icon: const Icon(Icons.video_call_rounded, color: Colors.white),
              label: Text('Post Video', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'youtube': return Colors.red;
      case 'facebook': return const Color(0xFF1877F2);
      default: return AppColors.primary;
    }
  }
  String _typeLabel(String type) {
    switch (type) {
      case 'youtube': return '▶ YouTube';
      case 'facebook': return 'f Facebook';
      default: return '🔗 Link';
    }
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String type;
  const _VideoPlaceholder({required this.type});
  @override
  Widget build(BuildContext context) => Container(
    color: type == 'youtube' ? const Color(0xFF1A1A1A) : const Color(0xFF1877F2).withValues(alpha: 0.3),
    child: Center(child: Icon(
      type == 'youtube' ? Icons.smart_display_rounded : Icons.video_library_rounded,
      size: 48, color: Colors.white54,
    )),
  );
}

class _TypeBtn extends StatelessWidget {
  final String label, value, selected;
  final VoidCallback onTap;
  final Color color;
  const _TypeBtn({required this.label, required this.value, required this.selected, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected == value ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: selected == value ? 0 : 1),
      ),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600,
        color: selected == value ? Colors.white : color)),
    ),
  );
}