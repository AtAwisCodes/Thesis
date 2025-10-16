from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import requests
from google.cloud import firestore
from google.oauth2 import service_account
from supabase import create_client, Client
import tempfile
import os
import json

app = Flask(__name__)
CORS(app)

# --- CONFIGURATION ---
MESHY_API_KEY = "msy_zkhom6uoX6vtWwvnrtsOB5PT01yO049AIXRX"
SUPABASE_URL = "https://ynjqcaxxofteqfbcnbpy.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InluanFjYXh4b2Z0ZXFmYmNuYnB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ5OTUzNDEsImV4cCI6MjA3MDU3MTM0MX0.mSqnKhqSmrICZ5B2iCDcQgeOLF3xCgC1MnMnF1FbzMM"

# Path to your Firebase service account key JSON file
FIREBASE_CREDENTIALS_PATH = os.path.join(os.path.dirname(__file__), 'firebase-credentials.json')

# --- INITIALIZE CLIENTS ---
try:
    if os.path.exists(FIREBASE_CREDENTIALS_PATH):
        # Use service account credentials
        credentials = service_account.Credentials.from_service_account_file(FIREBASE_CREDENTIALS_PATH)
        db = firestore.Client(credentials=credentials)
        print("Firestore initialized with service account credentials")
    else:
        print("WARNING: firebase-credentials.json not found!")
        print(f"Expected location: {FIREBASE_CREDENTIALS_PATH}")
        print("Attempting to use Application Default Credentials...")
        db = firestore.Client()
except Exception as e:
    print(f"ERROR: Failed to initialize Firestore: {e}")
    print("\nTo fix this, do ONE of the following:")
    print("1. Download your Firebase service account JSON from:")
    print("Firebase Console → Project Settings → Service Accounts → Generate New Private Key")
    print(f"2. Save it as: {FIREBASE_CREDENTIALS_PATH}")
    print(" 3. OR set GOOGLE_APPLICATION_CREDENTIALS environment variable")
    print("\nServer will continue but Firestore operations will fail.\n")
    db = None

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# --- HELPER FUNCTIONS ---
def get_meshy_headers():
    return {"Authorization": f"Bearer {MESHY_API_KEY}", "Content-Type": "application/json"}

# --- ENDPOINTS ---

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "Meshy AR Backend"}), 200


