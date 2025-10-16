#  Backend Setup & Start Guide

## **CRITICAL: The backend MUST be running for 3D model generation to work!**

---

## **Quick Start** 

### 1. Navigate to backend folder:
```bash
cd c:\ReXplore\Thesis\backend
```

### 2. Install dependencies (first time only):
```bash
pip install -r requirements.txt
```

### 3. Start the backend:
```bash
python app.py
```

You should see:
```
Starting Meshy AR Backend Server...
Server running on http://localhost:5000
Available endpoints:
  - GET  /api/health
  - POST /api/generate-3d
  ...
```

---

## **How It Works** 

### Upload Flow:
1. **User uploads video + 3-4 images** in Flutter app
2. **Images uploaded to Supabase** `ar_pics` bucket
3. **Video uploaded to Supabase** `videos` bucket
4. **Metadata saved to Firestore** with `modelImages` URLs
5. **Flutter calls backend** → `POST /api/generate-3d`
6. **Backend calls Meshy AI** to generate 3D model
7. **Backend polls Meshy** for completion (5 min timeout)
8. **Backend downloads .glb** and uploads to Supabase `models` bucket
9. **Firestore updated** with 3D model URL and status

---

## **Testing the Backend** 

### Check if backend is running:
```bash
curl http://localhost:5000/api/health
```

Expected response:
```json
{"status": "healthy", "service": "Meshy AR Backend"}
```

### Test 3D generation (after uploading a video):
```bash
python test_meshy_integration.py
```

---

## **Common Issues** 

###  "Cannot connect to backend"
**Solution**: Make sure `python app.py` is running in backend folder

###  "Module not found" errors
**Solution**: Install dependencies: `pip install -r requirements.txt`

###  "Firestore permission denied"
**Solution**: Ensure Firebase credentials are configured correctly

###  "No model URL found"
**Solution**: Check Meshy AI API key and credit balance

###  "modelImages missing or less than 3"
**Solution**: Upload video must have at least 3 images selected

---

## **Configuration** 

### Backend Configuration (in `app.py`):
- **Meshy API Key**: `msy_zkhom6uoX6vtWwvnrtsOB5PT01yO049AIXRX`
- **Supabase URL**: `https://ynjqcaxxofteqfbcnbpy.supabase.co`
- **Port**: `5000`

### Flutter Configuration (in `upload_function.dart`):
- **Backend URL**: `http://localhost:5000`
- Change to deployed URL for production

---

## **Deployment** 

For production deployment:

1. Deploy backend to **Heroku**, **Railway**, or **Google Cloud Run**
2. Update `_backendUrl` in `upload_function.dart` to deployed URL
3. Configure CORS for your Flutter app domain
4. Use environment variables for sensitive keys

---

## **Monitoring** 

### Watch backend logs:
The backend prints detailed logs for each operation:
- `✅` Success operations
- `❌` Errors
- `📸` 3D generation queued
- `🚀` Generation started

### Check Firestore:
- `videos` collection → `has3DModel`, `generatedModelUrl`
- `generated_models_files` collection → all generated models

### Check Supabase Storage:
- `ar_pics` bucket → uploaded images
- `videos` bucket → uploaded videos
- `models` bucket → generated .glb files

---

## **Need Help?** 

1. Check backend console for error messages
2. Check Flutter debug console for "3D Model Status:" logs
3. Verify Firestore `modelImages` field exists and has 3+ URLs
4. Test Meshy API key at: https://www.meshy.ai/api-docs
5. Check Supabase buckets are public and accessible

---

**Remember**: The backend must be running continuously while testing 3D model generation!
