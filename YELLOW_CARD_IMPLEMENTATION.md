# Yellow Card (Желтая карта) - Implementation Summary

## Overview
Complete implementation of the Yellow Card adverse drug reaction reporting system integrated with the NDDA (National Drug and Device Authority) Kazakhstan API.

**Reference Website**: [https://www.ndda.kz/register.php/sideeffects/new/lang/ru](https://www.ndda.kz/register.php/sideeffects/new/lang/ru)

## Features Implemented

### 1. **MedDRA Integration** ✅
Integrated the Medical Dictionary for Regulatory Activities (MedDRA) for standardized medical terminology.

#### Files Created:
- **`lib/models/meddra_model.dart`** - Data model for MedDRA hierarchy
- **`lib/services/meddra_service.dart`** - Service to fetch MedDRA data from API
- **`lib/widgets/meddra_selector_dialog.dart`** - Interactive dialog for selecting diagnoses

#### API Endpoint:
```
GET https://www.ndda.kz/register.php/Sideeffects/MedDra
```

#### Features:
- 🔍 Real-time search across all fields (text, abbreviation, code)
- 📁 Hierarchical structure with expandable parent-child nodes
- 🔄 Automatic retry on error
- ✨ Loading states and error handling
- 📱 Responsive design (90% width, 80% height)

#### Usage in Form:
The MedDRA selector is integrated into:
1. **Primary Diagnosis** (Основной диагноз) - Required field
2. **Secondary Diagnosis** (Сопутствующий диагноз) - Optional field
3. **Side Effects** (Побочные действия) - Multiple entries

Each field has a blue search button (🔍) that opens the MedDRA selector dialog.

---

### 2. **Form Submission Service** ✅
Complete implementation of form data submission to NDDA server.

#### File Created:
- **`lib/services/yellow_card_service.dart`** - Handles form submission and data mapping

#### API Endpoint:
```
POST https://www.ndda.kz/register.php/sideeffects/new/lang/ru
Content-Type: application/x-www-form-urlencoded
```

#### Data Mapping:
All form fields are mapped to the exact parameter names expected by the NDDA API:

##### Section 1: General Information (PDLScard)
- `message_type` - Type of report
- `message_kind` - Initial or follow-up
- `message_date` - Date of report (format: dd.MM.yyyy)
- `org_name` - Organization name (REQUIRED)
- `dept_id` - City/department
- `org_address` - Organization address
- `org_phone` - Phone number
- `org_email` - Email address
- `source` - Reporter type (врач, медсестра, etc.)
- `source_name` - Reporter name
- `source_phone` - Reporter phone
- `source_email` - Reporter email

##### Section 2: Patient Information (PDLScard)
- `patient_name` - Patient initials (REQUIRED)
- `medrecord_number` - Medical record number
- `patient_birthdate` - Date of birth (format: dd.MM.yyyy)
- `patient_age` - Age in years (REQUIRED)
- `patient_sex` - Sex: 0=Female, 1=Male, 2=Unknown (REQUIRED)
- `patient_growth` - Height in cm
- `patient_weight` - Weight in kg
- `additional_information_patient` - Additional info
- `patient_nation` - Nationality
- `diagnosis_primary` - Primary diagnosis (REQUIRED, MedDRA)
- `diagnosis_secondary` - Secondary diagnosis (MedDRA)

##### Section 3: Pregnancy Information (PDLScard)
- `pregnancy` - 0=No, 1=Yes
- `last_menstrual_date` - Last menstrual period
- `due_date` - Expected due date
- `fetus_count` - Number of fetuses
- `conceiving_type` - Type of conception
- `pregnancy_outcome` - Pregnancy outcome
- `fact_due_date` - Actual delivery date
- `gestational_date` - Gestational date
- `due_type` - Type of delivery
- `child_weight` - Baby weight (kg)
- `child_growth` - Baby height (cm)
- `child_sex` - Baby sex
- `apar_1min`, `apar_5min`, `apar_10min` - Apgar scores

##### Section 4: Suspected Drugs (PdlsDrugs) - Array [0-9]
- `suspect_drug[i]` - Drug name (REQUIRED for first entry)
- `suspect_drug_begin_date[i]` - Start date
- `suspect_drug_end_date[i]` - End date
- `suspect_drug_use_method[i]` - Route of administration
- `suspect_drug_description[i]` - Batch/lot number
- `suspect_drug_indications[i]` - Indications
- `suspect_drug_remedy[i]` - Actions taken

##### Section 5: Side Effects (PDLSsideeffects) - Array [0-9]
- `side_effect[i]` - Effect description (MedDRA)
- `outcome[i]` - Outcome
- `relation[i]` - Relationship to drug
- `sideeffects_serious` - Are effects serious? (0/1)
- `sideeffects_reason` - Reason if serious
- `sideeffects_causeofdeath` - Cause of death if applicable

##### Section 6: Accompanying Drugs (PDLSaccompaying) - Array [0-9]
- `drug[i]` - Drug name
- `dosage_form[i]` - Dosage form/batch
- `injection_comment[i]` - Dose/route/side
- `begin_date[i]` - Start date
- `end_date[i]` - End date
- `indications[i]` - Indications
- `remedy[i]` - Actions taken

##### Section 7: Medical History (PDLShistory) - Array [0-9]
- `name[i]` - History item name
- `continues[i]` - Is it ongoing? (0/1)

##### Submission Parameters:
- `ls` - "Сохранить" (Save button)
- `complete_sign` - "1" (Completion flag)

---

### 3. **Enhanced Yellow Card Screen** ✅
Updated the main form screen with submission functionality.

#### File Modified:
- **`lib/screens/yellow_card_screen.dart`**

#### Key Changes:
1. **Import Added**: `yellow_card_service.dart`
2. **New Method**: `_buildMedDraTextField()` - Text field with MedDRA selector button
3. **Updated Method**: `_submitForm()` - Complete async submission implementation
4. **Helper Method**: `_mapSexToValue()` - Maps sex labels to API values

#### Submission Flow:
1. **Validation** - Checks all required fields
2. **Loading Dialog** - Shows progress indicator
3. **Data Preparation** - Maps all form data to API format
4. **API Call** - Posts data to NDDA server
5. **Response Handling** - Shows success/error dialog
6. **Navigation** - Returns to previous screen on success

#### User Experience:
- ✅ Loading indicator during submission
- ✅ Success confirmation dialog
- ✅ Error handling with retry option
- ✅ Automatic navigation on success
- ✅ Form validation before submission

---

## Data Flow Diagram

```
User Input → Form Fields → Validation → Data Mapping → HTTP POST → NDDA Server
                                                            ↓
                                                       Response
                                                            ↓
                                                    Success/Error Dialog
```

## API Integration Summary

### Endpoints Used:
1. **MedDRA Data**: `GET https://www.ndda.kz/register.php/Sideeffects/MedDra`
2. **Form Submission**: `POST https://www.ndda.kz/register.php/sideeffects/new/lang/ru`

### Authentication:
- No authentication required for these endpoints
- Form submission uses standard HTTP POST with URL-encoded data

### Response Handling:
- **Success**: HTTP 200 or 302 (redirect)
- **Error**: Any other status code or exception

---

## Required Fields

The following fields are **mandatory** for form submission:

1. **Organization Name** (Наименование)
2. **Patient Name/Initials** (Ф.И.О.(инициалы))
3. **Patient Age** (Возраст, лет)
4. **Patient Sex** (Пол)
5. **Primary Diagnosis** (Основной диагноз)
6. **First Suspected Drug Name** (Наименование препарата #1)

All other fields are optional but recommended for complete reporting.

---

## Testing Checklist

- [ ] Test MedDRA selector dialog opens correctly
- [ ] Test search functionality in MedDRA selector
- [ ] Test selecting items from MedDRA hierarchy
- [ ] Test form validation for required fields
- [ ] Test form submission with minimal data
- [ ] Test form submission with complete data
- [ ] Test error handling (network errors)
- [ ] Test success dialog and navigation
- [ ] Test date formatting (dd.MM.yyyy)
- [ ] Test array data (drugs, effects, history)

---

## Future Enhancements

### Potential Improvements:
1. **Offline Support** - Cache submitted forms for later submission
2. **Draft Saving** - Save incomplete forms as drafts
3. **Photo Attachments** - Add ability to attach images
4. **History View** - View previously submitted reports
5. **Auto-fill** - Remember organization details
6. **Validation Enhancement** - Add more field-level validation
7. **Multi-language** - Support English/Russian toggle
8. **PDF Export** - Generate PDF of submitted form

---

## Dependencies

### Required Packages:
- `http: ^1.1.0` - HTTP client for API calls
- `intl: ^0.19.0` - Date formatting
- `flutter/material.dart` - UI components

All dependencies are already included in `pubspec.yaml`.

---

## Code Structure

```
lib/
├── models/
│   └── meddra_model.dart          # MedDRA data models
├── services/
│   ├── meddra_service.dart        # MedDRA API service
│   └── yellow_card_service.dart   # Form submission service
├── screens/
│   └── yellow_card_screen.dart    # Main form screen
└── widgets/
    └── meddra_selector_dialog.dart # MedDRA selection dialog
```

---

## Usage Example

```dart
// Navigate to Yellow Card screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const YellowCardScreen(),
  ),
);
```

---

## Notes

- All dates are formatted as `dd.MM.yyyy` (e.g., "25.12.2025")
- Sex values: 0 = Female, 1 = Male, 2 = Unknown
- Boolean values: "0" = No/False, "1" = Yes/True
- Arrays support up to 10 items each
- Empty array slots are sent as empty strings
- Form uses URL-encoded POST data format

---

## Support

For issues or questions related to the NDDA API, contact:
- Website: https://www.ndda.kz
- API Documentation: Contact NDDA directly

---

**Implementation Date**: December 25, 2025  
**Status**: ✅ Complete and Ready for Testing

