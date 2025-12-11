# NDDA Helper - Implementation Plan

## 1. PLAN - Architecture & Design

### 1.1 Core Features
- **Data Fetching**: POST request to NDDA API
- **Local Caching**: Store data locally, only fetch when empty
- **Reload Button**: Force refresh from API
- **Intelligent Search**: Search across name, atc_name, and code fields
- **Multiselect**: Select multiple items from the list
- **Selection Management**: Separate list for selected items
- **CSV Export**: Export selected items to CSV file

### 1.2 Technology Stack
- **Framework**: Flutter (Web optimized)
- **HTTP Client**: http package
- **Local Storage**: shared_preferences (web compatible)
- **CSV Export**: csv package
- **State Management**: Built-in setState (simple and clean)

### 1.3 Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── drug_model.dart      # Drug registry data model
├── services/
│   ├── api_service.dart     # API calls handler
│   └── storage_service.dart # Local storage handler
├── screens/
│   ├── home_screen.dart     # Main screen with search & list
│   └── selected_screen.dart # Selected items screen
└── widgets/
    ├── drug_card.dart       # Drug item card widget
    └── search_bar.dart      # Custom search bar
```

### 1.4 Data Model
Based on API response structure:
- id, reg_number, regTypesName, name, reg_action_id, regActions
- reg_date, reg_term, expiration_date
- producerNameRu, producerNameEng, countryNameRu
- drugTypesName, atc_name, code
- short_name, short_name_kz, dosage_value
- storage_term, storageMeasure_name
- Various boolean flags (gmp_sign, generic_sign, etc.)
- dosageForm_name, concentration, nd_number

### 1.5 UI Design (Black & White - shadcn inspired)
- **Color Scheme**: 
  - Background: White (#FFFFFF)
  - Text Primary: Black (#000000)
  - Text Secondary: Gray (#6B7280)
  - Borders: Light Gray (#E5E7EB)
  - Hover: Very Light Gray (#F9FAFB)
  - Selected: Black with white text
  
- **Components**:
  - Clean card-based list
  - Rounded corners (8px)
  - Subtle shadows
  - Minimal borders
  - Clear typography hierarchy
  - Checkbox for multiselect
  - Floating action button for export

### 1.6 Search Algorithm
- **Intelligent Search Features**:
  - Case-insensitive matching
  - Search across multiple fields simultaneously (name, atc_name, code)
  - Partial matching support
  - Trim whitespace
  - Highlight matching terms (optional)
  - Real-time search results

### 1.7 User Flow
1. App loads → Check local storage
2. If empty → Fetch from API → Save locally
3. If not empty → Load from local storage
4. Display list with search bar
5. User searches → Filter results in real-time
6. User taps items → Toggle selection
7. Selected items appear in separate list
8. User clicks export → Generate and download CSV

## 2. IMPLEMENTATION - Step by Step

### Step 1: Dependencies (pubspec.yaml)
```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
  csv: ^6.0.0
  universal_html: ^2.2.4
```

### Step 2: Create Drug Model
- Parse JSON response
- Convert to/from JSON for storage
- Include all necessary fields

### Step 3: Storage Service
- Save JSON string to shared_preferences
- Load and parse from storage
- Clear cache functionality

### Step 4: API Service
- POST request to NDDA endpoint
- Handle responses and errors
- Integrate with storage service

### Step 5: Main UI
- AppBar with title and reload button
- Search TextField
- ListView with drug cards
- Show loading states
- Error handling

### Step 6: Drug Card Widget
- Display key information (name, atc_name, code)
- Checkbox for selection
- Tap to toggle selection
- Visual feedback for selected state

### Step 7: Selected Items Screen
- Bottom sheet or separate tab
- List of selected items
- Remove from selection
- Export to CSV button

### Step 8: CSV Export
- Generate CSV from selected items
- Include relevant columns
- Download functionality for web

### Step 9: Polish & Testing
- Test search functionality
- Test multiselect
- Test CSV export
- Ensure responsive design
- Add loading indicators
- Error handling

## 3. Implementation Commands

### Command 1: Setup & Core Structure
Create models, services, and basic architecture

### Command 2: UI & Features
Build screens, widgets, search, selection, and export functionality

