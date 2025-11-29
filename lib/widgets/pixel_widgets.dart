import 'package:flutter/material.dart';
import '../theme/pixel_theme.dart';

// Pixel-styled button with 3D effect
class PixelButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const PixelButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: PixelTheme.pixelButton(
          color: widget.color ?? PixelTheme.primary,
          isPressed: _isPressed,
        ),
        transform: _isPressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        child: widget.isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PixelTheme.textPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 16, color: PixelTheme.textPrimary),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.text, style: PixelTheme.buttonText),
                ],
              ),
      ),
    );
  }
}

// Pixel-styled text field
class PixelTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;

  const PixelTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: PixelTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: PixelTheme.pixelBox(),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: PixelTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: PixelTheme.bodyMedium.copyWith(color: PixelTheme.textMuted),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: PixelTheme.textSecondary, size: 20)
                  : null,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

// Pixel-styled card
class PixelCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const PixelCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: PixelTheme.pixelCard(color: color),
        child: child,
      ),
    );
  }
}

// Pixel-styled icon button
class PixelIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;
  final double size;

  const PixelIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.iconColor,
    this.size = 40,
  });

  @override
  State<PixelIconButton> createState() => _PixelIconButtonState();
}

class _PixelIconButtonState extends State<PixelIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.size,
        height: widget.size,
        decoration: PixelTheme.pixelButton(
          color: widget.color ?? PixelTheme.surface,
          isPressed: _isPressed,
        ),
        transform: _isPressed
            ? Matrix4.translationValues(1, 1, 0)
            : Matrix4.identity(),
        child: Icon(
          widget.icon,
          color: widget.iconColor ?? PixelTheme.textPrimary,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

// Pixel progress bar
class PixelProgressBar extends StatelessWidget {
  final double progress;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;

  const PixelProgressBar({
    super.key,
    required this.progress,
    this.backgroundColor,
    this.progressColor,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? PixelTheme.coalBlack,
        border: Border.all(color: PixelTheme.pixelBorder, width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * progress.clamp(0, 1),
                decoration: BoxDecoration(
                  color: progressColor ?? PixelTheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Pixel avatar with border
class PixelAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? text;
  final double size;
  final Color? backgroundColor;

  const PixelAvatar({
    super.key,
    this.imageUrl,
    this.text,
    this.size = 60,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? PixelTheme.primary,
        border: Border.all(color: PixelTheme.pixelBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: imageUrl != null
          ? Image.network(imageUrl!, fit: BoxFit.cover)
          : Center(
              child: Text(
                text?.isNotEmpty == true ? text![0].toUpperCase() : '?',
                style: PixelTheme.headingMedium.copyWith(fontSize: size * 0.4),
              ),
            ),
    );
  }
}

// Pixel dialog
class PixelDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const PixelDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: PixelTheme.pixelCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: PixelTheme.primary,
                border: Border(
                  bottom: BorderSide(color: PixelTheme.pixelBorder, width: 2),
                ),
              ),
              child: Text(
                title,
                style: PixelTheme.headingSmall,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
            if (actions != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Pixel loading indicator
class PixelLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const PixelLoader({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  State<PixelLoader> createState() => _PixelLoaderState();
}

class _PixelLoaderState extends State<PixelLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animation = (_controller.value + delay) % 1.0;
            final scale = animation < 0.5 ? animation * 2 : 2 - animation * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: widget.size / 4,
              height: widget.size / 4 + (scale * widget.size / 4),
              color: widget.color ?? PixelTheme.primary,
            );
          }),
        );
      },
    );
  }
}

// Pixel song tile
class PixelSongTile extends StatelessWidget {
  final String title;
  final String artist;
  final String? imageUrl;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const PixelSongTile({
    super.key,
    required this.title,
    required this.artist,
    this.imageUrl,
    this.isPlaying = false,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: PixelTheme.pixelBox(
          color: isPlaying ? PixelTheme.primary.withValues(alpha: 0.2) : PixelTheme.surface,
          borderColor: isPlaying ? PixelTheme.primary : PixelTheme.pixelBorder,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: PixelTheme.surfaceLight,
                border: Border.all(color: PixelTheme.pixelBorder, width: 2),
              ),
              child: imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : Icon(
                      isPlaying ? Icons.music_note : Icons.album,
                      color: isPlaying ? PixelTheme.primary : PixelTheme.textSecondary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PixelTheme.bodyLarge.copyWith(
                      color: isPlaying ? PixelTheme.primary : PixelTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    style: PixelTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPlaying)
              Container(
                padding: const EdgeInsets.all(6),
                child: const _PixelEqualizer(),
              ),
            if (onMoreTap != null)
              PixelIconButton(
                icon: Icons.more_vert,
                size: 32,
                onPressed: onMoreTap,
              ),
          ],
        ),
      ),
    );
  }
}

// Animated equalizer for playing songs
class _PixelEqualizer extends StatefulWidget {
  const _PixelEqualizer();

  @override
  State<_PixelEqualizer> createState() => _PixelEqualizerState();
}

class _PixelEqualizerState extends State<_PixelEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final phase = (index * 0.3 + _controller.value) % 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: 8 + (phase * 8),
              color: PixelTheme.primary,
            );
          }),
        );
      },
    );
  }
}
