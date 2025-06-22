<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# flutter_chunked_upload

A Flutter package for handling chunked file uploads with resume capability, progress tracking, and queue management.

## 🚀 Demo

| Android Demo | iOS Demo |
| :---: | :---: |
| <img src="media/android_demo.gif" alt="Android Demo" width="300"/> | <img src="media/ios_demo.gif" alt="iOS Demo" width="300"/> |

## 🌟 Features

- **Chunked File Uploads**: Split large files into manageable chunks for reliable uploads
- **Resume Capability**: Automatically resume uploads from where they left off
- **Queue Management**: Manage multiple uploads with priority support
- **Progress Tracking**: Real-time progress updates with callbacks
- **Pause/Resume/Cancel**: Full control over upload operations
- **Automatic Connectivity Handling**: Pause uploads when internet is lost, resume when restored
- **Persistent Storage**: Upload progress saved using Hive for app restarts
- **Cross-Platform**: Works on iOS, Android, Web, and Desktop
- **Backend Agnostic**: Works with any server that supports chunked uploads
- **Notifications**: Built-in success, retry, and failure notifications
- **Error Handling**: Comprehensive error handling with automatic retries

## Getting started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_chunked_upload: ^1.0.0
```

### Dependencies

This package requires the following dependencies:

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  http: ^1.4.0
  path_provider: ^2.1.5
  flutter_local_notifications: ^19.2.1
  rxdart: ^0.28.0
  collection: ^1.19.0
```

## Usage

### Basic Setup

```dart
import 'package:flutter_chunked_upload/flutter_chunked_upload.dart';

// Initialize the upload queue manager
final queueManager = UploadQueueManager();
await queueManager.initAsync();
```

### Creating Upload Jobs

```dart
// Create an upload job
final job = UploadJob(
  id: 'unique_job_id',
  filePath: '/path/to/your/file.mp4',
  url: 'https://api.example.com/upload',
  chunkSize: 1024 * 1024, // 1MB chunks
  priority: 5, // Higher number = higher priority
  onProgress: (id, progress) {
    print('Upload $id progress: ${(progress * 100).toStringAsFixed(1)}%');
  },
  onComplete: (id) {
    print('Upload $id completed successfully!');
  },
  onFailed: (id, error) {
    print('Upload $id failed: $error');
  },
  headerBuilder: (chunkIndex, totalChunks) {
    // Custom headers for each chunk
    return {
      'Content-Type': 'application/octet-stream',
      'X-Chunk-Index': chunkIndex.toString(),
      'X-Total-Chunks': totalChunks.toString(),
    };
  },
);

// Add to queue
await queueManager.addToQueue(job);
```

### 🔄 Automatic Connectivity Handling

The package automatically handles internet connectivity changes:

- **Internet Lost**: All active uploads are automatically paused
- **Internet Restored**: All paused uploads are automatically resumed
- **No Manual Intervention**: Works seamlessly in the background
- **Progress Preserved**: No data loss during connectivity changes

```dart
// The connectivity handling is automatic - no additional code needed!
// Uploads will pause when internet is lost and resume when restored
```

### Managing Uploads

```dart
// Pause an upload
queueManager.pauseJob('job_id');

// Resume an upload
queueManager.resumeJob('job_id');

// Cancel an upload
queueManager.cancelJob('job_id');

// Get all pending jobs
final pendingJobs = await queueManager.getPendingJobs();

// Get paused jobs
final pausedJobs = await queueManager.getPausedJobs();

// Clear all jobs
queueManager.clearAllJobs();
```

### Using the Debug Panel

```dart
import 'package:flutter/material.dart';
import 'package:flutter_chunked_upload/flutter_chunked_upload.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Upload Manager')),
        body: UploadJobsDebugPanel(), // Shows all upload jobs with controls
      ),
    );
  }
}
```

### Custom Storage Adapters

You can implement custom storage adapters for different persistence needs:

```dart
class CustomJobStorageAdapter implements UploadJobStorageAdapter {
  // Implement the required methods
  @override
  Future<void> saveJob(UploadJob job) async {
    // Your custom implementation
  }
  
  // ... implement other methods
}

// Use custom adapters
await queueManager.initAsync(
  jobStorage: CustomJobStorageAdapter(),
  chunkStorage: CustomChunkStorageAdapter(),
);
```

## API Reference

### UploadJob

The main class representing an upload job.

```dart
class UploadJob {
  String id;                    // Unique identifier
  String filePath;              // Path to file
  String url;                   // Upload endpoint
  int chunkSize;                // Size of each chunk
  UploadJobStatus status;       // Current status
  int retryCount;               // Number of retries
  int maxRetries;               // Maximum retries
  bool isPaused;                // Pause state
  int priority;                 // Queue priority
  double progress;              // Upload progress (0.0-1.0)
  
  // Callbacks
  ProgressCallback? onProgress;
  UploadCompleteCallback? onComplete;
  UploadFailedCallback? onFailed;
  HeaderBuilder? headerBuilder;
}
```

### UploadJobStatus

```dart
enum UploadJobStatus {
  pending,    // Waiting in queue
  uploading,  // Currently uploading
  success,    // Upload completed
  failed,     // Upload failed
}
```

### UploadQueueManager

Singleton class for managing upload queue.

```dart
class UploadQueueManager {
  // Initialize the manager
  Future<void> initAsync({...});
  
  // Queue management
  Future<void> addToQueue(UploadJob job);
  void pauseJob(String jobId);
  void resumeJob(String jobId);
  void cancelJob(String jobId);
  
  // Query methods
  Future<List<UploadJob>> getPendingJobs();
  Future<List<UploadJob>> getPausedJobs();
  
  // Cleanup
  void clearAllJobs();
  void dispose();
}
```

## Configuration

### Chunk Size

Choose appropriate chunk sizes based on your needs:

- **Small files (< 10MB)**: 512KB chunks
- **Medium files (10MB - 100MB)**: 1MB chunks  
- **Large files (> 100MB)**: 2-5MB chunks

### Retry Configuration

```dart
final job = UploadJob(
  // ... other properties
  maxRetries: 5, // Increase for unreliable networks
  retryCount: 0, // Start with 0
);
```

### Priority Levels

- **0-2**: Low priority
- **3-7**: Medium priority  
- **8-10**: High priority

## Error Handling

The package handles various error scenarios:

- **File not found**: Throws `FileSystemException`
- **Network errors**: Automatic retry with exponential backoff
- **Server errors**: Retry based on HTTP status codes
- **Storage errors**: Graceful degradation

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web (with limitations)
- ❌ Desktop (not tested)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
