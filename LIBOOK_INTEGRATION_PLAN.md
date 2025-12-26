# Libook/UpToDate Integration Plan

## Overview
Integrate Libook/UpToDate API authentication and drug information lookup into the nddahelper Flutter application.

## Authentication Flow Analysis

### Current Flow (from HTTP traces):
1. **Initial OAuth Request**: `GET /api/auth/signin/libook`
   - Redirects to: `https://dispatcher.libook.xyz/revo/authorize`
   - Uses PKCE (Proof Key for Code Exchange) for security
   - Parameters:
     - `client_id`: YYrrB62w9z5OmQ1sP6vBfqyKFP7IA2yjN8Jqt0ae
     - `scope`: read write groups
     - `response_type`: code
     - `redirect_uri`: https://utd.libook.xyz/api/auth/callback/libook
     - `code_challenge`: PKCE challenge
     - `code_challenge_method`: S256

2. **Login Page**: Shows login form at `https://dispatcher.libook.xyz/login`

3. **Login POST**: Submits credentials
   - `username`: email
   - `password`: password
   - `csrfmiddlewaretoken`: CSRF token
   - Returns session cookies

4. **Session Token**: `GET /api/auth/session`
   - Returns user data including:
     - name, email, sub (user ID)
     - groups (database access, expiry dates)
     - JWT token in secure cookie

## Architecture Plan

### Phase 1: Authentication Module
**Goal**: Implement OAuth2 + PKCE authentication flow

**Components**:
1. **LibookAuthService** (`lib/services/libook_auth_service.dart`)
   - Manage OAuth2 flow with PKCE
   - Handle token storage securely
   - Refresh token management
   - Session validation

2. **LibookApiClient** (`lib/services/libook_api_client.dart`)
   - HTTP client with authentication headers
   - Token refresh interceptor
   - Error handling

3. **Storage Layer**
   - Use `flutter_secure_storage` (already in dependencies)
   - Store: access_token, refresh_token, expiry, user_profile

### Phase 2: UI Integration
**Goal**: Add UpToDate drug lookup feature

**Components**:
1. **Settings/Account Screen**
   - Login/Logout button
   - Display user info (name, email, subscription status)
   - Show expiry date: 2026-03-25
   - Access level: Advanced

2. **Drug Card Enhancement**
   - Add "UpToDate" badge/button
   - Quick lookup from drug card
   - Show UpToDate availability indicator

3. **UpToDate Search Screen**
   - Search UpToDate database
   - Display drug monographs
   - Interaction checker
   - Clinical guidelines

### Phase 3: API Integration
**Goal**: Connect to UpToDate/Libook APIs

**Endpoints to Implement**:
1. **Authentication**
   - `POST /api/auth/signin/libook` - Initiate OAuth
   - `GET /api/auth/session` - Get session info
   - `POST /api/auth/signout` - Logout

2. **Drug Information** (to be discovered)
   - Drug monograph lookup
   - Drug interactions
   - Clinical guidelines
   - Dosing information

### Phase 4: Data Synchronization
**Goal**: Cache and sync UpToDate data

**Features**:
- Offline access to recently viewed monographs
- Background sync when connected
- Smart caching strategy

## Security Considerations

1. **Token Storage**
   - Use flutter_secure_storage for tokens
   - Never log tokens
   - Clear on logout

2. **PKCE Implementation**
   - Generate secure code_verifier
   - Calculate code_challenge using SHA256
   - Validate state parameter

3. **HTTPS Only**
   - All requests over HTTPS
   - Certificate pinning (optional)

4. **Session Management**
   - Auto-refresh before expiry
   - Handle 401 responses gracefully
   - Clear session on logout

## User Experience Flow

### Happy Path:
1. User opens app → sees "Login to UpToDate" option
2. User taps login → opens secure web view with Libook OAuth
3. User enters credentials → redirects back to app
4. App exchanges code for token → stores securely
5. User sees their profile: "Zhandaulet Zhaxylykuly" with expiry date
6. User searches drug → sees UpToDate badge
7. User taps badge → views comprehensive drug info from UpToDate

### Error Handling:
- Network errors: Show retry option
- Invalid credentials: Clear error message
- Expired subscription: Show renewal prompt
- Token expired: Auto-refresh or re-login

## Dependencies Required

Already in pubspec.yaml:
- ✅ flutter_secure_storage
- ✅ http

Need to add:
- oauth2
- url_launcher (for OAuth flow)
- webview_flutter (for OAuth login page)
- crypto (for PKCE)

## Implementation Priority

### Must Have (MVP):
1. OAuth authentication flow
2. Secure token storage
3. Session management
4. Basic user profile display
5. Logout functionality

### Should Have:
1. Drug lookup integration
2. UpToDate badge on drug cards
3. Cached monographs
4. Subscription expiry warnings

### Nice to Have:
1. Drug interaction checker
2. Clinical guidelines browser
3. Offline monograph access
4. Push notifications for updates

## Timeline Estimate

- **Phase 1** (Authentication): 2-3 days
- **Phase 2** (UI Integration): 1-2 days
- **Phase 3** (API Integration): 3-4 days (depends on API documentation)
- **Phase 4** (Data Sync): 2-3 days
- **Testing & Polish**: 2 days

**Total**: ~10-14 days for full integration

## Success Metrics

1. **Authentication**: 95%+ success rate on login
2. **Performance**: < 2s to authenticate
3. **Reliability**: < 1% token refresh failures
4. **UX**: 4.5+ star rating for UpToDate feature
5. **Adoption**: 30%+ of users link UpToDate account

## Next Steps

1. Review and approve this plan
2. Obtain official Libook/UpToDate API documentation
3. Register app for OAuth client credentials (if different from web)
4. Begin Phase 1 implementation
5. Set up test environment with test accounts

