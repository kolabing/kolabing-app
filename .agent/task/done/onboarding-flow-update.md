# Task: Onboarding Flow Update & Logo

## Status
- Created: 2026-01-25 16:30
- Started: 2026-01-25 16:30
- Completed: 2026-01-25

## Description

### 1. Logo Güncelleme
- Verilen Supabase logo URL'ini kullan
- URL: https://qcmperlkuujhweikoyru.supabase.co/storage/v1/object/sign/media/Logo_Kolabing-removebg-preview.png?token=...

### 2. Register Flow Değişikliği
- Google Sign In register'dan KALDIRILACAK
- User type seçildikten sonra direkt onboarding başlayacak
- Google Sign In SADECE login için kullanılacak

### 3. Onboarding Screens (API'ye göre)

#### Business Onboarding
PUT /onboarding/business endpointi için:
- Step 1: Profile Photo + Business Name (required)
- Step 2: Business Type (required) - GET /lookup/business-types
- Step 3: City (required) - GET /cities
- Step 4: About (optional) + Contact Info (phone, instagram, website)
- Final: Google Sign In ile kayıt tamamla

#### Community Onboarding
PUT /onboarding/community endpointi için:
- Step 1: Profile Photo + Display Name (required)
- Step 2: Community Type (required) - GET /lookup/community-types
- Step 3: City (required) - GET /cities
- Step 4: About (optional) + Social Links (instagram, tiktok, website)
- Final: Google Sign In ile kayıt tamamla

### Yeni Flow
```
User Type Selection
    ├── Business seçildi
    │       ↓
    │   Business Onboarding (4 step)
    │       ↓
    │   Google Sign In (with collected data)
    │       ↓
    │   PUT /onboarding/business
    │       ↓
    │   Business Dashboard
    │
    └── Community seçildi
            ↓
        Community Onboarding (4 step)
            ↓
        Google Sign In (with collected data)
            ↓
        PUT /onboarding/community
            ↓
        Community Dashboard
```

## API Endpoints
- [x] POST /auth/google - Login only
- [x] PUT /onboarding/business - Business profile
- [x] PUT /onboarding/community - Community profile
- [x] GET /lookup/business-types - Business types list
- [x] GET /lookup/community-types - Community types list
- [x] GET /cities - Cities list

## Eksik Endpoint Notu
- POST /auth/register endpoint'i YOK - Google OAuth zorunlu
- Email/password ile register YOK
- Çözüm: Onboarding verilerini topla, en sonda Google Sign In yap, ardından onboarding endpoint'i çağır

## Assigned Agents
- [x] @ui-designer - COMPLETED
- [ ] @flutter-expert

## Progress

### UX Design
**Status:** In Progress

#### Onboarding Flow Design

**IMPORTANT CHANGES:**
- Google Sign In moved to END of onboarding (not at start)
- Flow: User Type → Onboarding Steps → Google Sign In → API Call → Dashboard
- All onboarding data collected BEFORE authentication

**User Flow:**
```
Register Screen
    ↓
User Type Selection (Business / Community)
    ↓
Onboarding Step 1: Basics (Photo + Name)
    ↓
Onboarding Step 2: Type Selection
    ↓
Onboarding Step 3: City Selection
    ↓
Onboarding Step 4: Details (About + Social)
    ↓
Final Step: Review + "Complete with Google" Button
    ↓
Google Sign In
    ↓
POST /auth/google (with collected data)
    ↓
PUT /onboarding/business or /onboarding/community
    ↓
Dashboard
```

#### Detailed Wireframes & Specifications

