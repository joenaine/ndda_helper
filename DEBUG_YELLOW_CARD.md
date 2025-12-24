# Yellow Card - Debugging Guide

## How to Debug the 500 Error

### Step 1: Use the Debug Test Button

A debug button (🐛) has been added to the Yellow Card screen's app bar.

**To test:**
1. Open the Yellow Card screen
2. Click the bug icon (🐛) in the top right
3. Choose either:
   - **"Minimal (Required Only)"** - Tests with only the 6 required fields
   - **"Complete Data"** - Tests with all fields populated

### Step 2: Check the Console Output

When you submit (either real form or test), the console will show:

```
=== YELLOW CARD SUBMISSION DEBUG ===
URL: https://www.ndda.kz/register.php/sideeffects/new/lang/ru
Data length: XXXX
Form data preview (first 500 chars): ...
Response status: XXX
Response body (first 1000 chars): ...
=== END DEBUG ===
```

### Step 3: Review the Error Dialog

The error dialog will now show:
- Error message
- HTTP status code
- First 500 characters of server response
- Button to show full log in console

### Common Issues and Fixes

#### 1. **500 Internal Server Error**

**Possible Causes:**
- Missing required parameters
- Incorrect parameter format
- Invalid date format (should be dd.MM.yyyy)
- Invalid enum values

**Check:**
```
Required Parameters:
- PDLScard[org_name] ✓
- PDLScard[patient_name] ✓
- PDLScard[patient_age] ✓
- PDLScard[patient_sex] ✓ (0=Female, 1=Male, 2=Unknown)
- PDLScard[diagnosis_primary] ✓
- PdlsDrugs[suspect_drug][0] ✓
```

#### 2. **Date Format Issues**

Dates must be in format: **dd.MM.yyyy** (e.g., "25.12.2025")

**Wrong:** 2025-12-25, 12/25/2025
**Correct:** 25.12.2025

#### 3. **Sex Value Mapping**

Server expects numeric values:
- `0` = Female (Женский)
- `1` = Male (Мужской)
- `2` = Unknown (Неизвестно)

#### 4. **Boolean Values**

Server expects string "0" or "1":
- `"0"` = No/False
- `"1"` = Yes/True

#### 5. **Array Indices**

All arrays must send indices [0] through [9], even if empty:
```
PdlsDrugs[suspect_drug][0]=value
PdlsDrugs[suspect_drug][1]=
PdlsDrugs[suspect_drug][2]=
...
PdlsDrugs[suspect_drug][9]=
```

### Step 4: Compare with Browser Request

To see what a working request looks like:

1. Open the [NDDA website](https://www.ndda.kz/register.php/sideeffects/new/lang/ru) in a browser
2. Open Developer Tools (F12)
3. Go to Network tab
4. Fill out and submit the form
5. Find the POST request to `/sideeffects/new/lang/ru`
6. Click "Payload" or "Request" to see the data format

Compare this with our app's console output.

### Step 5: Test Incrementally

Use the debug test button to test with minimal data first:

1. **Test 1:** Minimal data (6 required fields only)
   - If this works → Required fields are correct
   - If this fails → Check required field formats

2. **Test 2:** Add optional sections one by one
   - Add pregnancy info
   - Add side effects
   - Add accompanying drugs
   - Add medical history

This helps identify which section is causing the problem.

### Debug Output Explanation

**Console Output:**
```
=== YELLOW CARD DATA DEBUG ===
Required Fields:
  org_name: Test Organization          ← Must not be empty
  patient_name: T.T.T                  ← Must not be empty
  patient_age: 30                      ← Must be a number
  patient_sex: 1                       ← Must be 0, 1, or 2
  diagnosis_primary: Test Diagnosis    ← Must not be empty
  suspect_drug[0]: Test Drug           ← Must not be empty

Optional Fields:
  message_type: Спонтанный
  message_kind: Начальное сообщение
  message_date: 25.12.2025
  org_city: Алматы
  side_effects count: 1
  suspected_drugs count: 1
=== END DEBUG ===
```

### Server Response Analysis

**200/302 = Success**
```
Response status: 200
```

**400 = Bad Request**
- Usually means invalid parameter format
- Check date formats, boolean values, enum values

**500 = Server Error**
- Could be missing required field
- Could be invalid enum value
- Could be unexpected data format
- Check server response for clues

### Network Issues

If you see connection errors:
- Check internet connection
- Check if NDDA server is accessible
- Try browser first to confirm site is working

### Code Changes for Debugging

#### Added Files:
- `lib/services/yellow_card_debug.dart` - Debug helper with test data

#### Modified Files:
- `lib/services/yellow_card_service.dart` - Added debug logging
- `lib/screens/yellow_card_screen.dart` - Added debug button and detailed error display

#### To Remove Debug Output Later:

In `yellow_card_service.dart`, remove or comment out the print statements:
```dart
// print('=== YELLOW CARD SUBMISSION DEBUG ===');
// ... other print statements
```

### Troubleshooting Steps

1. **Click the debug button (🐛)**
2. **Choose "Minimal" test**
3. **Check console output for:**
   - URL being called
   - Data being sent
   - Response status
   - Response body (may contain error message)
4. **If 500 error, look for:**
   - PHP errors in response
   - Missing parameter messages
   - Invalid value messages
5. **Compare data format with working browser request**
6. **Try modifying one field at a time**

### Next Steps After Finding the Issue

Once you identify the problem field:
1. Fix the data mapping in `yellow_card_service.dart`
2. Update the `_buildFormData()` method
3. Test again with debug button
4. When working, test with real form data

### Getting Help

If still stuck, provide:
1. Console output from debug submission
2. Server response body
3. HTTP status code
4. Which test data was used (minimal or complete)

This information will help identify the exact issue.

