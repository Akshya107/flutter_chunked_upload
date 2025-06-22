import 'package:flutter/material.dart';
import 'package:flutter_chunked_upload/flutter_chunked_upload.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final queueManager = UploadQueueManager();
  await queueManager.initAsync();

  runApp(MyApp(queueManager: queueManager));
}

class MyApp extends StatelessWidget {
  final UploadQueueManager queueManager;

  const MyApp({super.key, required this.queueManager});

  String _getServerUrl() {
    // Use 10.0.2.2 for Android emulator to connect to host machine
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/upload';
    }
    // Use localhost for iOS simulator and other platforms
    return 'http://localhost:8000/upload';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chunked Upload Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Chunked Upload Example')),
        body: UploadJobsDebugPanel(queueManager: queueManager),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await FilePicker.platform
                .pickFiles(type: FileType.any, allowMultiple: false);
            if (result?.files.single.path != null) {
              final path = result!.files.single.path;
              final uploadId =
                  'test_upload_${DateTime.now().millisecondsSinceEpoch}';
              // Add a test job using the FastAPI backend
              final job = UploadJob(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                filePath: path!,
                url: _getServerUrl(),
                chunkSize: 1024 * 1024,
                // 1MB chunks
                headerBuilder: (chunkIndex, totalChunks) {
                  return {
                    'X-Chunk-Index': chunkIndex.toString(),
                    'X-Total-Chunks': totalChunks.toString(),
                    'X-Upload-ID': uploadId,
                    'X-Filename': path.split('/').last,
                    'Content-Type': 'application/octet-stream',
                  };
                },
                onProgress: (id, progress) {
                  debugPrint(
                      'Progress for $id: ${(progress * 100).toStringAsFixed(1)}%');
                },
                onComplete: (id) {
                  debugPrint('Upload completed: $id');
                  // Notifications are handled automatically by UploadQueueManager
                },
                onFailed: (id, error) {
                  debugPrint('Upload failed: $id - $error');
                  // Notifications are handled automatically by UploadQueueManager
                },
              );
              await queueManager.addToQueue(job);
            } else {
              debugPrint('No file selected.');
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
