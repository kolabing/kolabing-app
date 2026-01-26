import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/colors.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../models/user_model.dart';
import '../widgets/selection_card.dart';

export '../widgets/selection_card.dart' show SelectionUserType;

/// User Type Selection Screen
///
/// Allows new users to select their account type (Business or Community)
/// before proceeding to onboarding.
class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends ConsumerState<UserTypeSelectionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;

  // Staggered animations
  late final Animation<double> _headlineAnimation;
  late final Animation<double> _subtitleAnimation;
  late final Animation<double> _businessCardAnimation;
  late final Animation<double> _communityCardAnimation;
  late final Animation<double> _bottomLinkAnimation;

  // Slide animations
  late final Animation<Offset> _headlineSlideAnimation;
  late final Animation<Offset> _subtitleSlideAnimation;
  late final Animation<Offset> _businessCardSlideAnimation;
  late final Animation<Offset> _communityCardSlideAnimation;
  late final Animation<Offset> _bottomLinkSlideAnimation;

  /// Selected user type (null = none selected)
  SelectionUserType? _selectedType;

  @override
  void initState() {
    super.initState();
    _configureSystemUI();
    _initializeAnimations();
    _startEntryAnimation();
  }

  void _configureSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: KolabingColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _initializeAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Staggered opacity animations
    _headlineAnimation = _createOpacityAnimation(0.0, 0.4);
    _subtitleAnimation = _createOpacityAnimation(0.1, 0.5);
    _businessCardAnimation = _createOpacityAnimation(0.2, 0.6);
    _communityCardAnimation = _createOpacityAnimation(0.3, 0.7);
    _bottomLinkAnimation = _createOpacityAnimation(0.4, 0.8);

    // Staggered slide animations
    _headlineSlideAnimation = _createSlideAnimation(0.0, 0.4);
    _subtitleSlideAnimation = _createSlideAnimation(0.1, 0.5);
    _businessCardSlideAnimation = _createSlideAnimation(0.2, 0.6);
    _communityCardSlideAnimation = _createSlideAnimation(0.3, 0.7);
    _bottomLinkSlideAnimation = _createSlideAnimation(0.4, 0.8);
  }

  Animation<double> _createOpacityAnimation(double begin, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _createSlideAnimation(double begin, double end) =>
      Tween<Offset>(
        begin: const Offset(0, 20),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(begin, end, curve: Curves.easeOut),
        ),
      );

  void _startEntryAnimation() {
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _handleBack() {
    context.pop();
  }

  void _handleCardTap(SelectionUserType type) {
    setState(() => _selectedType = type);

    // Brief delay to show selection, then navigate
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        // Initialize onboarding with the selected user type
        final userType = type == SelectionUserType.business
            ? UserType.business
            : UserType.community;
        ref.read(onboardingProvider.notifier).initialize(userType);

        // Navigate directly to onboarding step 1
        if (type == SelectionUserType.business) {
          context.push('/onboarding/business/step1');
        } else {
          context.push('/onboarding/community/step1');
        }
      }
    });
  }

  void _navigateToLogin() {
    HapticFeedback.lightImpact();
    context.push('/auth/login');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: KolabingColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with back button
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: _BackButton(onPressed: _handleBack),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Headline
                      _AnimatedElement(
                        opacityAnimation: _headlineAnimation,
                        slideAnimation: _headlineSlideAnimation,
                        child: Text(
                          'CHOOSE YOUR PATH',
                          style: GoogleFonts.rubik(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: KolabingColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subtitle
                      _AnimatedElement(
                        opacityAnimation: _subtitleAnimation,
                        slideAnimation: _subtitleSlideAnimation,
                        child: Text(
                          'Select your account type to get started',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: KolabingColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Business Card
                      _AnimatedElement(
                        opacityAnimation: _businessCardAnimation,
                        slideAnimation: _businessCardSlideAnimation,
                        child: SelectionCard(
                          userType: SelectionUserType.business,
                          isSelected: _selectedType == SelectionUserType.business,
                          onTap: () => _handleCardTap(SelectionUserType.business),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Community Card
                      _AnimatedElement(
                        opacityAnimation: _communityCardAnimation,
                        slideAnimation: _communityCardSlideAnimation,
                        child: SelectionCard(
                          userType: SelectionUserType.community,
                          isSelected:
                              _selectedType == SelectionUserType.community,
                          onTap: () => _handleCardTap(SelectionUserType.community),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Bottom link
                      _AnimatedElement(
                        opacityAnimation: _bottomLinkAnimation,
                        slideAnimation: _bottomLinkSlideAnimation,
                        child: _LoginLink(onTap: _navigateToLogin),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Animated wrapper for staggered entry
class _AnimatedElement extends StatelessWidget {
  const _AnimatedElement({
    required this.opacityAnimation,
    required this.slideAnimation,
    required this.child,
  });

  final Animation<double> opacityAnimation;
  final Animation<Offset> slideAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: opacityAnimation,
        builder: (context, child) => Transform.translate(
          offset: slideAnimation.value,
          child: Opacity(
            opacity: opacityAnimation.value,
            child: child,
          ),
        ),
        child: child,
      );
}

/// Back button with icon and text
class _BackButton extends StatefulWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onPressed();
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _isPressed ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: KolabingColors.textPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: KolabingColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Login link at bottom
class _LoginLink extends StatefulWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LoginLink> createState() => _LoginLinkState();
}

class _LoginLinkState extends State<_LoginLink> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 100),
          scale: _isPressed ? 0.98 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: KolabingColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Login',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: KolabingColors.textPrimary,
                      decoration: _isPressed ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