**SCREEN 1: User Type Selection**
```
┌─────────────────────────────────────────────────┐
│ Background: #F7F8FA (Light Mode)               │
├─────────────────────────────────────────────────┤
│                                                 │
│  ← Back                                         │
│                                                 │
│          CHOOSE YOUR PATH                       │
│       (Rubik Bold, 24sp, #232323)               │
│                                                 │
│     Select how you'll use Kolabing              │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         🏢 BUSINESS                      │    │
│  │                                          │    │
│  │  I want to find communities              │    │
│  │  and post opportunities                  │    │
│  │                                          │    │
│  │  Border: 2px solid #FFD861 (if selected)│    │
│  │  Bg: #FFF6D8 (if selected)              │    │
│  │  Radius: 16dp, Padding: 24dp            │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         👥 COMMUNITY                     │    │
│  │                                          │    │
│  │  I want to find businesses               │    │
│  │  and apply for sponsorships              │    │
│  │                                          │    │
│  │  Border: 1px solid #EBEBEB (default)    │    │
│  │  Bg: #FFFFFF                             │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  │      (Yellow Button, 52dp)               │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│     Already have an account? Sign In            │
│       (Open Sans Medium, 14sp, #FFD861)         │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Component Specs:**
- Radio card height: 120dp
- Card spacing: 16dp
- Selection state: Border thickens, background changes
- Continue button: Disabled until selection made

**SCREEN 2: Onboarding Progress Header**

This header appears on all onboarding steps (Step 1-4):

```
┌─────────────────────────────────────────────────┐
│  ← Back                           Skip →        │
│                                                 │
│  Step 1 of 4                                    │
│  (Open Sans Medium, 12sp, #888888)              │
│                                                 │
│  ●━━━○━━━○━━━○                                 │
│  Progress Bar:                                   │
│  - Active: #FFD861 (filled circles)             │
│  - Inactive: #E8E8E8 (empty circles)            │
│  - Line: 2dp height                             │
│  - Circle: 12dp diameter                        │
│  - Spacing: 24dp between circles                │
│                                                 │
└─────────────────────────────────────────────────┘
```

**BUSINESS ONBOARDING**

**Step 1: Basics**
```
┌─────────────────────────────────────────────────┐
│  ← Back                 Step 1 of 4    Skip →   │
│  ●━━━○━━━○━━━○                                 │
│                                                 │
│          LET'S START WITH BASICS                │
│       (Rubik Semibold, 20sp, #232323)           │
│                                                 │
│     Tell us about your business                 │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │          PROFILE PHOTO                   │    │
│  │                                          │    │
│  │       ┌───────────────┐                  │    │
│  │       │               │                  │    │
│  │       │   [  📷  ]    │  80x80dp         │    │
│  │       │   Upload      │  Circle          │    │
│  │       │               │                  │    │
│  │       └───────────────┘                  │    │
│  │                                          │    │
│  │       Add photo (optional)               │    │
│  │       (Open Sans, 12sp, #888888)         │    │
│  │                                          │    │
│  │  Bg: #F5F6F8, Radius: 12dp              │    │
│  │  Dashed border: 2dp, #DCDCDC             │    │
│  │  Tap area: full card                     │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Business Name *                                │
│  ┌─────────────────────────────────────────┐    │
│  │  Enter your business name                │    │
│  │                                          │    │
│  │  Height: 52dp, Radius: 8dp               │    │
│  │  Bg: #F5F6F8, Border: none               │    │
│  │  Padding: 16dp horizontal                │    │
│  │  Font: Open Sans Regular, 16sp           │    │
│  │  Text: #232323, Hint: #888888            │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Character count: 0/255                         │
│  (Open Sans Regular, 12sp, #888888)             │
│                                                 │
│  [Spacer - pushes button to bottom]             │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  │      (Yellow Button, 52dp)               │    │
│  │      Disabled if name empty              │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Validation:**
- Business Name: Required, max 255 chars
- Profile Photo: Optional, max 5MB, jpg/png
- Show error state with red border if validation fails

**Step 2: Business Type**
```
┌─────────────────────────────────────────────────┐
│  ← Back                 Step 2 of 4    Skip →   │
│  ●━━━●━━━○━━━○                                 │
│                                                 │
│       WHAT TYPE OF BUSINESS?                    │
│       (Rubik Semibold, 20sp, #232323)           │
│                                                 │
│     This helps us show you to the               │
│     right communities                           │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  ┌────────┬────────┬────────┐                   │
│  │  ☕️    │  🍽️    │  🍺    │                   │
│  │  Café  │  Rest. │  Bar   │                   │
│  │        │        │        │  Grid: 3 cols     │
│  │ 96dp h │        │        │  Gap: 12dp        │
│  └────────┴────────┴────────┘                   │
│                                                 │
│  ┌────────┬────────┬────────┐                   │
│  │  🥐    │  💼    │  💪    │                   │
│  │ Bakery │Cowork  │  Gym   │                   │
│  └────────┴────────┴────────┘                   │
│                                                 │
│  ┌────────┬────────┬────────┐                   │
│  │  💇    │  🛍️    │  🏨    │                   │
│  │ Salon  │ Retail │ Hotel  │                   │
│  └────────┴────────┴────────┘                   │
│                                                 │
│  ┌─────────────────────────┐                    │
│  │     📦 Other            │                    │
│  └─────────────────────────┘                    │
│                                                 │
│  Card specs:                                    │
│  - Default: Bg #FFFFFF, Border 1px #EBEBEB      │
│  - Selected: Bg #FFF6D8, Border 2px #FFD861     │
│  - Radius: 12dp, Padding: 16dp                  │
│  - Icon: 32dp, centered                         │
│  - Label: Open Sans Semibold, 14sp              │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Step 3: City**
```
┌─────────────────────────────────────────────────┐
│  ← Back                 Step 3 of 4    Skip →   │
│  ●━━━●━━━●━━━○                                 │
│                                                 │
│         WHERE ARE YOU LOCATED?                  │
│       (Rubik Semibold, 20sp, #232323)           │
│                                                 │
│     Select your city to connect with            │
│     local communities                           │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  🔍 Search cities...                            │
│  ┌─────────────────────────────────────────┐    │
│  │  Search                              ⊗   │    │
│  │  Height: 48dp, Bg: #F5F6F8               │    │
│  │  Icon: 20dp, #888888                     │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Popular Cities:                                │
│  (Open Sans Semibold, 12sp, #888888)            │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │  📍 Barcelona                      →     │    │
│  │     Spain                                │    │
│  │                                          │    │
│  │  Height: 64dp, Border bottom 1px #EBEBEB │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │  📍 Madrid                         →     │    │
│  │     Spain                                │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │  📍 Valencia                       →     │    │
│  │     Spain                                │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  [More cities in scrollable list]               │
│                                                 │
│  List item specs:                               │
│  - Selected: Bg #FFF6D8, Border left 4px #FFD861│
│  - Icon: 24dp                                   │
│  - City: Open Sans Semibold, 16sp               │
│  - Country: Open Sans Regular, 14sp, #888888    │
│  - Arrow: 20dp, #CCCCCC                         │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Step 4: Details**
```
┌─────────────────────────────────────────────────┐
│  ← Back                 Step 4 of 4    Skip →   │
│  ●━━━●━━━●━━━●                                 │
│                                                 │
│         TELL US MORE                            │
│       (Rubik Semibold, 20sp, #232323)           │
│                                                 │
│     Share details to make your profile          │
│     stand out (all optional)                    │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  About Your Business                            │
│  ┌─────────────────────────────────────────┐    │
│  │  Describe your business...               │    │
│  │                                          │    │
│  │  [Multiline text area]                   │    │
│  │                                          │    │
│  │  Min height: 120dp                       │    │
│  │  Max height: 200dp (scrollable)          │    │
│  │  Bg: #F5F6F8, Radius: 8dp                │    │
│  │  Padding: 16dp                           │    │
│  │  Font: Open Sans Regular, 16sp           │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Character count: 0/1000                        │
│  (Right aligned, #888888, 12sp)                 │
│                                                 │
│  Phone Number                                   │
│  ┌─────────────────────────────────────────┐    │
│  │  +34 |  Enter phone number              │    │
│  │                                          │    │
│  │  Country code: Bold, 60dp width          │    │
│  │  Separator: 1px vertical line            │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Instagram                                      │
│  ┌─────────────────────────────────────────┐    │
│  │  @ username                              │    │
│  │  Prefix icon: Instagram, 20dp, #888888   │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Website                                        │
│  ┌─────────────────────────────────────────┐    │
│  │  https://                                │    │
│  │  Prefix: 🌐 icon                         │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  │      Always enabled (all optional)       │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**COMMUNITY ONBOARDING**

**Step 1: Basics**
```
┌─────────────────────────────────────────────────┐
│  ← Back                 Step 1 of 4    Skip →   │
│  ●━━━○━━━○━━━○                                 │
│                                                 │
│          TELL US ABOUT YOU                      │
│       (Rubik Semibold, 20sp, #232323)           │
│                                                 │
│     Let's create your profile                   │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │          PROFILE PHOTO                   │    │
│  │       ┌───────────────┐                  │    │
│  │       │   [  📷  ]    │  80x80dp circle  │    │
│  │       │   Upload      │                  │    │
│  │       └───────────────┘                  │    │
│  │       Add photo (optional)               │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Display Name *                                 │
│  ┌─────────────────────────────────────────┐    │
│  │  Your name or handle                     │    │
│  │  Height: 52dp, Bg: #F5F6F8               │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Character count: 0/255                         │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Step 2: Community Type**
```
┌─────────────────────────────────────────────────┐
│  ← Back                 Step 2 of 4    Skip →   │
│  ●━━━●━━━○━━━○                                 │
│                                                 │
│       WHAT DESCRIBES YOU BEST?                  │
│       (Rubik Semibold, 20sp, #232323)           │
│                                                 │
│     Help businesses find you                    │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  ┌────────┬────────┬────────┐                   │
│  │  🍔    │  ✨    │  💪    │                   │
│  │  Food  │Lifestyle│Fitness│                   │
│  │ Blogger│Influenc.│Enthus. │                   │
│  └────────┴────────┴────────┘                   │
│                                                 │
│  ┌────────┬────────┬────────┐                   │
│  │  ✈️    │  📸    │  🗺️    │                   │
│  │ Travel │Photo-  │ Local  │                   │
│  │ Blogger│grapher │Explorer│                   │
│  └────────┴────────┴────────┘                   │
│                                                 │
│  ┌────────┬────────┬────────┐                   │
│  │  🎓    │  💼    │  🎉    │                   │
│  │Student │Profess.│Community│                  │
│  │        │        │Organizer│                  │
│  └────────┴────────┴────────┘                   │
│                                                 │
│  ┌─────────────────────────┐                    │
│  │     📦 Other            │                    │
│  └─────────────────────────┘                    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Step 3: City** (Same as Business)

**Step 4: Details**
```
┌─────────────────────────────────────────────────┐
│  ← Back                 Step 4 of 4    Skip →   │
│  ●━━━●━━━●━━━●                                 │
│                                                 │
│         COMPLETE YOUR PROFILE                   │
│       (Rubik Semibold, 20sp, #232323)           │
│                                                 │
│     Add your social links (all optional)        │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  About / Bio                                    │
│  ┌─────────────────────────────────────────┐    │
│  │  Tell us about yourself...               │    │
│  │  [Multiline, 120-200dp]                  │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  0/1000 characters                              │
│                                                 │
│  Instagram                                      │
│  ┌─────────────────────────────────────────┐    │
│  │  📷 @ username                           │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  TikTok                                         │
│  ┌─────────────────────────────────────────┐    │
│  │  🎵 @ username                           │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  Website                                        │
│  ┌─────────────────────────────────────────┐    │
│  │  🌐 https://                             │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         CONTINUE                         │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
└─────────────────────────────────────────────────┘
```

**FINAL STEP: Complete with Google**

```
┌─────────────────────────────────────────────────┐
│  ← Back                                         │
│                                                 │
│          ALMOST THERE!                          │
│       (Rubik Semibold, 24sp, #232323)           │
│                                                 │
│     Review your information                     │
│       (Open Sans Regular, 14sp, #606060)        │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │         Summary Card                     │    │
│  │                                          │    │
│  │  ┌────┐  Café Barcelona                 │    │
│  │  │ 📷 │  Café • Barcelona                │    │
│  │  └────┘                                  │    │
│  │                                          │    │
│  │  "Artisan coffee shop in the heart..."  │    │
│  │                                          │    │
│  │  📱 +34 612 345 678                      │    │
│  │  📷 @cafebarcelona                       │    │
│  │  🌐 cafebarcelona.com                    │    │
│  │                                          │    │
│  │  Bg: #FFFFFF, Border: 1px #EBEBEB        │    │
│  │  Radius: 16dp, Padding: 20dp             │    │
│  │  Shadow: 0 2px 8px rgba(0,0,0,0.06)      │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │  ← Edit                                  │    │
│  │  (Text button, #FFD861)                  │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  [Spacer]                                       │
│                                                 │
│  ┌─────────────────────────────────────────┐    │
│  │  🌐  COMPLETE WITH GOOGLE                │    │
│  │                                          │    │
│  │  Height: 52dp, Radius: 12dp              │    │
│  │  Bg: #FFD861, Text: #000000              │    │
│  │  Google icon: 24dp, left aligned         │    │
│  │  Font: Darker Grotesque Semibold, 16sp   │    │
│  └─────────────────────────────────────────┘    │
│                                                 │
│  By continuing, you agree to our                │
│  Terms of Service and Privacy Policy            │
│  (Open Sans Regular, 12sp, #888888)             │
│  Links: Underlined, #FFD861                     │
│                                                 │
└─────────────────────────────────────────────────┘
```

#### Component Library

**1. Progress Indicator**
```dart
class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;  // 1-4
  final int totalSteps;   // 4

  // Visual:
  // - Height: 24dp
  // - Circle diameter: 12dp
  // - Line height: 2dp
  // - Active circle: #FFD861 (filled)
  // - Inactive circle: #E8E8E8 (filled)
  // - Active line: #FFD861
  // - Inactive line: #E8E8E8
  // - Spacing: 24dp between circles
}
```

**2. Onboarding Header**
```dart
class OnboardingHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onSkip;  // null if skip not allowed
  final int currentStep;
  final int totalSteps;

  // Layout:
  // - Back button: 40x40dp touch target
  // - Skip button: Text button, right aligned
  // - Progress: Below step text
  // - Spacing: 16dp vertical between elements
}
```

**3. Selection Card (Type/City)**
```dart
class OnboardingSelectionCard extends StatelessWidget {
  final String icon;       // emoji or image
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  // States:
  // Default:
  // - Bg: #FFFFFF
  // - Border: 1px solid #EBEBEB
  // - Shadow: 0 1px 2px rgba(0,0,0,0.04)

  // Selected:
  // - Bg: #FFF6D8
  // - Border: 2px solid #FFD861
  // - Shadow: 0 2px 8px rgba(255, 216, 97, 0.15)

  // Pressed:
  // - Scale: 0.98
  // - Duration: 100ms

  // Layout:
  // - Padding: 16dp
  // - Icon: 32dp (centered top)
  // - Label: 14sp Semibold (centered)
  // - Subtitle: 12sp Regular (if present)
}
```

**4. Photo Upload Widget**
```dart
class ProfilePhotoUpload extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  // States:
  // Empty:
  // - Dashed border: 2dp, #DCDCDC
  // - Bg: #F5F6F8
  // - Icon: 📷 32dp
  // - Label: "Add photo"

  // With Image:
  // - Solid border: 2px #FFD861
  // - Image: Circle cropped
  // - Overlay on hover: Semi-transparent with edit icon

  // Size: 80x80dp circle
  // Touch feedback: Scale 0.95
}
```

**5. Summary Card**
```dart
class OnboardingSummaryCard extends StatelessWidget {
  final ProfileData data;

  // Layout:
  // - Photo: 48x48dp circle (left)
  // - Name: Semibold 16sp
  // - Type + City: Regular 14sp, #606060
  // - Divider: 1px, #EBEBEB (8dp margin)
  // - About: Regular 14sp (max 2 lines, ellipsis)
  // - Contact info: Icons + text, 12sp

  // Styling:
  // - Bg: #FFFFFF
  // - Border: 1px #EBEBEB
  // - Radius: 16dp
  // - Padding: 20dp
  // - Shadow: Subtle card shadow
}
```

#### Validation Rules

**Business Onboarding:**

Step 1:
- name: Required, max 255 chars, trimmed
- profile_photo: Optional, max 5MB, jpg/png/webp

Step 2:
- business_type: Required, must be from API list

Step 3:
- city_id: Required, must be valid UUID from API

Step 4 (all optional):
- about: Max 1000 chars
- phone_number: Valid E.164 format (+34...)
- instagram: Alphanumeric + underscore, no @
- website: Valid URL with https://

**Community Onboarding:**

Step 1:
- name: Required, max 255 chars
- profile_photo: Optional, max 5MB

Step 2:
- community_type: Required, from API list

Step 3:
- city_id: Required, valid UUID

Step 4 (all optional):
- about: Max 1000 chars
- instagram: Alphanumeric + underscore
- tiktok: Alphanumeric + underscore
- website: Valid URL

#### State Management

```dart
class OnboardingState {
  // Store all data in local state
  Map<String, dynamic> data = {};
  int currentStep = 1;
  String userType; // 'business' or 'community'

  // Methods:
  void updateField(String key, dynamic value);
  void nextStep();
  void previousStep();
  bool canProceed(); // Check if required fields filled
  Map<String, dynamic> toApiPayload();
}
```

#### Error States

**Validation Error:**
```
┌─────────────────────────────────────────┐
│  Business Name *                        │
│  ┌─────────────────────────────────────┐│
│  │  AB                                 ││ ← Too short
│  │                                     ││
│  │  Border: 1px solid #E14D76          ││
│  │  Bg: #FFF5F7 (light red tint)       ││
│  └─────────────────────────────────────┘│
│  ⚠️ Name must be at least 3 characters  │
│  (Open Sans Medium, 12sp, #E14D76)      │
└─────────────────────────────────────────┘
```

**API Error:**
```
┌─────────────────────────────────────────┐
│  ⚠️ ERROR                               │
│                                         │
│  Something went wrong. Please try       │
│  again or contact support.              │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │         TRY AGAIN                 │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Bg: #FFF5F7, Border: 2px #E14D76       │
│  Radius: 12dp, Padding: 20dp            │
└─────────────────────────────────────────┘
```

#### Loading States

**Button Loading:**
```
┌─────────────────────────────────────────┐
│  ⟳  COMPLETING...                       │
│                                         │
│  Spinner: 20dp, #000000                 │
│  Bg: #FFD861 (same as normal)           │
│  Button: Disabled state                 │
└─────────────────────────────────────────┘
```

**Full Screen Loading (Google Sign In):**
```
┌─────────────────────────────────────────┐
│                                         │
│           ⟳                             │
│                                         │
│    Signing in with Google...            │
│                                         │
│  Overlay: Semi-transparent #000000 40%  │
│  Spinner: 48dp, #FFD861                 │
└─────────────────────────────────────────┘
```

#### Animations

**Page Transitions:**
- Type: Slide from right
- Duration: 300ms
- Curve: easeInOut

**Back Navigation:**
- Type: Slide to right
- Duration: 250ms
- Curve: easeOut

**Card Selection:**
- Scale: 0.98 on press
- Border/Background: Animate over 150ms
- Curve: easeOut

**Progress Indicator:**
- Fill animation: 200ms per step
- Curve: easeInOut

#### Accessibility

**Touch Targets:**
- All buttons: Min 48x48dp
- Selection cards: Full card touchable
- Skip button: 48x48dp touch area

**Screen Reader:**
- Progress: "Step 1 of 4, Profile setup"
- Required fields: "Business name, required field"
- Skip button: "Skip this step, optional"

**Keyboard Navigation:**
- Tab order: Logical flow
- Enter: Proceed to next step
- Escape: Go back

---

**Design Complete: 2026-01-25**
**Next: Flutter Implementation by @flutter-expert**

### Flutter Implementation
**Status:** COMPLETED

## Deliverables

### UX Design (COMPLETED)
1. ✅ User flow diagram
2. ✅ Wireframes for all screens:
   - User Type Selection
   - Business Onboarding (4 steps + final)
   - Community Onboarding (4 steps + final)
3. ✅ Component specifications:
   - Progress Indicator
   - Onboarding Header
   - Selection Card
   - Photo Upload Widget
   - Summary Card
4. ✅ Design documentation:
   - `/documentations/onboarding-ux-design.md`
   - `/documentations/onboarding-implementation-guide.md`
5. ✅ Validation rules & error states
6. ✅ Animation & transition specs
7. ✅ Accessibility guidelines

### Flutter Implementation (COMPLETED)
- [x] Create file structure
- [x] Implement Onboarding State (Riverpod 3.x Notifier)
- [x] Build reusable components
- [x] Implement User Type Selection (updated to go directly to onboarding)
- [x] Implement Business Onboarding (4 steps)
- [x] Implement Community Onboarding (4 steps)
- [x] Implement Final Review screens
- [x] Integrate Google Sign In (at end of onboarding flow)
- [x] API integration (POST /auth/google, PUT /onboarding)
- [x] Error handling & loading states
- [x] Route configuration
- [x] iOS build verified

## Notes
- ✅ Onboarding verilerini local state'te tut (Riverpod)
- ✅ En sonda Google Sign In + PUT /onboarding çağır
- ✅ Her step'te progress indicator göster (4 steps)
- ✅ Back navigation destekle (veriyi koru)
- ✅ Step 4 optional (Skip button)
- ✅ Final review'de edit butonu (Step 1'e geri dön)
- ⚠️ Photo upload max 5MB, jpg/png/webp
- ⚠️ Character counters (name: 255, about: 1000)
- ⚠️ Phone format: E.164 (+34...)
- ⚠️ Social handles WITHOUT @ prefix
