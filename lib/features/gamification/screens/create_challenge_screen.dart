import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';

/// Screen for organizers to create a custom challenge
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  ConsumerState<CreateChallengeScreen> createState() =>
      _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  ChallengeDifficulty _selectedDifficulty = ChallengeDifficulty.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default points based on difficulty
    _pointsController.text = _selectedDifficulty.defaultPoints.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _onDifficultyChanged(ChallengeDifficulty? difficulty) {
    if (difficulty == null) return;
    setState(() {
      _selectedDifficulty = difficulty;
      // Update default points when difficulty changes
      _pointsController.text = difficulty.defaultPoints.toString();
    });
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await createChallenge(
        ref,
        widget.eventId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        difficulty: _selectedDifficulty,
        points: int.tryParse(_pointsController.text),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Challenge created successfully!'),
          backgroundColor: KolabingColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: KolabingColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? KolabingColors.darkBackground : KolabingColors.background;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;
    final surfaceColor =
        isDark ? KolabingColors.darkSurface : KolabingColors.surface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.x,
            color: textColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Challenge',
          style: GoogleFonts.rubik(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(KolabingSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              _FieldLabel(label: 'Challenge Name', required: true),
              const SizedBox(height: KolabingSpacing.xs),
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hint: 'Enter challenge name',
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a challenge name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: KolabingSpacing.lg),

              // Description field
              _FieldLabel(label: 'Description', required: false),
              const SizedBox(height: KolabingSpacing.xs),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isLoading,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hint: 'Describe what attendees need to do',
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                ),
              ),

              const SizedBox(height: KolabingSpacing.lg),

              // Difficulty selection
              _FieldLabel(label: 'Difficulty', required: true),
              const SizedBox(height: KolabingSpacing.xs),
              _DifficultySelector(
                selectedDifficulty: _selectedDifficulty,
                onChanged: _onDifficultyChanged,
                enabled: !_isLoading,
              ),

              const SizedBox(height: KolabingSpacing.lg),

              // Points field
              _FieldLabel(label: 'Points', required: false),
              const SizedBox(height: KolabingSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pointsController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        hint: 'Points awarded',
                        isDark: isDark,
                        surfaceColor: surfaceColor,
                        prefixIcon: LucideIcons.star,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final points = int.tryParse(value);
                          if (points == null || points < 1) {
                            return 'Enter a valid number';
                          }
                          if (points > 100) {
                            return 'Maximum 100 points';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: KolabingSpacing.sm),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _pointsController.text =
                                _selectedDifficulty.defaultPoints.toString();
                          },
                    child: const Text('Reset to default'),
                  ),
                ],
              ),

              const SizedBox(height: KolabingSpacing.xs),
              Text(
                'Default: Easy=5, Medium=15, Hard=30 points',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: KolabingColors.textTertiary,
                ),
              ),

              const SizedBox(height: KolabingSpacing.xxl),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              KolabingColors.onPrimary,
                            ),
                          ),
                        )
                      : Text(
                          'CREATE CHALLENGE',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDark,
    required Color surfaceColor,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.openSans(
        color: KolabingColors.textTertiary,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: KolabingColors.textTertiary)
          : null,
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? KolabingColors.darkBorder : KolabingColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: KolabingColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: KolabingColors.error,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.required,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? KolabingColors.textOnDark : KolabingColors.textPrimary;

    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KolabingColors.error,
            ),
          ),
      ],
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({
    required this.selectedDifficulty,
    required this.onChanged,
    required this.enabled,
  });

  final ChallengeDifficulty selectedDifficulty;
  final ValueChanged<ChallengeDifficulty?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ChallengeDifficulty.values.map((difficulty) {
        final isSelected = difficulty == selectedDifficulty;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: difficulty != ChallengeDifficulty.hard
                  ? KolabingSpacing.xs
                  : 0,
            ),
            child: _DifficultyOption(
              difficulty: difficulty,
              isSelected: isSelected,
              onTap: enabled ? () => onChanged(difficulty) : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final ChallengeDifficulty difficulty;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final IconData icon;

    switch (difficulty) {
      case ChallengeDifficulty.easy:
        bgColor = isSelected
            ? const Color(0xFFD4EDDA)
            : Colors.transparent;
        borderColor = isSelected
            ? const Color(0xFF155724)
            : KolabingColors.border;
        textColor = isSelected
            ? const Color(0xFF155724)
            : KolabingColors.textSecondary;
        icon = LucideIcons.leaf;
      case ChallengeDifficulty.medium:
        bgColor = isSelected
            ? const Color(0xFFFFF3CD)
            : Colors.transparent;
        borderColor = isSelected
            ? const Color(0xFF856404)
            : KolabingColors.border;
        textColor = isSelected
            ? const Color(0xFF856404)
            : KolabingColors.textSecondary;
        icon = LucideIcons.flame;
      case ChallengeDifficulty.hard:
        bgColor = isSelected
            ? const Color(0xFFF8D7DA)
            : Colors.transparent;
        borderColor = isSelected
            ? const Color(0xFF721C24)
            : KolabingColors.border;
        textColor = isSelected
            ? const Color(0xFF721C24)
            : KolabingColors.textSecondary;
        icon = LucideIcons.zap;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(height: 4),
              Text(
                difficulty.label,
                style: GoogleFonts.openSans(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                '${difficulty.defaultPoints} pts',
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
