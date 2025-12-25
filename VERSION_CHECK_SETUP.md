# Version Check Setup Guide

This guide explains how to set up and use the remote version checking system with Firebase Firestore.

## Features

- ✅ Automatic version check on app startup
- ✅ Remote control of update dialog text from Firestore
- ✅ Platform-specific version checking (Android & iOS)
- ✅ Optional or required updates
- ✅ Direct link to App Store/Play Store
- ✅ No version check on web platform

## Firestore Database Structure

### Collection: `versions`
### Document ID: `current`

Create a document in Firestore with the following structure:

```json
{
  "androidVersion": "1.0.3",
  "iosVersion": "1.0.3",
  "isReleased": true,
  "isRequiredAndroid": false,
  "isRequiredIos": false,
  "title": "Update Available",
  "content": "A new version of the app is available with bug fixes and improvements. Please update to continue using the app."
}
```

### Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| `androidVersion` | String | The latest Android version (e.g., "1.0.3") |
| `iosVersion` | String | The latest iOS version (e.g., "1.0.3") |
| `isReleased` | Boolean | Controls whether to show update dialog. Set to `false` to disable version check temporarily |
| `isRequiredAndroid` | Boolean | If `true`, Android users cannot dismiss the dialog |
| `isRequiredIos` | Boolean | If `true`, iOS users cannot dismiss the dialog |
| `title` | String | The title text for the update dialog |
| `content` | String | The message content for the update dialog |

## How to Set Up Firestore

### Step 1: Create the Collection

1. Go to your Firebase Console
2. Navigate to Firestore Database
3. Click "Start collection"
4. Collection ID: `versions`

### Step 2: Add the Document

1. Document ID: `current`
2. Add the fields listed above with appropriate values

### Step 3: Test the Setup

Set `isReleased` to `false` initially to avoid showing alerts during testing.

## How It Works

1. **On App Launch**: The app checks the version once after the first frame is rendered
2. **Version Comparison**: 
   - Uses semantic versioning (e.g., 1.0.3 < 1.0.4)
   - Compares current app version with Firestore version
3. **Show Dialog**: If Firestore version is higher AND `isReleased` is `true`, shows the update dialog
4. **User Action**:
   - **Update Now**: Opens the appropriate app store
   - **Later**: Dismisses the dialog (only if not required)

## Controlling Updates Remotely

### To Enable Update Notifications

```json
{
  "androidVersion": "1.0.5",
  "iosVersion": "1.0.5",
  "isReleased": true,
  ...
}
```

### To Disable Update Notifications

```json
{
  "isReleased": false,
  ...
}
```

### To Force Update (Users Cannot Skip)

```json
{
  "isRequiredAndroid": true,
  "isRequiredIos": true,
  ...
}
```

### To Customize Dialog Text

```json
{
  "title": "Critical Update Required",
  "content": "This update includes important security fixes. Please update immediately to continue using the app safely.",
  ...
}
```

## App Store Links

The default links are configured in `update_alert_dialog.dart`:

**Android (Google Play)**:
```
https://play.google.com/store/apps/details?id=kz.ndda.helper
```

**iOS (App Store)**:
```
https://apps.apple.com/app/id6738850710
```

You can customize these links by passing `androidLink` and `iosLink` parameters to the `UpdateAlertDialog.show()` method.

## Version Format

- Both Android and iOS use semantic versioning: `MAJOR.MINOR.PATCH`
- Examples: `1.0.0`, `1.0.3`, `2.1.5`
- The system parses and compares versions correctly
- Build numbers are not compared (only the version number)

## Current App Version

The current app version is defined in `pubspec.yaml`:

```yaml
version: 1.0.2+4
```

- `1.0.2` = Version number (shown to users)
- `+4` = Build number (internal, not compared)

## Testing Scenarios

### Scenario 1: Test Update Available (Optional)

1. Set Firestore `androidVersion` and `iosVersion` to `1.0.3`
2. Set `isReleased` to `true`
3. Set `isRequiredAndroid` and `isRequiredIos` to `false`
4. Launch app → Should show dialog with "Later" and "Update Now" buttons

### Scenario 2: Test Required Update

1. Set `isRequiredAndroid` and `isRequiredIos` to `true`
2. Launch app → Should show dialog with only "Update Now" button
3. Back button should not close the dialog

### Scenario 3: Test No Update (Up to Date)

1. Set Firestore versions to `1.0.0` (lower than current)
2. Launch app → No dialog should appear

### Scenario 4: Test Disabled Updates

1. Set `isReleased` to `false`
2. Launch app → No dialog should appear regardless of version

## Logs

The system logs version check information to the console:

```
Current app version: 1.0.2
Firebase Android version: 1.0.3
Current device version: 1.0.2
Update available for Android
```

Check the console/logcat for troubleshooting.

## Security Rules

Don't forget to set appropriate Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /versions/{document=**} {
      // Anyone can read versions
      allow read: if true;
      // Only admins can write (use your own authentication logic)
      allow write: if false;
    }
  }
}
```

## Files Created

The version check system consists of the following files:

1. `lib/models/version_model.dart` - Data model for version information
2. `lib/services/firebase_repository.dart` - Firestore data access
3. `lib/services/version_checker.dart` - Version comparison logic
4. `lib/widgets/update_alert_dialog.dart` - Update dialog UI
5. `lib/main.dart` - Integration point (modified)

## Troubleshooting

### Dialog Not Showing

- Check that `isReleased` is `true` in Firestore
- Verify Firestore version is higher than app version
- Check console logs for errors
- Verify Firebase is initialized correctly

### Wrong Store Link

- Update the default URLs in `update_alert_dialog.dart`
- Or pass custom links when calling `UpdateAlertDialog.show()`

### Web Platform Issues

- Version check is automatically skipped on web
- No configuration needed

## Future Enhancements

You can extend this system to:
- Add platform-specific messages
- Track version check analytics
- Support A/B testing for update messages
- Add deep links to specific app store pages
- Support staged rollouts

