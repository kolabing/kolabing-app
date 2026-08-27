import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/keyboard_avoiding_content.dart';
import '../../../widgets/kolabing_button.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';

/// Screen for organizers to create a custom challenge
class CreateChallengeScreen extends ConsumerStatefulWidget {
  const CreateChallengeScreen({
    super.key,
    required this.eventId,
    this.challenge,
  });

  final String eventId;

  /// When present the screen edits that challenge instead of creating one.
  /// `EventChallengesScreen` has pushed
  /// `/events/{id}/challenges/{challengeId}/edit` since it shipped, and that
  /// route was never registered — tapping a custom challenge as the organizer
  /// landed on the not-found page (#188).
  final Challenge? challenge;

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

  /// Whether the app opens the camera when the pair agrees.
  ChallengeProofType _proofType = ChallengeProofType.text;

  bool _isLoading = false;

  bool get _isEditing => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.challenge;
    if (existing != null) {
      _nameController.text = existing.name;
      _descriptionController.text = existing.description ?? '';
      _selectedDifficulty = existing.difficulty;
      _proofType = existing.proofType;
      _pointsController.text = existing.points.toString();
      return;
    }
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final existing = widget.challenge;
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      if (existing == null) {
        await createChallenge(
          ref,
          widget.eventId,
          name: _nameController.text.trim(),
          description: description,
          difficulty: _selectedDifficulty,
          points: int.tryParse(_pointsController.text),
          proofType: _proofType,
        );
      } else {
        await updateChallenge(
          ref,
          widget.eventId,
          existing.id,
          name: _nameController.text.trim(),
          description: description,
          difficulty: _selectedDifficulty,
          points: int.tryParse(_pointsController.text),
          proofType: _proofType,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? AppLocalizations.of(context).createChallengeUpdated
                : AppLocalizations.of(context).createChallengeSuccess,
          ),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KolabingRadius.md),
          ),
        ),
      );
      context.pop();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KolabingRadius.md),
          ),
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
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? context.colors.surface : context.colors.background;
    final textColor = isDark
        ? context.colors.textOnDark
        : context.colors.onSurface;
    final surfaceColor = isDark
        ? context.colors.darkSurface
        : context.colors.surface;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing
              ? l10n.createChallengeEditTitle
              : l10n.createChallengeTitle,
          style: KolabingTextStyles.bodyMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
      body: KeyboardAvoidingContent(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(KolabingSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                _FieldLabel(
                  label: l10n.createChallengeNameLabel,
                  required: true,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    hint: l10n.createChallengeNameHint,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.createChallengeNameRequired;
                    }
                    if (value.trim().length < 3) {
                      return l10n.createChallengeNameTooShort;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: KolabingSpacing.lg),

                // Description field
                _FieldLabel(
                  label: l10n.createChallengeDescriptionLabel,
                  required: false,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isLoading,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    hint: l10n.createChallengeDescriptionHint,
                    isDark: isDark,
                    surfaceColor: surfaceColor,
                  ),
                ),

                const SizedBox(height: KolabingSpacing.lg),

                // Difficulty selection
                _FieldLabel(
                  label: l10n.createChallengeDifficultyLabel,
                  required: true,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                _DifficultySelector(
                  selectedDifficulty: _selectedDifficulty,
                  onChanged: _onDifficultyChanged,
                  enabled: !_isLoading,
                ),

                const SizedBox(height: KolabingSpacing.lg),

                // Camera or not — the backend's proof_type (#188).
                _FieldLabel(
                  label: l10n.createChallengeProofTypeLabel,
                  required: false,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                _ProofTypeSelector(
                  selected: _proofType,
                  onChanged: (value) => setState(() => _proofType = value),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  l10n.createChallengeProofTypeHint,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: context.colors.textTertiary,
                  ),
                ),

                const SizedBox(height: KolabingSpacing.lg),

                // Points field
                _FieldLabel(
                  label: l10n.createChallengePointsLabel,
                  required: false,
                ),
                const SizedBox(height: KolabingSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pointsController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hint: l10n.createChallengePointsHint,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          prefixIcon: LucideIcons.star,
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final points = int.tryParse(value);
                            if (points == null || points < 1) {
                              return l10n.createChallengePointsInvalid;
                            }
                            if (points > 100) {
                              return l10n.createChallengePointsMax;
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
                              _pointsController.text = _selectedDifficulty
                                  .defaultPoints
                                  .toString();
                            },
                      child: Text(l10n.createChallengeResetDefault),
                    ),
                  ],
                ),

                const SizedBox(height: KolabingSpacing.xs),
                Text(
                  l10n.createChallengePointsDefaultHint,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: context.colors.textTertiary,
                  ),
                ),

                const SizedBox(height: KolabingSpacing.xxl),

                // Create button
                KolabingButton(
                  label: _isEditing
                      ? l10n.createChallengeSaveChanges
                      : l10n.createChallengeSubmit,
                  onPressed: _isLoading ? null : _handleSubmit,
                  variant: KolabingButtonVariant.primary,
                  isLoading: _isLoading,
                ),
              ],
            ),
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
      hintStyle: KolabingTextStyles.bodyMedium.copyWith(
        color: context.colors.textTertiary,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: context.colors.textTertiary)
          : null,
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? context.colors.darkBorder : context.colors.darkBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? context.colors.darkBorder : context.colors.darkBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.error),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.required});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? context.colors.textOnDark
        : context.colors.onSurface;

    return Row(
      children: [
        Text(
          label,
          style: KolabingTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        if (required)
          Text(
            ' *',
            style: KolabingTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.error,
            ),
          ),
      ],
    );
  }
}

