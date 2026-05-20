// lib/screens/shared/file_viewer_screen.dart
// In-app viewer for PDF and image files (used by books_screen, homework_screen, study_material_screen)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FileViewerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isPdf;

  const FileViewerScreen({
    super.key,
    required this.url,
    required this.title,
    required this.isPdf,
  });

  /// Factory: auto-detects type from URL extension
  factory FileViewerScreen.fromUrl({required String url, required String title}) {
    final lower = url.toLowerCase().split('?').first; // strip query params
    final isPdf = lower.endsWith('.pdf');
    return FileViewerScreen(url: url, title: title, isPdf: isPdf);
  }

  @override
  State<FileViewerScreen> createState() => _FileViewerScreenState();
}

class _FileViewerScreenState extends State<FileViewerScreen> {
  // PDF state
  String? _localPdfPath;
  bool _pdfLoading = true;
  String? _pdfError;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfController;

  @override
  void initState() {
    super.initState();
    if (widget.isPdf) _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      setState(() { _pdfLoading = true; _pdfError = null; });
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) throw Exception('Download failed');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(response.bodyBytes);
      if (mounted) setState(() { _localPdfPath = file.path; _pdfLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _pdfError = e.toString(); _pdfLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.isPdf ? 'PDF Document' : 'Image',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (widget.isPdf && _totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: widget.isPdf ? _buildPdfViewer() : _buildImageViewer(),
      // Page nav for PDF
      bottomNavigationBar: (widget.isPdf && !_pdfLoading && _pdfError == null && _totalPages > 1)
          ? _buildPdfNavBar()
          : null,
    );
  }

  // ── PDF Viewer ────────────────────────────────────────────────────────────
  Widget _buildPdfViewer() {
    if (_pdfLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Loading PDF...', style: TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }

    if (_pdfError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text('Failed to load PDF',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Please check your connection and try again.',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
            ),
          ],
        ),
      );
    }

    return PDFView(
      filePath: _localPdfPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageSnap: false,
      fitPolicy: FitPolicy.BOTH,
      onRender: (pages) => setState(() => _totalPages = pages ?? 0),
      onViewCreated: (ctrl) => setState(() => _pdfController = ctrl),
      onPageChanged: (page, _) => setState(() => _currentPage = page ?? 0),
      onError: (e) => setState(() => _pdfError = e.toString()),
    );
  }

  Widget _buildPdfNavBar() {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => _pdfController?.setPage(_currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 8),
          Text(
            'Page ${_currentPage + 1} of $_totalPages',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () => _pdfController?.setPage(_currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // ── Image Viewer ──────────────────────────────────────────────────────────
  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: CachedNetworkImage(
          imageUrl: widget.url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (_, __, ___) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                const SizedBox(height: 12),
                Text('Could not load image',
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}