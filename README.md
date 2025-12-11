# NDDA Helper

A Flutter web application for browsing, searching, and managing drug registry data from the Kazakhstan NDDA (National Drug Database Agency).

## Features

### 🔍 **Intelligent Search**
- Search across multiple fields simultaneously (drug name, ATC name, ATC code, registration number, producer)
- Case-insensitive matching
- Real-time filtering
- Partial text matching

### 💾 **Local Caching**
- Data is automatically saved locally after first fetch
- Only fetches from API when local database is empty
- Manual reload button to force refresh
- Faster subsequent loads

### ✅ **Multiselect & Export**
- Select multiple drugs by tapping cards
- Visual feedback for selected items
- View only selected items with filter toggle
- Export selected drugs to CSV format
- Persistent selection across sessions

### 🎨 **Clean Design**
- Minimalist black & white design inspired by shadcn/ui
- Responsive card-based layout
- Clear typography hierarchy
- Smooth interactions and animations

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- A web browser (Chrome, Firefox, Safari, or Edge)

### Installation

1. Clone the repository:
```bash
cd /path/to/nddahelper
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run on web:
```bash
flutter run -d chrome
```

Or build for web:
```bash
flutter build web
```

## Usage

### First Launch
1. The app will automatically fetch drug data from the NDDA API
2. Data is saved locally for faster future access
3. Browse the list of registered drugs

### Searching
1. Use the search bar at the top to filter drugs
2. Search works across:
   - Drug name (e.g., "Мифалцин")
   - ATC name (e.g., "Моксифлоксацин")
   - ATC code (e.g., "J01MA14")
   - Registration number
   - Producer name

### Selecting Drugs
1. Tap on any drug card to select/deselect it
2. Selected cards turn black with white text
3. Use the "Selected (X)" toggle to view only selected items
4. Selections are saved automatically

### Exporting Data
1. Select the drugs you want to export
2. Tap the "Export (X)" floating button at the bottom right
3. A CSV file will be downloaded with all selected drugs
4. CSV includes: ID, name, ATC info, producer, country, dates, and more

### Reloading Data
1. Tap the refresh icon in the app bar
2. This will fetch fresh data from the API
3. Useful for getting the latest drug registrations

## Project Structure

```
lib/
├── main.dart                 # App entry point and theme
├── models/
│   └── drug_model.dart      # Drug data model
├── services/
│   ├── api_service.dart     # API communication
│   ├── storage_service.dart # Local storage handler
│   └── csv_service.dart     # CSV export functionality
├── screens/
│   └── home_screen.dart     # Main screen with list
└── widgets/
    └── drug_card.dart       # Drug item card widget
```

## API Details

**Endpoint**: `https://register.ndda.kz/register-backend/RegisterService/list`  
**Method**: POST  
**Content-Type**: application/json

The API returns an array of drug objects with comprehensive information about registered pharmaceutical products in Kazakhstan.

## Technologies

- **Flutter**: Cross-platform UI framework
- **http**: For API requests
- **shared_preferences**: Local data persistence
- **csv**: CSV file generation
- **universal_html**: Web-specific HTML operations

## Design Philosophy

The app follows a minimalist design approach inspired by shadcn/ui:
- Clean white background
- Black text and accents
- Subtle gray tones for secondary elements
- Clear borders and shadows
- Consistent spacing and typography
- Focus on content and usability

## License

This project is for educational and informational purposes.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
