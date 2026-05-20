// lib/widgets/custom_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

// ─── APP LOGO ─────────────────────────────────────────────────────────────────
class BDPHSLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool darkBackground;
  const BDPHSLogo({super.key, this.size = 60, this.showText = true, this.darkBackground = false});

  @override
  Widget build(BuildContext context) {
    final textColor = darkBackground ? Colors.white : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: darkBackground
                ? const LinearGradient(colors: [Colors.white24, Colors.white10])
                : AppColors.primaryGradient,
            border: Border.all(
              color: darkBackground ? Colors.white38 : AppColors.accent,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12, spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text('B',
              style: GoogleFonts.playfairDisplay(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w800,
                color: darkBackground ? AppColors.accent : Colors.white,
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text('BDPHS',
            style: GoogleFonts.playfairDisplay(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 2,
            ),
          ),
          Text('Student Management',
            style: GoogleFonts.poppins(
              fontSize: size * 0.13,
              fontWeight: FontWeight.w400,
              color: textColor.withOpacity(0.7),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── GRADIENT BUTTON ──────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final LinearGradient? gradient;
  final IconData? icon;
  final double height;
  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
            : (gradient ?? AppColors.primaryGradient),
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed == null ? [] : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(text, style: AppTextStyles.buttonText),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── CUSTOM TEXT FIELD ────────────────────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffix,
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ─── STAT CARD ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
            style: GoogleFonts.poppins(
              fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(title,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
              style: GoogleFonts.poppins(fontSize: 10, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── USER AVATAR ──────────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  const UserAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.size = 48,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
        : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor ?? AppColors.primary.withOpacity(0.1),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl!,
            width: size, height: size, fit: BoxFit.cover,
            placeholder: (_, __) => Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(color: Colors.white),
            ),
            errorWidget: (_, __, ___) => _initials(initials),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? AppColors.primary,
      child: _initials(initials),
    );
  }

  Widget _initials(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: size * 0.35, fontWeight: FontWeight.w600, color: Colors.white,
    ),
  );
}

// ─── APPROVAL STATUS BADGE ────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.success; label = 'Approved'; icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppColors.error; label = 'Rejected'; icon = Icons.cancel;
        break;
      default:
        color = AppColors.warning; label = 'Pending'; icon = Icons.schedule;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── SHIMMER LOADING ──────────────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height, margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─── NOTICE CARD ─────────────────────────────────────────────────────────────
class NoticeCard extends StatelessWidget {
  final String title;
  final String content;
  final String postedBy;
  final DateTime postedAt;
  final bool isPinned;
  final Color? accentColor;
  const NoticeCard({
    super.key,
    required this.title,
    required this.content,
    required this.postedBy,
    required this.postedAt,
    this.isPinned = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPinned ? Border.all(color: AppColors.accent, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (isPinned) ...[
                  const Icon(Icons.push_pin, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color,
                    ),
                  ),
                ),
                Text(_formatDate(postedAt),
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(postedBy,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(title,
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}