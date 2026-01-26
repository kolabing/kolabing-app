# Onboarding Flow - Implementation Guide

**For:** @flutter-expert
**Design by:** @ux-designer
**Date:** 2026-01-25

---

## Quick Start

This guide helps you implement the new onboarding flow where Google Sign In happens AFTER data collection.

### File Structure

```
lib/features/onboarding/
├── screens/
│   ├── user_type_selection_screen.dart
│   ├── business_onboarding/
│   │   ├── business_step1_basics.dart
│   │   ├── business_step2_type.dart
│   │   ├── business_step3_city.dart
│   │   ├── business_step4_details.dart
│   │   └── business_final_review.dart
│   └── community_onboarding/
│       ├── community_step1_basics.dart
│       ├── community_step2_type.dart
│       ├── community_step3_city.dart
│       ├── community_step4_details.dart
│       └── community_final_review.dart
├── widgets/
│   ├── onboarding_header.dart
│   ├── progress_indicator.dart
│   ├── selection_card.dart
│   ├── photo_upload_widget.dart
│   └── summary_card.dart
├── models/
│   └── onboarding_data.dart
└── providers/
    └── onboarding_provider.dart
```

---

## Implementation Steps

### Step 1: Create Onboarding State

```dart
// lib/features/onboarding/models/onboarding_data.dart

class OnboardingData {
  String? userType; // 'business' or 'community'
  String? name;
  String? profilePhoto; // base64 or URL
  String? type; // business_type or community_type
  String? cityId;
  String? about;
  String? phoneNumber;
  String? instagram;
  String? tiktok; // community only
  String? website;

  int currentStep = 1;

  Map<String, dynamic> toBusinessPayload() {
    return {
      'name': name,
      'profile_photo': profilePhoto,
      'business_type': type,
      'city_id': cityId,
      'about': about,
      'phone_number': phoneNumber,
      'instagram': instagram,
      'website': website,
    }..removeWhere((key, value) => value == null);
  }

  Map<String, dynamic> toCommunityPayload() {
    return {
      'name': name,
      'profile_photo': profilePhoto,
      'community_type': type,
      'city_id': cityId,
      'about': about,
      'instagram': instagram,
      'tiktok': tiktok,
      'website': website,
    }..removeWhere((key, value) => value == null);
  }

  bool canProceedFromStep(int step) {
    switch (step) {
      case 1:
        return name != null && name!.trim().isNotEmpty;
      case 2:
        return type != null;
      case 3:
        return cityId != null;
      case 4:
        return true; // All fields optional
      default:
        return false;
    }
  }
}
```

---

### Step 2: Create Onboarding Provider

```dart
// lib/features/onboarding/providers/onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(OnboardingData());

  void setUserType(String type) {
    state = state..userType = type;
  }

  void updateField(String key, dynamic value) {
    switch (key) {
      case 'name':
        state = state..name = value;
        break;
      case 'profilePhoto':
        state = state..profilePhoto = value;
        break;
      case 'type':
        state = state..type = value;
        break;
      case 'cityId':
        state = state..cityId = value;
        break;
      case 'about':
        state = state..about = value;
        break;
      case 'phoneNumber':
        state = state..phoneNumber = value;
        break;
      case 'instagram':
        state = state..instagram = value;
        break;
      case 'tiktok':
        state = state..tiktok = value;
        break;
      case 'website':
        state = state..website = value;
        break;
    }
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state..currentStep++;
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state..currentStep--;
    }
  }

  void reset() {
    state = OnboardingData();
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingData>(
  (ref) => OnboardingNotifier(),
);
```

---

### Step 3: User Type Selection Screen

```dart
// lib/features/onboarding/screens/user_type_selection_screen.dart

class UserTypeSelectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Padding(
          padding: KolabingLayout.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                icon: Icon(LucideIcons.chevronLeft),
                onPressed: () => Navigator.pop(context),
              ),

              SizedBox(height: 24),

              // Title
              Text(
                'CHOOSE YOUR PATH',
                style: KolabingTextStyles.displaySmall.copyWith(
                  color: KolabingColors.textPrimary,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Select how you'll use Kolabing',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
              ),

              SizedBox(height: 32),

              // Business card
              UserTypeCard(
                icon: '🏢',
                title: 'BUSINESS',
                description: 'I want to find communities\nand post opportunities',
                isSelected: onboarding.userType == 'business',
                onTap: () {
                  ref.read(onboardingProvider.notifier).setUserType('business');
                },
              ),

              SizedBox(height: 16),

              // Community card
              UserTypeCard(
                icon: '👥',
                title: 'COMMUNITY',
                description: 'I want to find businesses\nand apply for sponsorships',
                isSelected: onboarding.userType == 'community',
                onTap: () {
                  ref.read(onboardingProvider.notifier).setUserType('community');
                },
              ),

              Spacer(),

              // Continue button
              KolabingPrimaryButton(
                text: 'CONTINUE',
                onPressed: onboarding.userType != null
                    ? () {
                        // Navigate to step 1
                        if (onboarding.userType == 'business') {
                          Navigator.pushNamed(context, '/onboarding/business/step1');
                        } else {
                          Navigator.pushNamed(context, '/onboarding/community/step1');
                        }
                      }
                    : null,
                isFullWidth: true,
              ),

              SizedBox(height: 16),

              // Sign in link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/auth/sign-in'),
                  child: Text(
                    'Already have an account? Sign In',
                    style: KolabingTextStyles.bodyMedium.copyWith(
                      color: KolabingColors.primary,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Step 4: Reusable Components

#### Progress Indicator

```dart
// lib/features/onboarding/widgets/progress_indicator.dart

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isEven) {
          // Circle
          final step = index ~/ 2 + 1;
          return Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step <= currentStep
                  ? KolabingColors.primary
                  : KolabingColors.borderFocus,
            ),
          );
        } else {
          // Line
          final step = index ~/ 2 + 1;
          return Container(
            width: 24,
            height: 2,
            color: step < currentStep
                ? KolabingColors.primary
                : KolabingColors.borderFocus,
          );
        }
      }),
    );
  }
}
```

#### Onboarding Header

```dart
// lib/features/onboarding/widgets/onboarding_header.dart

class OnboardingHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onSkip;
  final int currentStep;
  final int totalSteps;

  const OnboardingHeader({
    required this.onBack,
    this.onSkip,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(LucideIcons.chevronLeft),
              onPressed: onBack,
            ),
            if (onSkip != null)
              TextButton(
                onPressed: onSkip,
                child: Text(
                  'Skip',
                  style: KolabingTextStyles.labelMedium.copyWith(
                    color: KolabingColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Step $currentStep of $totalSteps',
            style: KolabingTextStyles.bodySmall.copyWith(
              color: KolabingColors.textTertiary,
            ),
          ),
        ),
        SizedBox(height: 8),
        OnboardingProgressIndicator(
          currentStep: currentStep,
          totalSteps: totalSteps,
        ),
      ],
    );
  }
}
```

#### Selection Card

```dart
// lib/features/onboarding/widgets/selection_card.dart

class SelectionCard extends StatelessWidget {
  final String icon;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectionCard({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? KolabingColors.softYellow : Colors.white,
          border: Border.all(
            color: isSelected ? KolabingColors.primary : KolabingColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(KolabingRadius.md),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: KolabingColors.primary.withOpacity(0.15),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 32),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: KolabingTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle!,
                style: KolabingTextStyles.bodySmall.copyWith(
                  color: KolabingColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

#### Photo Upload Widget

```dart
// lib/features/onboarding/widgets/photo_upload_widget.dart

class PhotoUploadWidget extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const PhotoUploadWidget({
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KolabingColors.surfaceVariant,
          border: Border.all(
            color: imageUrl != null
                ? KolabingColors.primary
                : Colors.transparent,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.camera,
                    size: 32,
                    color: KolabingColors.textTertiary,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upload',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
```

---

### Step 5: Example Step Screen (Business Step 1)

```dart
// lib/features/onboarding/screens/business_onboarding/business_step1_basics.dart

class BusinessStep1BasicsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BusinessStep1BasicsScreen> createState() => _BusinessStep1BasicsScreenState();
}

class _BusinessStep1BasicsScreenState extends ConsumerState<BusinessStep1BasicsScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _nameController.text = data.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Padding(
          padding: KolabingLayout.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OnboardingHeader(
                  onBack: () => Navigator.pop(context),
                  currentStep: 1,
                  totalSteps: 4,
                ),

                SizedBox(height: 24),

                Text(
                  'LET\'S START WITH BASICS',
                  style: KolabingTextStyles.headlineMedium.copyWith(
                    color: KolabingColors.textPrimary,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Tell us about your business',
                  style: KolabingTextStyles.bodyMedium.copyWith(
                    color: KolabingColors.textSecondary,
                  ),
                ),

                SizedBox(height: 32),

                // Photo upload
                Center(
                  child: PhotoUploadWidget(
                    imageUrl: onboarding.profilePhoto,
                    onTap: () async {
                      // TODO: Implement image picker
                      // final image = await ImagePicker().pickImage();
                      // ref.read(onboardingProvider.notifier).updateField('profilePhoto', base64Image);
                    },
                  ),
                ),

                SizedBox(height: 8),

                Center(
                  child: Text(
                    'Add photo (optional)',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                    ),
                  ),
                ),

                SizedBox(height: 32),

                // Business name
                Text(
                  'Business Name *',
                  style: KolabingTextStyles.labelMedium,
                ),

                SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your business name',
                    filled: true,
                    fillColor: KolabingColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KolabingRadius.sm),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: KolabingTextStyles.bodyLarge,
                  maxLength: 255,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Business name is required';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    ref.read(onboardingProvider.notifier).updateField('name', value);
                  },
                ),

                Spacer(),

                KolabingPrimaryButton(
                  text: 'CONTINUE',
                  onPressed: onboarding.canProceedFromStep(1)
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            ref.read(onboardingProvider.notifier).nextStep();
                            Navigator.pushNamed(context, '/onboarding/business/step2');
                          }
                        }
                      : null,
                  isFullWidth: true,
                ),

                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### Step 6: Final Review & Google Sign In

```dart
// lib/features/onboarding/screens/business_onboarding/business_final_review.dart

class BusinessFinalReviewScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: KolabingColors.background,
      body: SafeArea(
        child: Padding(
          padding: KolabingLayout.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(LucideIcons.chevronLeft),
                onPressed: () => Navigator.pop(context),
              ),

              SizedBox(height: 24),

              Text(
                'ALMOST THERE!',
                style: KolabingTextStyles.displaySmall,
              ),

              SizedBox(height: 8),

              Text(
                'Review your information',
                style: KolabingTextStyles.bodyMedium.copyWith(
                  color: KolabingColors.textSecondary,
                ),
              ),

              SizedBox(height: 32),

              // Summary card
              OnboardingSummaryCard(data: onboarding),

              SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  // Go back to step 1
                  ref.read(onboardingProvider.notifier).currentStep = 1;
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.chevronLeft, size: 16),
                    SizedBox(width: 4),
                    Text('Edit'),
                  ],
                ),
              ),

