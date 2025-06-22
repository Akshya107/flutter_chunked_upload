import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chunked_upload/models/upload_job.dart';
import 'package:flutter_chunked_upload/services/notification_service.dart';
import 'package:flutter_chunked_upload/services/connectivity_service.dart';
import 'package:flutter_chunked_upload/src/chunked_uploader.dart';
import 'package:flutter_chunked_upload/src/storage/hive_job_storage_adapter.dart';
import 'package:flutter_chunked_upload/src/storage/hive_storage_adapter.dart';
import 'package:flutter_chunked_upload/src/storage/upload_job_storage_adapter.dart';
import 'package:flutter_chunked_upload/src/storage/upload_storage_adapter.dart';
import 'package:hive/hive.dart';

class UploadQueueManager {
  static final UploadQueueManager _instance = UploadQueueManager._internal();

  factory UploadQueueManager() => _instance;

  UploadQueueManager._internal();

  final PriorityQueue<UploadJob> _queue = PriorityQueue(
    (a, b) => b.priority.compareTo(a.priority),
  );
  final Set<String> _cancelledJobs = {};
  final StreamController<UploadJob> _jobUpdateController =
      StreamController.broadcast();

  Stream<UploadJob> get jobUpdateStream => _jobUpdateController.stream;
  bool _isUploading = false;
  late final ChunkedUploader _uploader;
  late final UploadJobStorageAdapter _jobStorage;
  late final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  Future<void> initAsync(
      {UploadStorageAdapter? chunkStorage,
      UploadJobStorageAdapter? jobStorage,
      bool restore = true}) async {
    _uploader = ChunkedUploader(storage: chunkStorage ?? HiveStorageAdapter());
    await _uploader.init();
    _jobStorage = jobStorage ?? HiveUploadJobStorageAdapter();

    // Initialize job storage if it's Hive-based
    if (_jobStorage is HiveUploadJobStorageAdapter) {
      await _jobStorage.init();
    }

    await NotificationService().init();

    // Initialize connectivity service
    _connectivityService = ConnectivityService();
    await _connectivityService.init();
    _setupConnectivityListener();

    if (restore) restorePendingJobs();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription =
        _connectivityService.connectivityStream.listen((isConnected) {
      if (isConnected) {
        debugPrint('[UploadQueue] Internet restored - resuming uploads');
        _resumeAllPausedJobs();
      } else {
        debugPrint('[UploadQueue] Internet lost - pausing uploads');
        _pauseAllActiveJobs();
      }
    });
  }

  void _pauseAllActiveJobs() async {
    final activeJobs = await _jobStorage.getPendingJobs();
    for (final job in activeJobs) {
      if (job.status == UploadJobStatus.uploading && !job.isPaused) {
        job.isPaused = true;
        job.isManuallyPaused = false;
        job.status = UploadJobStatus.pending;
        await _jobStorage.updateJob(job.id, job);
        _jobUpdateController.add(job);
        debugPrint('[UploadQueue] Auto-paused job: ${job.id}');
      }
    }
  }

  void _resumeAllPausedJobs() async {
    final pausedJobs = await _jobStorage.getPausedJobs();
    for (final job in pausedJobs) {
      if (job.isPaused && !job.isManuallyPaused) {
        job.isPaused = false;
        job.status = UploadJobStatus.pending;
        await _jobStorage.updateJob(job.id, job);
        _jobUpdateController.add(job);
        addToQueue(job);
        debugPrint('[UploadQueue] Auto-resumed job: ${job.id}');
      }
    }
  }

