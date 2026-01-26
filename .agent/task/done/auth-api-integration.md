# Task: Authentication API Integration

## Status
- Created: 2026-01-25 23:15
- Started: 2026-01-25 23:15
- Completed: 2026-01-25

## Description
Update authentication flow to use new API endpoints for registration and login.

## API Endpoints

### Registration
- `POST /api/v1/auth/register/business` - Business user registration
- `POST /api/v1/auth/register/community` - Community user registration

### Login
- `POST /api/v1/auth/login` - Email/password login
- `POST /api/v1/auth/google` - Google login (existing users only)

### User
- `GET /api/v1/auth/me` - Get current user
- `POST /api/v1/auth/logout` - Logout

## Changes Required

### 1. AuthService Updates
- [x] Update `registerWithEmail` to use separate endpoints per user type
- [x] Add `registerBusiness()` method
- [x] Add `registerCommunity()` method
- [x] Update `login()` method for email/password
- [x] Keep `authenticateWithGoogle()` for existing users only

### 2. Onboarding Provider Updates
- [x] Update `completeWithEmail()` to call correct registration endpoint
- [x] Pass all onboarding data in registration request

### 3. Login Screen Updates
- [x] Add email/password login form
- [x] Add Google login option for existing users
- [x] Handle error messages (invalid credentials, Google-only user)

### 4. Response Model Updates
- [x] Update AuthResponse to handle new response format
- [x] Handle business_profile and community_profile in user model

## Assigned Agents
- [x] @flutter-expert - Implementation

## Progress

### API Service Implementation
**Status:** Completed
- Added `registerBusiness()` method with full onboarding data
- Added `registerCommunity()` method with full onboarding data
- Added `loginWithEmail()` method
- Added `loginWithGoogle()` method (existing users only)

### Onboarding Provider
**Status:** Completed
- Updated `completeWithEmail()` to use new single-step registration API
- Removed unused `completeWithGoogle()` method

### Login Screen
**Status:** Completed
- Added email/password login form
- Added Google login option (for existing users)
- Added "User Not Found" dialog for Google login failures

### Cleanup
**Status:** Completed
- Removed unused `register_screen.dart` (Google signup no longer supported)
- Removed unused `sign_up_screen.dart` (Google signup no longer supported)
- Routes already redirect `/auth/sign-up` to user type selection

## Notes
- Registration combines onboarding + account creation in single API call
- Google login is for existing users only
- New users must use email/password registration
