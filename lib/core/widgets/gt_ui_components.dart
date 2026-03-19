import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:otakulog/app/theme.dart';

class GTCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final Color? color;
  final BorderSide? borderSide;

  const GTCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.color,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: color ?? AppTheme.surface,
            borderRadius: borderRadius,
            border: Border.fromBorderSide(
              borderSide ?? BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GTProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;

  const GTProgressBar({super.key, required this.progress, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

class GTPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const GTPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label.toUpperCase()),
    );
  }
}

class GTSectionHeader extends StatelessWidget {
  final String title;

  const GTSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class GTStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const GTStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GTCard(
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GTEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;

  const GTEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.secondaryText.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 32),
              GTPrimaryButton(
                label: buttonLabel!,
                onPressed: onButtonPressed!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GTCircularAvatar extends StatelessWidget {
  final String? path;
  final double radius;

  const GTCircularAvatar({super.key, this.path, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.elevated,
      backgroundImage: (path != null && path!.isNotEmpty)
          ? (path!.startsWith('http')
              ? NetworkImage(path!) as ImageProvider
              : AssetImage(path!) as ImageProvider)
          : null,
      child: (path == null || path!.isEmpty)
          ? Icon(Icons.person, color: AppTheme.secondaryText, size: radius)
          : null,
    );
  }
}

class GTCoverImage extends StatelessWidget {
  final String imageUrl;
  final String title;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? badge;

  const GTCoverImage({
    super.key,
    required this.imageUrl,
    required this.title,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => _fallback(),
            errorWidget: (context, url, error) => _fallback(),
          )
        : _fallback();

    if (borderRadius == null) return image;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }

  Widget _fallback() {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B1B22), Color(0xFF101015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              _initials(title),
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (badge != null && imageUrl.isNotEmpty)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Text(
                  badge!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList();

    if (words.isEmpty) return '?';
    return words.map((word) => word[0].toUpperCase()).join();
  }
}
