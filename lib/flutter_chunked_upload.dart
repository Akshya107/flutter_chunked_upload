/// A Flutter package for handling chunked file uploads with resume capability,
/// progress tracking, and queue management.
///
/// This package provides:
/// - Chunked file uploads with automatic resume on failure
/// - Upload queue management with priority support
/// - Progress tracking and notifications
/// - Persistent storage using Hive
/// - Pause/resume/cancel functionality
///
/// ## Usage
///
/// ```dart
/// import 'package:flutter_chunked_upload/flutter_chunked_upload.dart';
///
/// // Initialize the upload queue manager
/// final queueManager = UploadQueueManager();
/// await queueManager.initAsync();
///
/// // Create an upload job
/// final job = UploadJob(
///   id: 'unique_job_id',
///   filePath: '/path/to/file',
///   url: 'https://api.example.com/upload',
///   chunkSize: 1024 * 1024, // 1MB chunks
///   priority: 5,
///   onProgress: (id, progress) => print('Progress: $progress'),
///   onComplete: (id) => print('Upload complete: $id'),
///   onFailed: (id, error) => print('Upload failed: $id - $error'),
/// );
///
/// // Add to queue
/// await queueManager.addToQueue(job);
/// ```
library;

// Export public models
export 'models/upload_job.dart';

// Export public services
export 'services/notification_service.dart';
export 'services/connectivity_service.dart';

// Export public widgets
export 'widgets/upload_jobs_panel.dart';

// Export core functionality
export 'src/chunked_uploader.dart';
export 'src/upload_queue_manager.dart';

// Export storage adapters
export 'src/storage/upload_job_storage_adapter.dart';
export 'src/storage/upload_storage_adapter.dart';
export 'src/storage/hive_job_storage_adapter.dart';
export 'src/storage/hive_storage_adapter.dart';
