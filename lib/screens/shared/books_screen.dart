// lib/screens/shared/books_screen.dart
// Teachers/Admin: add books via URL link (Google Drive / PDF link)
// Students: browse and open books
// No Firebase Storage needed — avoids unauthorized errors
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

// ─── Book Model ───────────────────────────────────────────────────────────────
class BookModel {
  final String id, title, subject, description, className;
  final String fileUrl, coverUrl, addedBy, addedById, category;
  final DateTime createdAt;

  const BookModel({
    required this.id, required this.title, required this.subject,
    required this.description, required this.className, required this.fileUrl,
    required this.coverUrl, required this.addedBy, required this.addedById,
    required this.category, required this.createdAt,
  });

  factory BookModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookModel(
      id: doc.id,
      title: d['title'] ?? '',
      subject: d['subject'] ?? '',
      description: d['description'] ?? '',
      className: d['className'] ?? 'All',
      fileUrl: d['fileUrl'] ?? '',
      coverUrl: d['coverUrl'] ?? '',
      addedBy: d['addedBy'] ?? '',
      addedById: d['addedById'] ?? '',
      category: d['category'] ?? 'Book',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─── Books Screen ─────────────────────────────────────────────────────────────
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});
  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedClass = 'All';
  String _selectedCategory = 'All';

  final _classes = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _categories = ['All', 'Book', 'Notes', 'Question Paper',
    'Sample Paper', 'Reference', 'Other'];

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
    final canAdd = user?.role == UserRole.teacher || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Books & Study Material',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        bottom: canAdd
            ? TabBar(
                controller: _tabs,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: '📚 All Books'),
                  Tab(text: '➕ Add Material'),
                ],
              )
            : null,
      ),
      body: canAdd
          ? TabBarView(
              controller: _tabs,
              children: [
                _BooksListTab(
                  selectedClass: _selectedClass,
                  selectedCategory: _selectedCategory,
                  classes: _classes,
                  categories: _categories,
                  canDelete: canAdd,
                  onClassChanged: (v) => setState(() => _selectedClass = v!),
                  onCategoryChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                _AddBookTab(user: user),
              ],
            )
          : _BooksListTab(
              selectedClass: _selectedClass,
              selectedCategory: _selectedCategory,
              classes: _classes,
              categories: _categories,
              canDelete: false,
              onClassChanged: (v) => setState(() => _selectedClass = v!),
              onCategoryChanged: (v) => setState(() => _selectedCategory = v!),
            ),
    );
  }
}

// ─── Books List Tab ───────────────────────────────────────────────────────────
class _BooksListTab extends StatefulWidget {
  final String selectedClass, selectedCategory;
  final List<String> classes, categories;
  final bool canDelete;
  final void Function(String?) onClassChanged;
  final void Function(String?) onCategoryChanged;

  const _BooksListTab({
    required this.selectedClass, required this.selectedCategory,
    required this.classes, required this.categories, required this.canDelete,
    required this.onClassChanged, required this.onCategoryChanged,
  });
  @override
  State<_BooksListTab> createState() => _BooksListTabState();
}

class _BooksListTabState extends State<_BooksListTab> {
  String _search = '';

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Book':            return const Color(0xFF059669);
      case 'Notes':           return const Color(0xFF2563EB);
      case 'Question Paper':  return const Color(0xFFDC2626);
      case 'Sample Paper':    return const Color(0xFF7C3AED);
      case 'Reference':       return const Color(0xFFD97706);
      default:                return AppColors.primary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Book':            return Icons.menu_book_rounded;
      case 'Notes':           return Icons.note_rounded;
      case 'Question Paper':  return Icons.quiz_rounded;
      case 'Sample Paper':    return Icons.assignment_rounded;
      case 'Reference':       return Icons.auto_stories_rounded;
      default:                return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Search + Filters ──────────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(children: [
          // Search bar
          TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search books, notes...',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _drop('Class', widget.selectedClass,
                widget.classes, widget.onClassChanged)),
            const SizedBox(width: 10),
            Expanded(child: _drop('Category', widget.selectedCategory,
                widget.categories, widget.onCategoryChanged)),
          ]),
        ]),
      ),
      const Divider(height: 1),

      // ── Book List ─────────────────────────────────────────────────
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('books')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF059669)));
            }

            var docs = snap.data?.docs ?? [];

            // Filters
            if (widget.selectedClass != 'All') {
              docs = docs.where((d) {
                final cls = (d.data() as Map)['className'];
                return cls == widget.selectedClass || cls == 'All';
              }).toList();
            }
            if (widget.selectedCategory != 'All') {
              docs = docs.where((d) =>
                  (d.data() as Map)['category'] ==
                  widget.selectedCategory).toList();
            }
            if (_search.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map;
                return (data['title'] ?? '').toLowerCase().contains(_search) ||
                    (data['subject'] ?? '').toLowerCase().contains(_search);
              }).toList();
            }

            if (docs.isEmpty) {
              return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_outlined,
                          size: 64,
                          color: AppColors.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No books found',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Books added by teachers appear here',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary)),
                    ]),
              );
            }

            final books = docs.map(BookModel.fromDoc).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: books.length,
              itemBuilder: (_, i) {
                final b = books[i];
                final color = _categoryColor(b.category);
                final icon  = _categoryIcon(b.category);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border(
                        left: BorderSide(color: color, width: 4)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8)
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: color, size: 26),
                        ),
                        const SizedBox(width: 12),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.title,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Wrap(spacing: 6, children: [
                                _badge(b.category, color),
                                _badge(b.className, AppColors.primary),
                                if (b.subject.isNotEmpty)
                                  _badge(b.subject, const Color(0xFF7C3AED)),
                              ]),
                              if (b.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(b.description,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.4),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                              const SizedBox(height: 8),
                              Row(children: [
                                Text(
                                  'By ${b.addedBy}  •  '
                                  '${DateFormat('dd MMM yyyy').format(b.createdAt)}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textHint),
                                ),
                              ]),
                            ],
                          ),
                        ),

                        // Action buttons
                        Column(children: [
                          if (b.fileUrl.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.open_in_new_rounded,
                                  color: color, size: 22),
                              tooltip: 'Open',
                              onPressed: () => _open(context, b.fileUrl),
                            ),
                          if (widget.canDelete)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error, size: 20),
                              tooltip: 'Delete',
                              onPressed: () => _delete(b.id),
                            ),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _open(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No link saved for this book'),
          backgroundColor: AppColors.error));
      return;
    }
    // Auto-add https:// if missing
    String fullUrl = url.trim();
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      fullUrl = 'https://$fullUrl';
    }
    final uri = Uri.tryParse(fullUrl);
    if (uri != null && uri.host.isNotEmpty && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Invalid link. Please paste a valid Google Drive or PDF URL.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3)));
      }
    }
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('books').doc(id).delete();
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color)),
      );

  Widget _drop(String label, String value, List<String> items,
      void Function(String?) onChange) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        style: GoogleFonts.poppins(
            fontSize: 13, color: AppColors.textPrimary),
        items: items
            .map((i) => DropdownMenuItem(
                value: i,
                child: Text(i, style: GoogleFonts.poppins(fontSize: 13))))
            .toList(),
        onChanged: onChange,
      );
}

