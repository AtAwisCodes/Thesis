# ReXplore - AR-Enhanced Educational Platform

ReXplore is a Flutter-based mobile application that combines video content with augmented reality (AR) to create immersive educational experiences. Users can watch educational videos and view related 3D models in AR.

## Project Structure

```
Thesis/
├── lib/                   # Flutter source code
│   ├── main.dart         # Application entry point
│   ├── pages/            # UI screens
│   ├── augmented_reality/ # AR camera features
│   ├── services/         # Business logic
│   ├── model/            # Data models
│   └── viewmodel/        # State management
├── backend/              # Python Flask backend
│   ├── app.py           # Flask API server
│   ├── requirements.txt # Python dependencies
│   └── README.md        # Backend documentation
├── android/              # Android platform code
├── ios/                  # iOS platform code
└── pubspec.yaml          # Flutter dependencies
```

## Features

- **Video Library**: Browse and watch educational content
- **AR Visualization**: View 3D models in augmented reality
- **3D Model Generation**: Generate 3D models from video frames using Meshy AI
- **Firebase Integration**: User authentication and data storage
- **Supabase Storage**: Cloud storage for 3D models
- **Cross-platform**: Supports Android and iOS

## Prerequisites

### Flutter Development
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / Xcode for platform development
- ARCore (Android) / ARKit (iOS) compatible device

### Backend Development
- Python 3.8+
- Firebase project with Firestore enabled
- Meshy AI API key
- Supabase project with storage bucket

## Installation

### 1. Flutter App Setup

```bash
# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

### 2. Backend Setup

```bash
# Navigate to the backend directory
cd backend

# Install Python dependencies
pip install -r requirements.txt

# Set up environment variables (copy .env.example to .env)
# Add your API keys and credentials

# Run the Flask server
python app.py
```

## Configuration

### Firebase Configuration
1. Add your `google-services.json` (Android) to `android/app/`
2. Add your `GoogleService-Info.plist` (iOS) to `ios/Runner/`
3. Set up Firestore collections: `videos`, `users`, `generated_models_files`

### Supabase Configuration
1. Create a storage bucket named `models`
2. Update credentials in `lib/main.dart` and `backend/app.py`

### Meshy AI Configuration
1. Get your API key from [Meshy AI](https://www.meshy.ai/)
2. Add it to `backend/.env`

## Usage

### For End Users
1. Launch the app
2. Browse available videos
3. Watch educational content
4. Tap the AR icon to view 3D models
5. Place models in your environment using AR

### For Developers
- **Flutter App**: `lib/` contains all Dart code
- **Backend API**: `backend/app.py` handles 3D model generation
- **AR Features**: `lib/augmented_reality/` contains AR camera logic

## API Endpoints

The backend provides these endpoints:

- `GET /api/health` - Health check
- `POST /api/generate-3d` - Generate 3D model from video
- `GET /api/model-status/<task_id>` - Check generation status
- `POST /api/fetch-model` - Download completed model
- `GET /api/models/list` - List available models
- `DELETE /api/delete-model/<model_id>` - Delete a model

See `backend/README.md` for detailed API documentation.

## Dependencies

### Flutter (pubspec.yaml)
- `ar_flutter_plugin_2` - AR functionality
- `firebase_core` & `cloud_firestore` - Firebase integration
- `supabase_flutter` - Supabase client
- `http` - API requests
- `provider` - State management

### Python (backend/requirements.txt)
- `flask` - Web framework
- `flask-cors` - CORS handling
- `requests` - HTTP client
- `google-cloud-firestore` - Firestore client
- `supabase` - Supabase client

## Development

### Running Tests
```bash
# Flutter tests
flutter test

# Run with coverage
flutter test --coverage
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Troubleshooting

### Common Issues

**AR not working:**
- Ensure device supports ARCore (Android) or ARKit (iOS)
- Check camera permissions in app settings
- Verify you're on a physical device (not emulator)

**Backend connection failed:**
- Ensure Flask server is running (`python backend/app.py`)
- Check firewall settings
- Update backend URL in Flutter code if not using localhost

**Model generation slow:**
- Meshy AI processing can take 5-10 minutes
- Check backend logs for progress
- Verify Meshy AI API key is valid

## Contributing

This is a thesis project. For contributions or questions, please contact the project maintainer.

## License

This project is part of an academic thesis. All rights reserved.

## Acknowledgments

- Meshy AI for 3D model generation API
- Firebase for backend services
- Supabase for storage solutions
- ARCore/ARKit for AR capabilities

## Contact

For questions or support, please refer to the thesis documentation or contact the development team.
