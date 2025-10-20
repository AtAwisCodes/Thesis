import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rexplore/services/meshy_api_service.dart';
import 'package:rexplore/augmented_reality/augmented_camera.dart';
import 'dart:async';

/// Widget that shows 3D model generation status for a video
/// Automatically opens AR camera when model is ready
class ModelStatusWidget extends StatefulWidget {
  final String videoId;
  final bool autoOpenAR;

  const ModelStatusWidget({
    super.key,
    required this.videoId,
    this.autoOpenAR = false,
  });

  @override
  State<ModelStatusWidget> createState() => _ModelStatusWidgetState();
}

class _ModelStatusWidgetState extends State<ModelStatusWidget> {
  StreamSubscription? _videoSubscription;
  Timer? _pollingTimer;

  bool _has3DModel = false;
  String? _modelUrl;
  String? _taskId;
  String? _meshyStatus;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _listenToVideoChanges();
  }

  void _listenToVideoChanges() {
    // Listen to real-time updates from Firestore
    _videoSubscription = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.videoId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      setState(() {
        _has3DModel = data['has3DModel'] ?? false;
        _modelUrl = data['generatedModelUrl'];
        _taskId = data['meshyTaskId'];
        _meshyStatus = data['meshyStatus'];
      });

      // If model just became ready and autoOpenAR is enabled
      if (_has3DModel && _modelUrl != null && widget.autoOpenAR) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openARCamera();
        });
      }

      // Start polling if processing
      if (_meshyStatus == 'processing' && _taskId != null) {
        _startPolling();
      } else {
        _stopPolling();
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_taskId == null) {
        timer.cancel();
        return;
      }

      try {
        final statusData = await MeshyApiService.checkModelStatus(_taskId!);
        final status = statusData['status']?.toString().toLowerCase();
        final progress = statusData['progress'] ?? 0;

        if (mounted) {
          setState(() {
            _progress = progress;
          });
        }

        print('📊 Model status for ${widget.videoId}: $status ($progress%)');

        // Status is checked by backend auto-fetch, but we track progress here
        if (status == 'succeeded' || status == 'failed') {
          timer.cancel();
        }
      } catch (e) {
        print('Error polling status: $e');
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _openARCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeshyARCamera(videoId: widget.videoId),
      ),
    );
  }

  @override
  void dispose() {
    _videoSubscription?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Model is ready
    if (_has3DModel && _modelUrl != null) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: const Icon(
            Icons.view_in_ar,
            color: Colors.green,
            size: 32,
          ),
          title: const Text(
            '3D Model Ready!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Tap to view in Augmented Reality'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _openARCamera,
        ),
      );
    }

    // Model is processing
    if (_meshyStatus == 'processing') {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Generating 3D Model...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '$_progress%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take 2-5 minutes. You can close this page.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Model generation failed
    if (_meshyStatus == 'failed') {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          leading: const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          title: const Text(
            '3D Model Generation Failed',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Please try uploading again with better images'),
        ),
      );
    }

    // No model data
    return const SizedBox.shrink();
  }
}
