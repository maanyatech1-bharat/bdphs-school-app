// lib/widgets/alert_ticker.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/school_service.dart';
import '../theme/app_theme.dart';

class AlertTicker extends StatefulWidget {
  const AlertTicker({super.key});
  @override
  State<AlertTicker> createState() => _AlertTickerState();
}

class _AlertTickerState extends State<AlertTicker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final _service = SchoolService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _animation = Tween<double>(begin: 1.0, end: -1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Color _alertColor(String type) {
    switch (type) {
      case 'urgent': return const Color(0xFFEF4444);
      case 'warning': return const Color(0xFFF59E0B);
      default: return AppColors.primary;
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'urgent': return Icons.warning_rounded;
      case 'warning': return Icons.info_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AlertModel>>(
      stream: _service.getActiveAlerts(),
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) return const SizedBox();

        final alert = alerts.first;
        final color = _alertColor(alert.type);

        return Container(
          height: 36,
          color: color.withValues(alpha: 0.12),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 36, height: 36,
                color: color,
                child: Icon(_alertIcon(alert.type), color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              // Scrolling text
              Expanded(
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (_, child) => FractionalTranslation(
                      translation: Offset(_animation.value, 0),
                      child: child,
                    ),
                    child: Text(
                      alert.message,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // LIVE badge for urgent
              if (alert.type == 'urgent')
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  child: Text('ALERT', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                ),
            ],
          ),
        );
      },
    );
  }
}