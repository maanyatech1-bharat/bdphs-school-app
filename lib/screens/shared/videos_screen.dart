import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../../models/user_model.dart';

class VideoScreen extends StatefulWidget {
  final UserModel user;
  const VideoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  String _selectedClass = 'All';
  String _search = '';
  bool _uploading = false;
  double _uploadProgress = 0;

  final List<String> _allClasses = [
    'Nursery','LKG','UKG',
    'Class 1','Class 2','Class 3','Class 4',
    'Class 5','Class 6','Class 7','Class 8',
    'Class 9','Class 10','Class 11','Class 12',
  ];

  bool get _isAdmin => widget.user.role == UserRole.admin;
  bool get _isTeacher => widget.user.role == UserRole.teacher;
  bool get _isStudent => widget.user.role == UserRole.student;

  String get _studentClass =>
      (_isStudent && widget.user is StudentModel)
          ? (widget.user as StudentModel).className
          : '';

  List<String> get _teacherClasses =>
      (_isTeacher && widget.user is TeacherModel)
          ? (widget.user as TeacherModel).assignedClasses
          : [];

  List<String> get _filterChips {
    if (_isAdmin) return ['All', ..._allClasses];
    if (_isTeacher) {
      final tc = _teacherClasses;
      return tc.isEmpty ? ['All', ..._allClasses] : ['All', ...tc];
    }
    return [];
  }

  Query<Map<String, dynamic>> get _query {
    var q = _firestore.collection('videos').orderBy('uploadedAt', descending: true);
    if (_isStudent && _studentClass.isNotEmpty) {
      q = q.where('className', isEqualTo: _studentClass);
    } else if (!_isStudent && _selectedClass != 'All') {
      q = q.where('className', isEqualTo: _selectedClass);
    }
    return q;
  }