// ─── Add Book Tab ─────────────────────────────────────────────────────────────
class _AddBookTab extends StatefulWidget {
  final dynamic user;
  const _AddBookTab({required this.user});
  @override
  State<_AddBookTab> createState() => _AddBookTabState();
}

class _AddBookTabState extends State<_AddBookTab> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _subjectCtrl= TextEditingController();
  final _descCtrl   = TextEditingController();
  final _urlCtrl    = TextEditingController();

  String _className = 'All';
  String _category  = 'Book';
  bool _saving = false;

  final _classes = ['All', 'Nursery', 'LKG', 'UKG',
    'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
    'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
  final _categories = ['Book', 'Notes', 'Question Paper',
    'Sample Paper', 'Reference', 'Other'];

  @override
  void dispose() {
    _titleCtrl.dispose(); _subjectCtrl.dispose();
    _descCtrl.dispose(); _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('books').add({
        'title':       _titleCtrl.text.trim(),
        'subject':     _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'fileUrl':     _urlCtrl.text.trim(),
        'coverUrl':    '',
        'className':   _className,
        'category':    _category,
        'addedBy':     widget.user?.fullName ?? 'Teacher',
        'addedById':   widget.user?.uid ?? '',
        'createdAt':   FieldValue.serverTimestamp(),
      });
      _titleCtrl.clear(); _subjectCtrl.clear();
      _descCtrl.clear(); _urlCtrl.clear();
      setState(() { _className = 'All'; _category = 'Book'; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Book added successfully!'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF059669), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Upload your file to Google Drive, then paste the shareable link below. '
                  'No file size limit!',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Title
          _field('Title *', 'e.g. Mathematics Class 10', _titleCtrl,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null),
          const SizedBox(height: 14),

          // Subject
          _field('Subject', 'e.g. Mathematics, Science, Hindi', _subjectCtrl),
          const SizedBox(height: 14),

          // Description
          _field('Description', 'Short description (optional)', _descCtrl,
              maxLines: 3),
          const SizedBox(height: 14),

          // File URL
          _field(
            'File Link *',
            'Paste Google Drive / PDF link (must start with https://)',
            _urlCtrl,
            icon: Icons.link_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Link is required';
              final url = v.trim();
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                return 'URL must start with https://';
              }
              return null;
            },
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () async {
              const helpUrl = 'https://support.google.com/drive/answer/2494822';
              final uri = Uri.parse(helpUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.help_outline_rounded, size: 14,
                color: Color(0xFF059669)),
            label: Text('How to get Google Drive share link?',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF059669))),
          ),
          const SizedBox(height: 14),

          // Category + Class row
          Row(children: [
            Expanded(child: _labelWrap('Category',
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: _dec('Category'),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textPrimary),
                  items: _categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ))),
            const SizedBox(width: 12),
            Expanded(child: _labelWrap('For Class',
                DropdownButtonFormField<String>(
                  value: _className,
                  decoration: _dec('Class'),
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textPrimary),
                  items: _classes.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c,
                          style: GoogleFonts.poppins(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _className = v!),
                ))),
          ]),
          const SizedBox(height: 28),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                disabledBackgroundColor: AppColors.divider,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Add Book / Material',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl,
      {int maxLines = 1,
      IconData? icon,
      String? Function(String?)? validator}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _dec(hint).copyWith(
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: AppColors.textHint)
                : null,
          ),
        ),
      ]);

  Widget _labelWrap(String label, Widget child) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        child,
      ]);

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            fontSize: 12, color: AppColors.textHint),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: Color(0xFF059669), width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error)),
      );
}