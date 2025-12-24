# Yellow Card Submission - Final Implementation

## ✅ SOLUTION FOUND!

The NDDA Yellow Card form **requires authentication**. Users must be logged in to submit reports.

### 🔍 Root Cause Analysis

By comparing successful browser requests with our app:

1. **Authentication Required**: Browser sends TWO cookies:
   - `PHPSESSID` - Session cookie
   - `70df632a8fb0cc0c01ee88db4be8c9eb` - **User authentication token**

2. **All Array Slots Required**: Must send indices [0] through [9] for:
   - Suspected drugs
   - Side effects
   - Accompanying drugs  
   - Medical history

## 🔧 Changes Made

### 1. Switched to Dio with Cookie Management
**Changed from:**
- ❌ `package:http` - No automatic cookie management
- ❌ Manual session handling

**Changed to:**
- ✅ `package:dio` with `DioHelper`  
- ✅ Automatic cookie management
- ✅ Shares authentication with existing NDDA login

### 2. Authentication Check
Now checks for authentication cookies before submitting:
```dart
final hasAuthCookie = cookies.any((c) => 
  c.name.contains('70df632a8fb0cc0c01ee88db4be8c9eb') ||
  c.name == 'PHPSESSID'
);
```

Returns error if not authenticated:
```
Вы должны войти в систему NDDA перед отправкой формы
```

### 3. Fixed Array Format
Now sends ALL 10 slots for each array (matching browser behavior):
```dart
for (int i = 0; i < 10; i++) {
  if (i < data.suspectedDrugs.length) {
    // Send actual data
  } else {
    // Send empty string
  }
}
```

## 📋 How to Use

### Step 1: User Must Log In

**Option A: Check if Login Screen Exists**
```dart
// Navigate to NDDA login first
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NddaLoginScreen()),
);
```

**Option B: Use Existing NddaAuthService**
```dart
final authService = NddaAuthService();

// Login
final success = await authService.login(username, password);

// Check status
final isLoggedIn = await authService.isLoggedIn();
```

### Step 2: Submit Yellow Card

After logging in, submit the yellow card normally:

```dart
final response = await YellowCardService.submitYellowCard(data);

if (response.success) {
  // Success! Form submitted
} else {
  if (response.statusCode == 401) {
    // Not logged in - show login screen
  } else {
    // Other error
  }
}
```

## 🎯 Testing Steps

### 1. Test Without Login
1. Run the app (without logging in)
2. Fill out yellow card form
3. Try to submit
4. **Expected**: Error message "Вы должны войти в систему NDDA"

### 2. Test With Login  
1. Log in to NDDA (using your existing login flow)
2. Fill out yellow card form
3. Submit
4. **Expected**: HTTP 200 success response

### 3. Verify Submission
1. Log in to https://www.ndda.kz
2. Navigate to Yellow Card list
3. **Expected**: See your submitted card in the list

## 📊 Data Format Reference

### Required Fields (6 total)
1. `PDLScard[org_name]` - Organization name
2. `PDLScard[patient_name]` - Patient initials  
3. `PDLScard[patient_age]` - Patient age
4. `PDLScard[patient_sex]` - Sex (0=Female, 1=Male, 2=Unknown)
5. `PDLScard[diagnosis_primary]` - Primary diagnosis
6. `PdlsDrugs[suspect_drug][0]` - First suspected drug

### Array Format
ALL arrays must send indices [0-9]:
```
PdlsDrugs[suspect_drug][0]=Drug Name
PdlsDrugs[suspect_drug][1]=
PdlsDrugs[suspect_drug][2]=
...
PdlsDrugs[suspect_drug][9]=
```

Same for:
- `PDLSsideeffects[side_effect][0-9]`
- `PDLSaccompaying[drug][0-9]`
- `PDLShistory[name][0-9]`

### Complete Sign
Must be sent twice (checkbox pattern):
```
PDLScard[complete_sign]=0
PDLScard[complete_sign]=1
```

## 🚀 Next Steps

### Immediate
1. ✅ **Test with logged-in user**
2. ✅ **Verify submission appears in NDDA dashboard**
3. ✅ **Remove debug button (🐛) in production**

### Future Enhancements
- Add login check before showing yellow card form
- Add "Login to NDDA" button if not authenticated
- Cache form data if submission fails
- Add offline mode with queue

## 🐛 Debugging

### Check Authentication Status
```dart
final authService = NddaAuthService();
final isLoggedIn = await authService.isLoggedIn();
print('Logged in: $isLoggedIn');
```

### View Cookies
```dart
final uri = Uri.parse('https://www.ndda.kz');
final cookies = await DioHelper.instance.getCookies(uri);
for (var cookie in cookies) {
  print('${cookie.name}: ${cookie.value}');
}
```

### Common Issues

**Issue**: 500 Error  
**Cause**: Not logged in  
**Solution**: Log in first using NddaAuthService

**Issue**: 401 Error  
**Cause**: Session expired  
**Solution**: Re-authenticate

**Issue**: Missing data  
**Cause**: Required field empty  
**Solution**: Check form validation

## 📁 Files Modified

### Core Changes
- ✅ `lib/services/yellow_card_service.dart` - Switched to Dio, added auth check, fixed arrays
- ✅ `lib/services/yellow_card_debug.dart` - Debug test data generator

### Supporting Files  
- ✅ `lib/screens/yellow_card_screen.dart` - Updated to use new service
- ✅ `lib/models/meddra_model.dart` - MedDRA data model
- ✅ `lib/services/meddra_service.dart` - MedDRA API service
- ✅ `lib/widgets/meddra_selector_dialog.dart` - MedDRA selection UI

### Existing (Already Had)
- ✅ `lib/services/ndda_auth_service.dart` - NDDA authentication (already existed)
- ✅ `lib/services/dio_helper.dart` - Dio singleton with cookie jar (already existed)

## 🎉 Success Criteria

✅ User logs in to NDDA  
✅ User fills yellow card form  
✅ User submits form  
✅ App shows success message  
✅ Form appears in NDDA dashboard  
✅ HTTP 200 response received  

## 📞 Support

If submission still fails after login:
1. Check console for debug output
2. Verify cookies are present
3. Test in browser first
4. Contact NDDA support for API issues

---

**Status**: ✅ Implementation Complete  
**Tested**: ⏳ Awaiting login test  
**Ready for**: Production (after successful login test)