/// Camera, or no camera — the backend's `proof_type` (#188, kolabing-v2#216).
///
/// Two options rather than a switch, because "off" is a real choice with its own
/// meaning ("the instruction is the game") and a switch labelled *Camera* leaves
/// the reader guessing what happens when it is off.
class _ProofTypeSelector extends StatelessWidget {
  const _ProofTypeSelector({
    required this.selected,
    required this.onChanged,
    required this.enabled,
  });

  final ChallengeProofType selected;
  final ValueChanged<ChallengeProofType> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _ProofTypeOption(
            icon: LucideIcons.fileText,
            label: l10n.createChallengeProofTypeText,
            isSelected: selected == ChallengeProofType.text,
            onTap: enabled ? () => onChanged(ChallengeProofType.text) : null,
          ),
        ),
        const SizedBox(width: KolabingSpacing.xs),
        Expanded(
          child: _ProofTypeOption(
            icon: LucideIcons.camera,
            label: l10n.createChallengeProofTypePhoto,
            isSelected: selected == ChallengeProofType.photo,
            onTap: enabled ? () => onChanged(ChallengeProofType.photo) : null,
          ),
        ),
      ],
    );
  }
}

class _ProofTypeOption extends StatelessWidget {
  const _ProofTypeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selectedFg = context.colors.onSurface;

    return Material(
      color: isSelected ? context.colors.primaryTint : Colors.transparent,
      borderRadius: BorderRadius.circular(KolabingRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KolabingRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KolabingSpacing.sm,
            vertical: KolabingSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KolabingRadius.md),
            border: Border.all(
              color: isSelected
                  ? context.colors.primaryDark
                  : context.colors.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selectedFg),
              const SizedBox(width: KolabingSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: KolabingTextStyles.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: selectedFg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        bgColor = isSelected ? const Color(0xFFD4EDDA) : Colors.transparent;
        borderColor = isSelected
            ? const Color(0xFF155724)
            : context.colors.darkBorder;
        textColor = isSelected
            ? const Color(0xFF155724)
            : context.colors.onSurfaceVariant;
        icon = LucideIcons.leaf;
      case ChallengeDifficulty.medium:
        bgColor = isSelected ? const Color(0xFFFFF3CD) : Colors.transparent;
        borderColor = isSelected
            ? const Color(0xFF856404)
            : context.colors.darkBorder;
        textColor = isSelected
            ? const Color(0xFF856404)
            : context.colors.onSurfaceVariant;
        icon = LucideIcons.flame;
      case ChallengeDifficulty.hard:
        bgColor = isSelected ? const Color(0xFFF8D7DA) : Colors.transparent;
        borderColor = isSelected
            ? const Color(0xFF721C24)
            : context.colors.darkBorder;
        textColor = isSelected
            ? const Color(0xFF721C24)
            : context.colors.onSurfaceVariant;
        icon = LucideIcons.zap;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(KolabingRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(KolabingRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(height: 4),
              Text(
                difficulty.label,
                style: KolabingTextStyles.captionSecondary.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              Text(
                AppLocalizations.of(
                  context,
                ).createChallengePointsValue(difficulty.defaultPoints),
                style: KolabingTextStyles.labelSmall.copyWith(
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