@app.route('/api/generate-3d', methods=['POST'])
def generate_3d_model():
    """
    Generate 3D model from video's model images stored in Firestore.
    Expects JSON: { "video_id": "...", "user_id": "..." }
    """
    try:
        if db is None:
            return jsonify({"error": "Firestore not initialized - check server logs"}), 503
            
        data = request.json
        video_id = data.get('video_id')
        user_id = data.get('user_id')

        if not video_id:
            return jsonify({"error": "video_id is required"}), 400

        # Step 1: Fetch video document from Firestore
        doc_ref = db.collection('videos').document(video_id)
        doc = doc_ref.get()

        if not doc.exists:
            return jsonify({"error": f"No video found for ID: {video_id}"}), 404

        video_data = doc.to_dict()
        image_urls = video_data.get('modelImages', [])

        if not image_urls or len(image_urls) < 3:
            return jsonify({
                "error": "modelImages missing or less than 3 images required"
            }), 400

        # Step 2: Send to Meshy AI
        payload = {
            "image_urls": image_urls,
            "should_remesh": True,
            "should_texture": True,
            "enable_pbr": True
        }

        print(f"Sending {len(image_urls)} images to Meshy AI...")
        response = requests.post(
            "https://api.meshy.ai/openapi/v1/multi-image-to-3d",
            headers=get_meshy_headers(),
            json=payload,
            timeout=30
        )
        response.raise_for_status()

        result = response.json()
        task_id = result.get('result')

        # Step 3: Update Firestore with job info
        doc_ref.update({
            "meshyJob": result,
            "meshyTaskId": task_id,
            "meshyStatus": "processing",
            "meshyRequestedAt": firestore.SERVER_TIMESTAMP,
            "userId": user_id
        })

        print(f"Meshy job created: {task_id}")

        return jsonify({
            "success": True,
            "task_id": task_id,
            "message": "3D model generation started",
            "result": result
        }), 200

    except requests.exceptions.RequestException as e:
        print(f"Meshy API Error: {e}")
        return jsonify({"error": f"Meshy API error: {str(e)}"}), 500
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/model-status/<task_id>', methods=['GET'])
def check_model_status(task_id):
    """
    Check the status of a Meshy AI generation task.
    """
    try:
        response = requests.get(
            f"https://api.meshy.ai/openapi/v1/multi-image-to-3d/{task_id}",
            headers=get_meshy_headers(),
            timeout=30
        )
        response.raise_for_status()
        
        model_info = response.json()
        status = model_info.get("status")
        progress = model_info.get("progress", 0)
        
        # Normalize status to lowercase for consistency
        status_normalized = status.lower() if status else "unknown"
        
        print(f"Task {task_id}: {status_normalized} ({progress}%)")

        return jsonify({
            "task_id": task_id,
            "status": status_normalized,
            "progress": progress,
            "model_info": model_info
        }), 200

    except requests.exceptions.RequestException as e:
        print(f"Status check error: {e}")
        return jsonify({"error": f"Failed to check status: {str(e)}"}), 500
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/fetch-model', methods=['POST'])
def fetch_generated_model():
    """
    Fetch the completed model from Meshy AI, upload to Supabase,
    and save metadata to Firestore.
    Expects JSON: { "task_id": "...", "user_id": "..." }
    """
    try:
        data = request.json
        task_id = data.get('task_id')
        user_id = data.get('user_id')

        if not task_id or not user_id:
            return jsonify({"error": "task_id and user_id are required"}), 400

        # Step 1: Fetch model info from Meshy
        print(f"Fetching model for task: {task_id}...")
        response = requests.get(
            f"https://api.meshy.ai/openapi/v1/multi-image-to-3d/{task_id}",
            headers=get_meshy_headers(),
            timeout=30
        )
        response.raise_for_status()
        model_info = response.json()

        # Check if succeeded
        if model_info.get("status") != "succeeded":
            return jsonify({
                "error": f"Model not ready yet: {model_info.get('status')}"
            }), 400

        # Get model URL
        model_file_url = model_info.get("model_url") or model_info.get("model", {}).get("url")

        if not model_file_url:
            return jsonify({"error": "No model URL found in Meshy response"}), 404

        # Step 2: Download GLB file
        print("Downloading .glb file...")
        tmp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".glb")
        model_data = requests.get(model_file_url, timeout=60)
        model_data.raise_for_status()
        tmp_file.write(model_data.content)
        tmp_file.close()

        # Step 3: Upload to Supabase
        filename = f"{task_id}.glb"
        print(f"Uploading to Supabase: {filename}...")
        
        with open(tmp_file.name, "rb") as f:
            supabase.storage.from_("models").upload(
                filename, 
                f, 
                {"content-type": "model/gltf-binary", "upsert": "true"}
            )

        # Step 4: Get public URL
        public_url = supabase.storage.from_("models").get_public_url(filename)
        print(f"Model public URL: {public_url}")

        # Step 5: Find the original video that this model was generated from
        video_query = db.collection("videos").where("meshyTaskId", "==", task_id).limit(1)
        video_docs = list(video_query.stream())
        video_id = video_docs[0].id if video_docs else None

        # Step 6: Save to Firestore
        model_doc = {
            "userId": user_id,
            "videoId": video_id,  # Link to the original video
            "taskId": task_id,
            "modelFileUrl": public_url,
            "source": "meshy",
            "status": "ready",
            "thumbnailUrl": model_info.get("thumbnail_url"),
            "videoUrl": model_info.get("video_url"),
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        }

        doc_ref = db.collection("generated_models_files").add(model_doc)
        print(f"Saved to Firestore: {doc_ref[1].id}")

        # Step 6: Cleanup
        os.remove(tmp_file.name)
        print("Temporary file removed")

        return jsonify({
            "success": True,
            "task_id": task_id,
            "model_public_url": public_url,
            "firestore_doc_id": doc_ref[1].id,
            "thumbnail_url": model_info.get("thumbnail_url"),
        }), 200

    except requests.exceptions.RequestException as e:
        print(f"Network Error: {e}")
        return jsonify({"error": f"Network error: {str(e)}"}), 500
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/models/list', methods=['GET'])
def list_available_models():
    """
    List all available 3D models from Firestore.
    Optional query params: user_id and video_id to filter by user or specific video.
    """
    try:
        user_id = request.args.get('user_id')
        video_id = request.args.get('video_id')

        query = db.collection("generated_models_files")
        
        if user_id:
            query = query.where("userId", "==", user_id)
        
        if video_id:
            query = query.where("videoId", "==", video_id)
        
        query = query.where("status", "==", "ready").order_by(
            "createdAt", 
            direction=firestore.Query.DESCENDING
        )

        docs = query.stream()
        
        models = []
        for doc in docs:
            model_data = doc.to_dict()
            model_data['id'] = doc.id
            models.append(model_data)

        return jsonify({
            "success": True,
            "count": len(models),
            "models": models
        }), 200

    except Exception as e:
        print(f"Error listing models: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/models/video/<video_id>', methods=['GET'])
def get_models_for_video(video_id):
    """
    Get all 3D models specifically for a video.
    Returns the models that can be displayed in AR for this video.
    """
    try:
        query = db.collection("generated_models_files").where("videoId", "==", video_id).where("status", "==", "ready")
        
        docs = query.stream()
        
        models = []
        for doc in docs:
            model_data = doc.to_dict()
            model_data['id'] = doc.id
            models.append(model_data)

        return jsonify({
            "success": True,
            "video_id": video_id,
            "count": len(models),
            "models": models
        }), 200

    except Exception as e:
        print(f"Error getting models for video {video_id}: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/stream-status/<task_id>', methods=['GET'])
def stream_model_status(task_id):
    """
    Stream real-time updates for model generation using SSE.
    """
    def generate():
        try:
            headers = get_meshy_headers()
            headers["Accept"] = "text/event-stream"
            
            response = requests.get(
                f'https://api.meshy.ai/openapi/v1/multi-image-to-3d/{task_id}/stream',
                headers=headers,
                stream=True,
                timeout=300
            )

            for line in response.iter_lines():
                if line:
                    if line.startswith(b'data:'):
                        data = json.loads(line.decode('utf-8')[5:])
                        yield f"data: {json.dumps(data)}\n\n"
                        
                        if data.get('status') in ['SUCCEEDED', 'FAILED', 'CANCELED']:
                            break

            response.close()
        except Exception as e:
            yield f"data: {json.dumps({'error': str(e)})}\n\n"

    return Response(
        generate(),
        mimetype='text/event-stream',
        headers={
            'Cache-Control': 'no-cache',
            'X-Accel-Buffering': 'no'
        }
    )


@app.route('/api/delete-model/<model_id>', methods=['DELETE'])
def delete_model(model_id):
    """
    Delete a 3D model from both Supabase and Firestore.
    """
    try:
        # Get model info from Firestore
        doc_ref = db.collection("generated_models_files").document(model_id)
        doc = doc_ref.get()

        if not doc.exists:
            return jsonify({"error": "Model not found"}), 404

        model_data = doc.to_dict()
        task_id = model_data.get('taskId')

        # Delete from Supabase storage
        if task_id:
            filename = f"{task_id}.glb"
            try:
                supabase.storage.from_("models").remove([filename])
                print(f"Deleted from Supabase: {filename}")
            except Exception as storage_error:
                print(f"Could not delete from Supabase: {storage_error}")

        # Delete from Firestore
        doc_ref.delete()
        print(f"Deleted from Firestore: {model_id}")

        return jsonify({
            "success": True,
            "message": "Model deleted successfully"
        }), 200

    except Exception as e:
        print(f"Delete error: {e}")
        return jsonify({"error": str(e)}), 500


@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    print("Starting Meshy AR Backend Server...")
    print("Server running on http://localhost:5000")
    print("Available endpoints:")
    print("  - GET  /api/health")
    print("  - POST /api/generate-3d")
    print("  - GET  /api/model-status/<task_id>")
    print("  - POST /api/fetch-model")
    print("  - GET  /api/models/list")
    print("  - GET  /api/stream-status/<task_id>")
    print("  - DELETE /api/delete-model/<model_id>")
    app.run(debug=True, host='0.0.0.0', port=5000)
    