  Future<void> _uploadVideo() async {
    // Step 1: pick class
    final classList = _isTeacher
        ? (_teacherClasses.isEmpty ? _allClasses : _teacherClasses)
        : _allClasses;

    String? uploadClass = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Class'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: classList
                .map((c) => ListTile(
                      title: Text(c),
                      onTap: () => Navigator.pop(ctx, c),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    if (uploadClass == null) return;

    // Step 2: pick video file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    if (file.size > 200 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large. Max 200MB.')),
      );
      return;
    }

    // Step 3: title/subject
    final titleCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Video Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Upload')),
        ],
      ),
    );
    if (confirmed != true || titleCtrl.text.trim().isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = _storage.ref('videos/$uploadClass/$fileName');
      final uploadTask = ref.putFile(File(file.path!));

      uploadTask.snapshotEvents.listen((snap) {
        if (mounted) {
          setState(() {
            _uploadProgress = snap.bytesTransferred / snap.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      await _firestore.collection('videos').add({
        'title': titleCtrl.text.trim(),
        'subject': subjectCtrl.text.trim(),
        'className': uploadClass,
        'url': url,
        'storagePath': 'videos/$uploadClass/$fileName',
        'uploadedBy': widget.user.uid,
        'uploaderName': widget.user.fullName,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _uploading = false; _uploadProgress = 0; });
    }
  }

  Future<void> _deleteVideo(
      String docId, String storagePath, String uploadedBy) async {
    if (!_isAdmin && widget.user.uid != uploadedBy) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only delete your own videos.')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      if (storagePath.isNotEmpty) await _storage.ref(storagePath).delete();
      await _firestore.collection('videos').doc(docId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video deleted.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (_isAdmin || _isTeacher)
            IconButton(
              icon: const Icon(Icons.upload_rounded),
              tooltip: 'Upload Video',
              onPressed: _uploading ? null : _uploadVideo,
            ),
        ],
      ),
      body: Column(
        children: [
          // Upload progress
          if (_uploading)
            Column(
              children: [
                LinearProgressIndicator(value: _uploadProgress),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),

          // Student class banner
          if (_isStudent)
            Container(
              width: double.infinity,
              color: const Color(0xFF1565C0),
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Text(
                'Showing videos for $_studentClass',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),

          // Class filter chips (admin/teacher)
          if (!_isStudent && _filterChips.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: _filterChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cls = _filterChips[i];
                  final selected = _selectedClass == cls;
                  return ChoiceChip(
                    label: Text(cls,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white : null)),
                    selected: selected,
                    selectedColor: const Color(0xFF1565C0),
                    onSelected: (_) =>
                        setState(() => _selectedClass = cls),
                  );
                },
              ),
            ),

          // Search bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search title, subject or teacher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              onChanged: (v) =>
                  setState(() => _search = v.toLowerCase()),
            ),
          ),

          // Video list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _query.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                final filtered = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  if (_search.isEmpty) return true;
                  final title =
                      (data['title'] ?? '').toString().toLowerCase();
                  final subject =
                      (data['subject'] ?? '').toString().toLowerCase();
                  final uploader =
                      (data['uploaderName'] ?? '').toString().toLowerCase();
                  return title.contains(_search) ||
                      subject.contains(_search) ||
                      uploader.contains(_search);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No videos found.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final canDelete = _isAdmin ||
                        widget.user.uid == (data['uploadedBy'] ?? '');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.play_circle_filled,
                              color: Color(0xFF1565C0), size: 36),
                        ),
                        title: Text(
                          data['title'] ?? 'Untitled',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${data['subject'] ?? ''} • ${data['className'] ?? ''}\nBy ${data['uploaderName'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow,
                                  color: Color(0xFF1565C0)),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _VideoPlayerScreen(
                                    url: data['url'] ?? '',
                                    title: data['title'] ?? 'Video',
                                  ),
                                ),
                              ),
                            ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () => _deleteVideo(
                                  doc.id,
                                  data['storagePath'] ?? '',
                                  data['uploadedBy'] ?? '',
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Video Player Screen ───────────────────────────────────────────────────────

class _VideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  const _VideoPlayerScreen({required this.url, required this.title});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _skip(int seconds) {
    final pos = _controller.value.position;
    final dur = _controller.value.duration;
    final next = pos + Duration(seconds: seconds);
    final clamped = next < Duration.zero
        ? Duration.zero
        : (next > dur ? dur : next);
    _controller.seekTo(clamped);
  }

  void _toggleFullscreen() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    SystemChrome.setPreferredOrientations(
      isLandscape
          ? [DeviceOrientation.portraitUp]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              title: Text(widget.title,
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.black87,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: const [
                Icon(Icons.no_photography, color: Colors.white54, size: 20),
                SizedBox(width: 12),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Center(
          child: _initialized
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                    if (_showControls)
                      Container(
                        color: Colors.black45,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: _controller,
                              builder: (_, VideoPlayerValue val, __) {
                                final pos = val.position;
                                final dur = val.duration;
                                final maxMs = dur.inMilliseconds.toDouble();
                                return Column(
                                  children: [
                                    Slider(
                                      value: pos.inMilliseconds
                                          .toDouble()
                                          .clamp(0, maxMs == 0 ? 1 : maxMs),
                                      max: maxMs == 0 ? 1 : maxMs,
                                      onChanged: (v) => _controller.seekTo(
                                          Duration(milliseconds: v.toInt())),
                                      activeColor: Colors.white,
                                      inactiveColor: Colors.white38,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_fmt(pos),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                          Text(_fmt(dur),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay_10,
                                      color: Colors.white, size: 32),
                                  onPressed: () => _skip(-10),
                                ),
                                ValueListenableBuilder(
                                  valueListenable: _controller,
                                  builder: (_, VideoPlayerValue val, __) =>
                                      IconButton(
                                    icon: Icon(
                                      val.isPlaying
                                          ? Icons.pause_circle
                                          : Icons.play_circle,
                                      color: Colors.white,
                                      size: 52,
                                    ),
                                    onPressed: () => val.isPlaying
                                        ? _controller.pause()
                                        : _controller.play(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_10,
                                      color: Colors.white, size: 32),
                                  onPressed: () => _skip(10),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.fullscreen,
                                      color: Colors.white, size: 32),
                                  onPressed: _toggleFullscreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                  ],
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
