# 🚀 How to Run the Meshy AI Backend with Flutter App

## ✅ **Quick Start Guide**

### **Step 1: Start the Python Backend**

Open a terminal and run:

```powershell
cd "C:\ReXplore\Thesis\backend"
python app.py
```

**Expected Output:**
```
Starting Meshy AR Backend Server...
Server running on http://localhost:5000
Available endpoints:
  - GET  /api/health
  - POST /api/generate-3d
  - GET  /api/model-status/<task_id>
  - POST /api/fetch-model
  - GET  /api/models/list
  - GET  /api/stream-status/<task_id>
  - DELETE /api/delete-model/<model_id>
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.x.x:5000
```

**⚠️ KEEP THIS TERMINAL WINDOW OPEN** - The backend must stay running while using the Flutter app.

---

### **Step 2: Verify Backend is Running**

Open a new terminal and test:

```powershell
curl http://localhost:5000/api/health
```

**Expected Response:**
```json
{"status":"healthy","service":"Meshy AR Backend"}
```

✅ If you see this, your backend is working!

---

### **Step 3: Run the Flutter App**

In a **NEW terminal** (keep backend running), navigate to the Flutter project:

```powershell
cd "C:\ReXplore\Thesis"
flutter run
```

Or use VS Code's "Run" button (F5)

---

## 📱 **Using the App**

### **To Generate a 3D Model:**

1. **Upload a video** with at least 3 images in the `modelImages` field in Firestore
2. **Open the video** in your Flutter app
3. **Tap "View in AR"** button
4. **Tap menu icon** (three dots) → "Generate from current video"
5. **Wait** for generation (shows progress in real-time)
6. **Tap screen** to place the 3D model in AR

---

## 🐛 **Troubleshooting**

### **Error: "Connection refused"**
**Cause:** Backend is not running
**Fix:** Start the Python backend (Step 1 above)

### **Error: "No module named 'supabase'"**
**Cause:** Missing dependencies
**Fix:**
```powershell
cd "C:\ReXplore\Thesis\backend"
pip install -r requirements.txt
```

### **Error: "modelImages missing"**
**Cause:** Video in Firestore doesn't have images
**Fix:** Add at least 3 image URLs to the video document's `modelImages` array

### **Backend closes immediately**
**Cause:** Python error on startup
**Fix:** Check the error message and install missing packages

---

## 🔍 **Checking Backend Status**

### **Test health endpoint:**
```powershell
curl http://localhost:5000/api/health
```

### **Test from browser:**
Open: `http://localhost:5000/api/health`

### **Check if port is in use:**
```powershell
netstat -ano | findstr :5000
```

---

## 📋 **Development Workflow**

1. **Start backend** first (keep running)
2. **Run Flutter app** in another terminal
3. **Use the app** to generate and view models
4. **Stop backend** with `Ctrl+C` when done

---

## ⚡ **Quick Commands**

### **Start Backend:**
```powershell
cd "C:\ReXplore\Thesis\backend" ; python app.py
```

### **Start Flutter App:**
```powershell
cd "C:\ReXplore\Thesis" ; flutter run
```

### **Test Backend:**
```powershell
Invoke-RestMethod -Uri http://localhost:5000/api/health
```

---

## 🎯 **Important Notes**

- ✅ Backend URL is already configured in Flutter: `http://localhost:5000`
- ✅ CORS is enabled for Flutter app communication
- ✅ Meshy API key is configured in backend
- ✅ Firestore connection is set up
- ⚠️ Supabase has Python 3.14 compatibility issues (using direct URLs instead)
- ⚠️ Backend must be running BEFORE starting Flutter app

---

## 🚀 **You're Ready!**

Both your backend and Flutter app are now configured and ready to generate 3D models from Meshy AI!
