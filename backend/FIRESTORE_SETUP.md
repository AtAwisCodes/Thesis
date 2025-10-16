# Firestore Setup Instructions

##  Current Error
```
google.auth.exceptions.DefaultCredentialsError: Your default credentials were not found.
```

**Why?** The backend cannot connect to Firestore because Firebase credentials are missing.

---

##  Solution: Download Firebase Service Account Key

### Step 1: Go to Firebase Console
1. Open: **https://console.firebase.google.com/**
2. Select your project (likely named **"ReXplore"** or similar)

### Step 2: Generate Service Account Key
1. Click the **Settings** icon (top left)
2. Select **"Project Settings"**
3. Go to the **"Service Accounts"** tab
4. Click **"Generate New Private Key"** button (bottom of page)
5. Click **"Generate Key"** in the confirmation dialog
6. A JSON file will download automatically (e.g., `rexplore-firebase-adminsdk-xxxxx.json`)

### Step 3: Save the Credentials File
1. **Rename** the downloaded file to: **`firebase-credentials.json`**
2. **Move** it to: `c:\ReXplore\Thesis\backend\firebase-credentials.json`
   - It should be in the same folder as `app.py`

### Step 4: Verify Setup
Run the backend again:
```powershell
cd c:\ReXplore\Thesis\backend
python app.py
```

**Expected output:**
```
 Firestore initialized with service account credentials
Starting Meshy AR Backend Server...
Server running on http://0.0.0.0:5000
```

If you see this, **the workflow is now working!** 

---

##  Security Note
 **NEVER commit `firebase-credentials.json` to Git!**
-  It's already protected in `.gitignore`
- This file contains **sensitive admin credentials**
- Keep it **local only** - never share publicly

---

##  Alternative: Environment Variable (Optional)
Instead of placing the file in the backend folder, you can set an environment variable:

**PowerShell:**
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\ReXplore\Thesis\backend\firebase-credentials.json"
python app.py
```

**Or permanently set it:**
```powershell
[System.Environment]::SetEnvironmentVariable('GOOGLE_APPLICATION_CREDENTIALS', 'C:\ReXplore\Thesis\backend\firebase-credentials.json', 'User')
```

---

##  Checklist: Is Your Workflow Working?

After setting up Firestore credentials, verify:

- [ ] Backend starts without errors
- [ ] You see: ` Firestore initialized with service account credentials`
- [ ] Health check works: http://192.168.254.100:5000/api/health
- [ ] Flutter app can upload videos with 3+ images
- [ ] Video player shows "Checking..." then model status
- [ ] 3D model generation completes successfully

**If all checked, your workflow is fully operational!** 
