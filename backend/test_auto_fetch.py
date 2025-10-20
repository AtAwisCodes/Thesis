"""
Test script to verify automatic model fetching is working.
Run this after uploading a video to check if the backend is processing it.
"""

import requests
import time
import sys

BACKEND_URL = "http://192.168.100.25:5000"

def test_backend_health():
    """Test if backend is running"""
    try:
        response = requests.get(f"{BACKEND_URL}/api/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is healthy")
            return True
        else:
            print(f"❌ Backend returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Backend not reachable: {e}")
        return False

def check_video_status(video_id):
    """Check Firestore for video status (requires Firebase access)"""
    from google.cloud import firestore
    from google.oauth2 import service_account
    import os
    
    try:
        creds_path = os.path.join(os.path.dirname(__file__), 'firebase-credentials.json')
        credentials = service_account.Credentials.from_service_account_file(creds_path)
        db = firestore.Client(credentials=credentials)
        
        video_doc = db.collection('videos').document(video_id).get()
        if video_doc.exists:
            data = video_doc.to_dict()
            print(f"\n📹 Video Status:")
            print(f"   has3DModel: {data.get('has3DModel', False)}")
            print(f"   meshyStatus: {data.get('meshyStatus', 'unknown')}")
            print(f"   meshyTaskId: {data.get('meshyTaskId', 'none')}")
            print(f"   generatedModelUrl: {data.get('generatedModelUrl', 'none')}")
            return data.get('meshyTaskId')
        else:
            print(f"❌ Video {video_id} not found")
            return None
    except Exception as e:
        print(f"⚠️ Could not check Firestore: {e}")
        return None

def check_task_status(task_id):
    """Check task status via backend API"""
    try:
        response = requests.get(f"{BACKEND_URL}/api/model-status/{task_id}", timeout=10)
        if response.status_code == 200:
            data = response.json()
            status = data.get('status', 'unknown')
            progress = data.get('progress', 0)
            print(f"\n🔄 Model Generation Status:")
            print(f"   Status: {status}")
            print(f"   Progress: {progress}%")
            return status.lower()
        else:
            print(f"❌ Failed to check status: {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ Error checking status: {e}")
        return None

def list_models_for_video(video_id):
    """List all models for a video"""
    try:
        response = requests.get(f"{BACKEND_URL}/api/models/video/{video_id}", timeout=10)
        if response.status_code == 200:
            data = response.json()
            models = data.get('models', [])
            print(f"\n🎯 Models for Video:")
            print(f"   Count: {len(models)}")
            for i, model in enumerate(models):
                print(f"   Model {i+1}:")
                print(f"      Task ID: {model.get('taskId')}")
                print(f"      Status: {model.get('status')}")
                print(f"      URL: {model.get('modelFileUrl', 'N/A')[:60]}...")
            return models
        else:
            print(f"❌ Failed to list models: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Error listing models: {e}")
        return []

def main():
    print("=" * 60)
    print("🔍 AUTOMATIC MODEL FETCHING TEST")
    print("=" * 60)
    
    # Test 1: Backend health
    if not test_backend_health():
        print("\n❌ Backend must be running!")
        print("   Start it with: python app.py")
        sys.exit(1)
    
    # Get video ID from user
    print("\n" + "=" * 60)
    video_id = input("Enter video ID to check (or press Enter to skip): ").strip()
    
    if video_id:
        # Check video status in Firestore
        task_id = check_video_status(video_id)
        
        # Check task status if we have a task ID
        if task_id:
            status = check_task_status(task_id)
            
            if status == 'succeeded':
                print("\n✅ Model generation completed!")
                print("   Backend should have automatically fetched it.")
                print("   Checking for saved models...")
                
                # Wait a bit for auto-fetch to complete
                time.sleep(2)
                
                # List models
                models = list_models_for_video(video_id)
                
                if models:
                    print("\n✅ SUCCESS! Auto-fetch is working!")
                    print("   Model is ready for AR display.")
                else:
                    print("\n⚠️ Model completed but not yet saved.")
                    print("   Backend worker should fetch it within 10 seconds.")
                    print("   Wait and check again.")
            
            elif status == 'in_progress':
                print("\n⏳ Model is still generating...")
                print("   Backend will automatically fetch when complete.")
                print("   This can take 2-5 minutes.")
            
            elif status == 'failed':
                print("\n❌ Model generation failed on Meshy AI.")
                print("   Try uploading with better quality images.")
    
    # Test 2: List all available models
    print("\n" + "=" * 60)
    try:
        response = requests.get(f"{BACKEND_URL}/api/models/list", timeout=10)
        if response.status_code == 200:
            data = response.json()
            total = data.get('count', 0)
            print(f"📦 Total models in database: {total}")
            if total > 0:
                print("✅ Auto-fetch is working! Models have been saved.")
        else:
            print("⚠️ Could not list all models")
    except Exception as e:
        print(f"⚠️ Error: {e}")
    
    print("\n" + "=" * 60)
    print("Test complete!")
    print("\nTo test the full flow:")
    print("  1. Upload a video with 3-4 model images")
    print("  2. Note the video ID from console")
    print("  3. Run this script again with that video ID")
    print("  4. Wait for generation to complete")
    print("  5. Open AR camera in app with that video ID")
    print("=" * 60)

if __name__ == "__main__":
    main()
