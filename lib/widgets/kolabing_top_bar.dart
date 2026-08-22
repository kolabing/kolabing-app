import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme/color_tokens.dart';
import '../config/theme/typography.dart';

class KolabingTopBar extends StatelessWidget implements PreferredSizeWidget {
  const KolabingTopBar({
    super.key,
    this.title,
    this.showBack = true,
    this.onBack,
    this.trailing,
    this.backgroundColor,
  });

  final String? title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  Widget _titleWidget(KolabingColorTokens colors) {
    final t = title;
    if (t == null) {
      return const SizedBox.shrink();
    }
    return Text(
      t,
      style: KolabingTextStyles.sectionHeader.copyWith(color: colors.ink),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _trailingWidget() {
    final w = trailing;
    if (w == null) {
      return const SizedBox.shrink();
    }
    return Center(child: w);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bgColor = backgroundColor ?? colors.appBackground;
    final topPadding = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        height: preferredSize.height + topPadding,
        padding: EdgeInsets.only(top: topPadding),
        color: bgColor,
        child: Row(
          children: [
            if (showBack)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _CircularBackButton(
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                  colors: colors,
                ),
              )
            else
              const SizedBox(width: 56),
            Expanded(child: _titleWidget(colors)),
            SizedBox(width: 56, child: _trailingWidget()),
          ],
        ),
      ),
    );
  }
}

class _CircularBackButton extends StatelessWidget {
  const _CircularBackButton({required this.onTap, required this.colors});

  final VoidCallback onTap;
  final KolabingColorTokens colors;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.hairline),
      ),
      child: Icon(Icons.arrow_back_rounded, color: colors.ink, size: 20),
    ),
  );
}
