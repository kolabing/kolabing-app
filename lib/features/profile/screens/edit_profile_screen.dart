import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../config/constants/radius.dart';
import '../../../config/constants/spacing.dart';
import '../../../config/theme/colors.dart';
import '../../../config/theme/typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/models/auth_response.dart';
import '../../auth/providers/auth_provider.dart';
import '../../business/services/profile_service.dart';
import '../../identity/widgets/handle_field.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../onboarding/widgets/city_list_item.dart';

/// Edit-Profile screen.
///
/// Lets the signed-in user update their display name, city, and profile photo.
/// Name + city are saved via `PUT /me/profile` (JSON `name` / `city_id`); the
/// photo is uploaded separately as multipart (`POST /me/profile` with
/// `_method=PUT`, file field `profile_photo`) through [ProfileService]. On
/// success we refresh [authProvider] so the rest of the app reflects the change.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _imagePicker = ImagePicker();
  final ProfileService _profileService = ProfileService();

  String? _selectedCityId;
  String? _selectedCityName;
  String? _pickedPhotoPath;
  bool _saving = false;

  /// The user's existing handle (lowercased) — lets [HandleField] treat the
  /// unchanged value as "yours" without flagging it as taken.
  String? _initialHandle;
  String _handle = '';
  bool _handleOk = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController.text = user?.displayName ?? '';
    // Attendees carry city on the top-level `profiles` record (user.cityId/
    // cityName); business/community carry it on their extended profile.
    final city = user?.communityProfile?.city ?? user?.businessProfile?.city;
    _selectedCityId = city?.id ?? user?.cityId;
    _selectedCityName = city?.name ?? user?.cityName;
    _initialHandle = user?.handle?.toLowerCase();
    _handle = _initialHandle ?? '';
    if (_initialHandle != null) {
      _handleController.text = _initialHandle!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _pickedPhotoPath = picked.path);
  }

  Future<void> _openCityPicker() async {
    final result = await showModalBottomSheet<({String id, String name})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KolabingColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(KolabingRadius.xl)),
      ),
      builder: (_) => _CityPickerSheet(selectedCityId: _selectedCityId),
    );
    if (result != null) {
      setState(() {
        _selectedCityId = result.id;
        _selectedCityName = result.name;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError(l10n.editProfileNameRequired);
      return;
    }
    // Block save on a malformed/taken handle (empty handle is allowed — it
    // simply isn't sent, leaving the existing value untouched).
    if (_handle.isNotEmpty && !_handleOk) {
      _showError(l10n.handleFieldFormatError);
      return;
    }

    setState(() => _saving = true);
    try {
      // 1. Name + city + handle via JSON PUT.
      final handleChanged =
          _handle.isNotEmpty && _handle != (_initialHandle ?? '');
      await _profileService.updateProfile({
        'name': name,
        if (_selectedCityId != null) 'city_id': _selectedCityId,
        if (handleChanged) 'handle': _handle,
      });

      // 2. Photo (if changed) as multipart.
      if (_pickedPhotoPath != null) {
        await _profileService.updateProfilePhotoFile(filePath: _pickedPhotoPath!);
      }

      // Refresh the global user so the profile + everywhere else reflects it.
      await ref.read(authProvider.notifier).checkAuthStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.editProfileSaved),
          backgroundColor: KolabingColors.success,
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      _showError(e.error.message);
    } on NetworkException catch (e) {
      _showError(e.message);
    } on Exception {
      _showError(AppLocalizations.of(context).editProfileSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: KolabingColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user;
    final currentPhoto = user?.profilePhotoUrl;

    return Scaffold(
      backgroundColor: KolabingColors.background,
      appBar: AppBar(
        backgroundColor: KolabingColors.background,
        elevation: 0,
        title: Text(l10n.editProfileTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KolabingSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: KolabingSpacing.md),

              // Photo picker
              Center(
                child: GestureDetector(
                  onTap: _saving ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      _EditAvatar(
                        pickedPhotoPath: _pickedPhotoPath,
                        currentPhotoUrl: currentPhoto,
                        initial: _initialOf(_nameController.text),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(KolabingSpacing.xs),
                          decoration: const BoxDecoration(
                            color: KolabingColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            size: 16,
                            color: KolabingColors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: KolabingSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: _saving ? null : _pickPhoto,
                  child: Text(l10n.editProfileChangePhoto),
                ),
              ),

              const SizedBox(height: KolabingSpacing.lg),

              // Name field
              Text(
                l10n.editProfileNameLabel,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              TextField(
                controller: _nameController,
                enabled: !_saving,
                onChanged: (_) => setState(() {}),
                style: KolabingTextStyles.bodyMedium
                    .copyWith(color: KolabingColors.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.editProfileNameHint,
                  filled: true,
                  fillColor: KolabingColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KolabingRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                    vertical: KolabingSpacing.sm + 2,
                  ),
                ),
              ),

              const SizedBox(height: KolabingSpacing.lg),

              // Handle field (@handle with live availability)
              Text(
                l10n.editProfileHandleLabel,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              HandleField(
                controller: _handleController,
                initialHandle: _initialHandle,
                enabled: !_saving,
                onChanged: (handle, ok) {
                  _handle = handle;
                  if (ok != _handleOk && mounted) {
                    setState(() => _handleOk = ok);
                  } else {
                    _handleOk = ok;
                  }
                },
              ),

              const SizedBox(height: KolabingSpacing.lg),

              // City picker
              Text(
                l10n.editProfileCityLabel,
                style: KolabingTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: KolabingColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KolabingSpacing.xs),
              InkWell(
                onTap: _saving ? null : _openCityPicker,
                borderRadius: BorderRadius.circular(KolabingRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                    vertical: KolabingSpacing.sm + 4,
                  ),
                  decoration: BoxDecoration(
                    color: KolabingColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(KolabingRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 20,
                        color: KolabingColors.textTertiary,
                      ),
                      const SizedBox(width: KolabingSpacing.sm),
                      Expanded(
                        child: Text(
                          _selectedCityName ?? l10n.editProfileCityHint,
                          style: KolabingTextStyles.bodyMedium.copyWith(
                            color: _selectedCityName != null
                                ? KolabingColors.onSurface
                                : KolabingColors.textTertiary,
                          ),
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: KolabingColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: KolabingSpacing.xxl),

              // Save button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KolabingColors.primary,
                    foregroundColor: KolabingColors.onPrimary,
                    disabledBackgroundColor:
                        KolabingColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KolabingRadius.md),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KolabingColors.onPrimary,
                          ),
                        )
                      : Text(
                          l10n.editProfileSave,
                          style: KolabingTextStyles.button
                              .copyWith(fontSize: 16, letterSpacing: 1.0),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }
}

/// Avatar preview for the edit screen: picked file > current remote photo >
/// initial-letter circle.
class _EditAvatar extends StatelessWidget {
  const _EditAvatar({
    required this.pickedPhotoPath,
    required this.currentPhotoUrl,
    required this.initial,
  });

  final String? pickedPhotoPath;
  final String? currentPhotoUrl;
  final String initial;

  static const double _size = 104;

  @override
  Widget build(BuildContext context) {
    if (pickedPhotoPath != null) {
      return ClipOval(
        child: Image.file(
          File(pickedPhotoPath!),
          width: _size,
          height: _size,
          fit: BoxFit.cover,
        ),
      );
    }
    if (currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: currentPhotoUrl!,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _initialCircle(),
        ),
      );
    }
    return _initialCircle();
  }

  Widget _initialCircle() => Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: KolabingColors.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: KolabingColors.primary, width: 3),
        ),
        child: Center(
          child: Text(
            initial,
            style: KolabingTextStyles.bodyLarge.copyWith(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: KolabingColors.primary,
            ),
          ),
        ),
      );
}

/// City selection bottom-sheet — reuses the onboarding [citiesProvider] +
/// [CityListItem] pattern.
class _CityPickerSheet extends ConsumerStatefulWidget {
  const _CityPickerSheet({this.selectedCityId});

  final String? selectedCityId;

  @override
  ConsumerState<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends ConsumerState<_CityPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = ref.watch(filteredCitiesProvider(_query));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: KolabingSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KolabingColors.outlineVariant,
                borderRadius: BorderRadius.circular(KolabingRadius.round),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(KolabingSpacing.md),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                style: KolabingTextStyles.bodyMedium
                    .copyWith(color: KolabingColors.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.editProfileCitySearchHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  filled: true,
                  fillColor: KolabingColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(KolabingRadius.sm),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KolabingSpacing.md,
                    vertical: KolabingSpacing.sm,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.when(
                data: (cities) {
                  if (cities.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.editProfileNoCitiesFound,
                        style: KolabingTextStyles.bodySmall
                            .copyWith(color: KolabingColors.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: cities.length,
                    itemBuilder: (_, i) {
                      final city = cities[i];
                      return CityListItem(
                        id: city.id,
                        name: city.name,
                        country: city.country,
                        isSelected: widget.selectedCityId == city.id,
                        onTap: () => Navigator.of(context)
                            .pop((id: city.id, name: city.name)),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: KolabingColors.primary,
                  ),
                ),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: KolabingColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: KolabingSpacing.sm),
                      Text(
                        l10n.editProfileCityLoadError,
                        style: KolabingTextStyles.bodySmall
                            .copyWith(color: KolabingColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: KolabingSpacing.md),
                      TextButton(
                        onPressed: () => ref.invalidate(citiesProvider),
                        child: Text(l10n.commonRetry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