  Future<void> _processQueue() async {
    if (_isUploading || _queue.isEmpty) return;

    // Check connectivity before processing
    if (!_connectivityService.isConnected) {
      debugPrint(
          '[UploadQueue] No internet connection - skipping queue processing');
      return;
    }

    _isUploading = true;

    while (_queue.isNotEmpty) {
      // Check connectivity before each job
      if (!_connectivityService.isConnected) {
        debugPrint(
            '[UploadQueue] Internet lost during processing - pausing queue');
        _isUploading = false;
        return;
      }

      final job = _queue.removeFirst();

      // Check if job was cancelled
      if (_cancelledJobs.contains(job.id)) {
        debugPrint('[UploadQueue] Skipping cancelled job: ${job.id}');
        _cancelledJobs.remove(job.id);
        continue;
      }

      // Check if job is paused
      if (job.isPaused) {
        _queue.add(job);
        await Future.delayed(
            const Duration(milliseconds: 100)); // avoid tight loop
        continue;
      }

      job.status = UploadJobStatus.uploading;
      _jobUpdateController.add(job);

      try {
        await _uploader.uploadFile(
          job: job,
          isCancelled: () => _cancelledJobs.contains(job.id),
          isPaused: () => job.isPaused || !_connectivityService.isConnected,
        );

        // Check if job was cancelled during upload
        if (_cancelledJobs.contains(job.id)) {
          debugPrint('[UploadQueue] Job cancelled during upload: ${job.id}');
          _cancelledJobs.remove(job.id);
          continue;
        }

        // Check if job was paused during upload (including connectivity loss)
        if (job.isPaused || !_connectivityService.isConnected) {
          debugPrint('[UploadQueue] Job paused during upload: ${job.id}');
          _queue.add(job); // Re-add to queue for later processing
          continue;
        }

        job.status = UploadJobStatus.success;
        await NotificationService().showUploadSuccessNotification(job.id);
        _jobUpdateController.add(job);
        _jobStorage.deleteJob(job.id);
        _cancelledJobs.remove(job.id);
        job.onComplete?.call(job.id);
      } catch (e) {
        // Check if job was cancelled during error handling
        if (_cancelledJobs.contains(job.id)) {
          debugPrint(
              '[UploadQueue] Job cancelled during error handling: ${job.id}');
          _cancelledJobs.remove(job.id);
          continue;
        }

        job.retryCount++;
        debugPrint('[UploadQueue] Failed: ${job.id} -> $e');
        if (job.retryCount <= job.maxRetries) {
          final delay = Duration(seconds: 1 << (job.retryCount - 1));
          debugPrint('Retrying ${job.id} in ${delay.inSeconds}s...');
          await Future.delayed(delay);
          await NotificationService()
              .showUploadFailedAndRetryNotification(job.id);
          _queue.add(job);
          _cancelledJobs.remove(job.id);
          await _jobStorage.updateJob(job.id, job);
          _jobUpdateController.add(job);
        } else {
          await NotificationService().showUploadFailedNotification(job.id);
          job.status = UploadJobStatus.failed;
          _jobUpdateController.add(job);
          await _jobStorage.updateJob(job.id, job);
          _cancelledJobs.remove(job.id);
          job.onFailed?.call(job.id, e);

          debugPrint('Upload permanently failed: ${job.id}');
        }
      }
    }
    _isUploading = false;
  }

  Future<void> addToQueue(UploadJob job) async {
    _queue.add(job);
    await _jobStorage.updateJob(job.id, job);
    await _processQueue();
  }

  void restorePendingJobs() async {
    final jobs = await getPendingJobs();
    _queue.addAll(jobs);
    _processQueue();
  }

  void pauseJob(String jobId) async {
    debugPrint('Attempting to pause job: $jobId');

    // Check if job is currently being processed
    final currentJob = _queue.toList().firstWhereOrNull((j) => j.id == jobId);
    if (currentJob != null) {
      currentJob.isPaused = true;
      currentJob.isManuallyPaused = true;
      currentJob.status = UploadJobStatus.pending;
      _jobUpdateController.add(currentJob);
      await _jobStorage.updateJob(jobId, currentJob);
      debugPrint('Job manually paused (from queue): $jobId');
      return;
    }

    // Check stored job
    final storedJob = await _jobStorage.getJob(jobId);
    if (storedJob != null) {
      storedJob.isPaused = true;
      storedJob.isManuallyPaused = true;
      storedJob.status = UploadJobStatus.pending;
      await _jobStorage.updateJob(jobId, storedJob);
      _jobUpdateController.add(storedJob);
      debugPrint('Job manually paused (from storage): $jobId');
    } else {
      debugPrint('Job not found for pause: $jobId');
    }
  }

  void resumeJob(String jobId) async {
    debugPrint('Attempting to resume job: $jobId');

    final job = await _jobStorage.getJob(jobId);
    if (job != null && job.status != UploadJobStatus.success) {
      job.isPaused = false;
      job.isManuallyPaused = false;
      job.status = UploadJobStatus.pending;
      await _jobStorage.updateJob(jobId, job);
      _jobUpdateController.add(job);
      addToQueue(job);
      debugPrint('Job manually resumed: $jobId');
    } else {
      debugPrint('Job not found or cannot resume: $jobId');
    }
  }

  void cancelJob(String jobId) async {
    debugPrint('Attempting to cancel job: $jobId');

    // Add to cancelled set to stop current processing
    _cancelledJobs.add(jobId);

    // Remove from queue if present
    final queuedJob = _queue.toList().firstWhereOrNull((j) => j.id == jobId);
    if (queuedJob != null) {
      _queue.remove(queuedJob);
      debugPrint('Job removed from queue: $jobId');
    }

    // Update stored job status
    final storedJob = await _jobStorage.getJob(jobId);
    if (storedJob != null) {
      storedJob.status = UploadJobStatus.failed;
      await _jobStorage.updateJob(jobId, storedJob);
      _jobUpdateController.add(storedJob);
      debugPrint('Job marked as cancelled: $jobId');
    }

    // Clean up storage
    await _jobStorage.deleteJob(jobId);
    debugPrint('Job cancelled and cleaned up: $jobId');
  }

  void clearAllJobs() {
    _queue.clear();
    _jobStorage.clearAllJobs();
  }

  Future<List<UploadJob>> getPendingJobs() async {
    return await _jobStorage.getPendingJobs();
  }

  Future<List<UploadJob>> getPausedJobs() async {
    return _jobStorage.getPausedJobs();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    _jobUpdateController.close();
    _queue.clear();
    _cancelledJobs.clear();

    // Close Hive boxes if using Hive adapters
    if (_jobStorage is HiveUploadJobStorageAdapter) {
      Hive.box('upload_jobs').close();
    }
    Hive.box('chunked_uploads').close();
  }
}
