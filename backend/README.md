# ReXplore Backend - 3D Model Generation Service

This is the Python Flask backend for the ReXplore application, handling 3D model generation via Meshy AI.

## Features

- Generate 3D models from video images using Meshy AI
- Store and retrieve models from Supabase Storage
- Manage model metadata in Firebase Firestore
- Real-time status updates via Server-Sent Events (SSE)
- RESTful API for Flutter frontend integration

## Prerequisites

- Python 3.8 or higher
- Google Cloud credentials for Firestore (service account JSON)
- Meshy AI API key
- Supabase project with storage bucket

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Set up environment variables:
   - Copy `.env.example` to `.env`
   - Fill in your API keys and credentials

3. Set up Google Cloud credentials:
   - Download your service account JSON from Firebase Console
   - Set the environment variable:
     ```bash
     set GOOGLE_APPLICATION_CREDENTIALS=path\to\your\service-account.json
     ```

## Running the Server

```bash
python app.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### Health Check
- **GET** `/api/health`
- Returns server status

### Generate 3D Model
- **POST** `/api/generate-3d`
- Body: `{ "video_id": "string", "user_id": "string" }`
- Initiates 3D model generation from video images

### Check Model Status
- **GET** `/api/model-status/<task_id>`
- Returns current status of model generation

### Fetch Generated Model
- **POST** `/api/fetch-model`
- Body: `{ "task_id": "string", "user_id": "string" }`
- Downloads and uploads completed model to Supabase

### List Available Models
- **GET** `/api/models/list?user_id=<user_id>`
- Returns list of all generated models

### Stream Status Updates
- **GET** `/api/stream-status/<task_id>`
- Server-Sent Events (SSE) endpoint for real-time updates

### Delete Model
- **DELETE** `/api/delete-model/<model_id>`
- Removes model from Supabase and Firestore

## Integration with Flutter

The Flutter app communicates with this backend via HTTP requests. Update the backend URL in your Flutter app:

```dart
// In augmented_camera.dart
final response = await http.post(
  Uri.parse('http://localhost:5000/api/generate-3d'),
  // or your deployed backend URL
  ...
);
```

## Deployment

For production deployment, consider:
- Using a production WSGI server (Gunicorn, uWSGI)
- Setting up proper CORS policies
- Using environment variables for all secrets
- Implementing rate limiting
- Adding authentication middleware

## Project Structure

```
backend/
├── app.py              # Main Flask application
├── requirements.txt    # Python dependencies
├── .env.example       # Environment variables template
└── README.md          # This file
```

## Troubleshooting

- **Firebase connection issues**: Ensure your service account JSON is properly configured
- **Meshy AI timeout**: Model generation can take 5-10 minutes, be patient
- **CORS errors**: Check CORS configuration in `app.py`
- **Port already in use**: Change the port in `app.py` or kill the existing process

## License

Part of the ReXplore thesis project
