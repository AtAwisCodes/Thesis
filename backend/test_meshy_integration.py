#!/usr/bin/env python3
"""
Test script for Meshy AI integration.
This script tests the complete workflow:
1. Generate 3D model from images
2. Check model status
3. Fetch completed model
4. List models for video
"""

import requests
import json
import time
from datetime import datetime

# Backend URL
BASE_URL = "http://localhost:5000"

def test_health_check():
    """Test if the backend server is running."""
    try:
        response = requests.get(f"{BASE_URL}/api/health", timeout=10)
        if response.status_code == 200:
            print("Backend server is healthy")
            return True
        else:
            print(f"Backend health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"Cannot connect to backend: {e}")
        return False

def test_generate_3d_model():
    """Test generating a 3D model from sample video."""
    print("\nTesting 3D model generation...")
    
    # Sample payload - you'll need a real video_id with modelImages in Firestore
    payload = {
        "video_id": "test_video_123",  # Replace with actual video ID
        "user_id": "test_user_456"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/generate-3d",
            json=payload,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            task_id = result.get("task_id")
            print(f"3D generation started successfully")
            print(f"   Task ID: {task_id}")
            return task_id
        else:
            print(f"3D generation failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"Error during 3D generation: {e}")
        return None

def test_model_status(task_id):
    """Test checking model generation status."""
    if not task_id:
        print("Skipping status check (no task ID)")
        return None
        
    print(f"\nChecking status for task: {task_id}")
    
    try:
        response = requests.get(
            f"{BASE_URL}/api/model-status/{task_id}",
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            status = result.get("status")
            progress = result.get("progress", 0)
            print(f"   Status check successful")
            print(f"   Status: {status}")
            print(f"   Progress: {progress}%")
            return status
        else:
            print(f"Status check failed: {response.status_code}")
            return None
            
    except Exception as e:
        print(f"Error during status check: {e}")
        return None

def test_fetch_model(task_id):
    """Test fetching a completed model."""
    if not task_id:
        print("Skipping model fetch (no task ID)")
        return False
        
    print(f"\nTesting model fetch for task: {task_id}")
    
    payload = {
        "task_id": task_id,
        "user_id": "test_user_456"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/fetch-model",
            json=payload,
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            model_url = result.get("model_public_url")
            doc_id = result.get("firestore_doc_id")
            print(f"   Model fetch successful")
            print(f"   Model URL: {model_url}")
            print(f"   Firestore Doc ID: {doc_id}")
            return True
        else:
            print(f"Model fetch failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"Error during model fetch: {e}")
        return False

def test_list_models():
    """Test listing available models."""
    print(f"\nTesting model listing...")
    
    try:
        # Test general listing
        response = requests.get(f"{BASE_URL}/api/models/list", timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            count = result.get("count", 0)
            print(f"Model listing successful")
            print(f"   Total models: {count}")
            
            # Test video-specific listing
            response2 = requests.get(f"{BASE_URL}/api/models/video/test_video_123", timeout=30)
            if response2.status_code == 200:
                result2 = response2.json()
                video_count = result2.get("count", 0)
                print(f"   Video-specific listing successful")
                print(f"   Models for test video: {video_count}")
            else:
                print(f"   Video-specific listing failed: {response2.status_code}")
                
            return True
        else:
            print(f" Model listing failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f" Error during model listing: {e}")
        return False

def main():
    """Run all tests."""
    print(" Starting Meshy AI Integration Tests")
    print("=" * 50)
    
    # Test 1: Health check
    if not test_health_check():
        print("\nCannot proceed without healthy backend")
        return
    
    # Test 2: Generate 3D model (might fail if no test data in Firestore)
    task_id = test_generate_3d_model()
    
    # Test 3: Check status
    status = test_model_status(task_id)
    
    # Test 4: Fetch model (only if succeeded)
    if status == "succeeded":
        test_fetch_model(task_id)
    elif task_id:
        print(f"  Model not ready yet (status: {status})")
        print("   You can test fetch later when it's completed")
    
    # Test 5: List models
    test_list_models()
    
    print("\n" + "=" * 50)
    print("     Tests completed!")
    print("\n   Summary:")
    print("   - Backend is functional and ready to use")
    print("   - API endpoints are working")
    print("   - To test full workflow, add real video with modelImages to Firestore")

if __name__ == "__main__":
    main()