              Spacer(),

              KolabingPrimaryButton(
                text: '🌐  COMPLETE WITH GOOGLE',
                onPressed: () async {
                  // TODO: Implement Google Sign In
                  // 1. Sign in with Google
                  // 2. Get ID token
                  // 3. POST /auth/google {id_token, user_type}
                  // 4. Store auth token
                  // 5. PUT /onboarding/business with collected data
                  // 6. Navigate to dashboard
                },
                isFullWidth: true,
              ),

              SizedBox(height: 16),

              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: KolabingTextStyles.bodySmall.copyWith(
                      color: KolabingColors.textTertiary,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: KolabingColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: KolabingColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## API Integration

### Complete Flow

```dart
Future<void> completeOnboarding() async {
  try {
    // 1. Google Sign In
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    // 2. POST /auth/google
    final authResponse = await apiClient.post('/auth/google', body: {
      'id_token': idToken,
      'user_type': onboardingData.userType,
    });

    // 3. Store token
    await secureStorage.write(key: 'auth_token', value: authResponse['token']);

    // 4. PUT /onboarding/business or /onboarding/community
    final payload = onboardingData.userType == 'business'
        ? onboardingData.toBusinessPayload()
        : onboardingData.toCommunityPayload();

    await apiClient.put(
      '/onboarding/${onboardingData.userType}',
      body: payload,
      headers: {'Authorization': 'Bearer ${authResponse['token']}'},
    );

    // 5. Navigate to dashboard
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/business/dashboard', // or /community/dashboard
      (route) => false,
    );
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## Testing Checklist

- [ ] User type selection works
- [ ] Navigation between steps works
- [ ] Back button preserves data
- [ ] Form validation shows errors
- [ ] Photo upload works (5MB limit)
- [ ] City search filters correctly
- [ ] Character counters update
- [ ] Skip button on step 4 works
- [ ] Final review shows all data
- [ ] Edit button goes back to step 1
- [ ] Google Sign In triggers correctly
- [ ] API calls succeed
- [ ] Token stored securely
- [ ] Navigation to dashboard works
- [ ] Error handling shows messages
- [ ] Loading states display correctly

---

## Design Assets Needed

1. Emojis for business types (☕️🍽️🍺🥐💼💪💇🛍️🏨📦)
2. Emojis for community types (🍔✨💪✈️📸🗺️🎓💼🎉📦)
3. Google icon for button
4. Loading spinner animation

---

## Routes to Add

```dart
'/onboarding/user-type': (context) => UserTypeSelectionScreen(),

// Business
'/onboarding/business/step1': (context) => BusinessStep1BasicsScreen(),
'/onboarding/business/step2': (context) => BusinessStep2TypeScreen(),
'/onboarding/business/step3': (context) => BusinessStep3CityScreen(),
'/onboarding/business/step4': (context) => BusinessStep4DetailsScreen(),
'/onboarding/business/final': (context) => BusinessFinalReviewScreen(),

// Community
'/onboarding/community/step1': (context) => CommunityStep1BasicsScreen(),
'/onboarding/community/step2': (context) => CommunityStep2TypeScreen(),
'/onboarding/community/step3': (context) => CommunityStep3CityScreen(),
'/onboarding/community/step4': (context) => CommunityStep4DetailsScreen(),
'/onboarding/community/final': (context) => CommunityFinalReviewScreen(),
```

---

## Questions? Issues?

Contact @ux-designer for design clarifications or @product-team for business logic questions.

---

**Ready to Implement:** Yes ✓
**Estimated Time:** 16-20 hours
**Priority:** High
