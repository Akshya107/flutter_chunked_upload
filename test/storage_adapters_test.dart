import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chunked_upload/models/upload_job.dart';
import 'package:flutter_chunked_upload/src/storage/upload_job_storage_adapter.dart';
import 'package:flutter_chunked_upload/src/storage/upload_storage_adapter.dart';

// Mock implementations for testing
class MockJobStorageAdapter implements UploadJobStorageAdapter {
  final Map<String, UploadJob> _jobs = {};

  @override
  Future<void> saveJob(UploadJob job) async {
    _jobs[job.id] = job;
  }

  @override
  Future<void> updateJob(String jobId, UploadJob job) async {
    _jobs[jobId] = job;
  }

  @override
  Future<void> deleteJob(String jobId) async {
    _jobs.remove(jobId);
  }

  @override
  Future<void> clearAllJobs() async {
    _jobs.clear();
  }

  @override
  Future<List<UploadJob>> getPendingJobs() async {
    return _jobs.values
        .where((job) => job.status != UploadJobStatus.success)
        .toList();
  }

  @override
  Future<List<UploadJob>> getPausedJobs() async {
    return _jobs.values.where((job) => job.isPaused).toList();
  }

  @override
  Future<List<UploadJob>> getAllJobs() async {
    return _jobs.values.toList();
  }

  @override
  Future<UploadJob?> getJob(String jobId) async {
    return _jobs[jobId];
  }
}

class MockStorageAdapter implements UploadStorageAdapter {
  final Map<String, int> _progress = {};

  @override
  Future<void> saveProgress(String uploadId, int lastUploadedChunk) async {
    _progress[uploadId] = lastUploadedChunk;
  }

  @override
  Future<int> getLastUploadedChunk(String uploadId) async {
    return _progress[uploadId] ?? 0;
  }

  @override
  Future<void> removeProgress(String uploadId) async {
    _progress.remove(uploadId);
  }
}

void main() {
  group('UploadJobStorageAdapter', () {
    late MockJobStorageAdapter storage;

    setUp(() {
      storage = MockJobStorageAdapter();
    });

    test('should save and retrieve job', () async {
      final job = UploadJob(
        id: 'test_job_1',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
      );

      await storage.saveJob(job);
      final retrievedJob = await storage.getJob('test_job_1');

      expect(retrievedJob, isNotNull);
      expect(retrievedJob!.id, equals('test_job_1'));
      expect(retrievedJob.filePath, equals('/path/to/file.txt'));
    });

    test('should update existing job', () async {
      final job = UploadJob(
        id: 'test_job_2',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
      );

      await storage.saveJob(job);

      // Update the job
      job.status = UploadJobStatus.uploading;
      job.progress = 0.5;
      await storage.updateJob('test_job_2', job);

      final updatedJob = await storage.getJob('test_job_2');
      expect(updatedJob!.status, equals(UploadJobStatus.uploading));
      expect(updatedJob.progress, equals(0.5));
    });

    test('should delete job', () async {
      final job = UploadJob(
        id: 'test_job_3',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
      );

      await storage.saveJob(job);
      await storage.deleteJob('test_job_3');

      final deletedJob = await storage.getJob('test_job_3');
      expect(deletedJob, isNull);
    });

    test('should clear all jobs', () async {
      final job1 = UploadJob(
        id: 'test_job_4',
        filePath: '/path/to/file1.txt',
        url: 'https://api.example.com/upload',
      );

      final job2 = UploadJob(
        id: 'test_job_5',
        filePath: '/path/to/file2.txt',
        url: 'https://api.example.com/upload',
      );

      await storage.saveJob(job1);
      await storage.saveJob(job2);

      await storage.clearAllJobs();

      final allJobs = await storage.getAllJobs();
      expect(allJobs.length, equals(0));
    });

    test('should get pending jobs', () async {
      final pendingJob = UploadJob(
        id: 'pending_job',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
        status: UploadJobStatus.pending,
      );

      final completedJob = UploadJob(
        id: 'completed_job',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
        status: UploadJobStatus.success,
      );

      await storage.saveJob(pendingJob);
      await storage.saveJob(completedJob);

      final pendingJobs = await storage.getPendingJobs();
      expect(pendingJobs.length, equals(1));
      expect(pendingJobs.first.id, equals('pending_job'));
    });

    test('should get paused jobs', () async {
      final pausedJob = UploadJob(
        id: 'paused_job',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
        isPaused: true,
      );

      final activeJob = UploadJob(
        id: 'active_job',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
        isPaused: false,
      );

      await storage.saveJob(pausedJob);
      await storage.saveJob(activeJob);

      final pausedJobs = await storage.getPausedJobs();
      expect(pausedJobs.length, equals(1));
      expect(pausedJobs.first.id, equals('paused_job'));
    });

    test('should return null for non-existent job', () async {
      final job = await storage.getJob('non_existent');
      expect(job, isNull);
    });
  });

  group('UploadStorageAdapter', () {
    late MockStorageAdapter storage;

    setUp(() {
      storage = MockStorageAdapter();
    });

    test('should save and retrieve progress', () async {
      await storage.saveProgress('test_upload_1', 5);
      final progress = await storage.getLastUploadedChunk('test_upload_1');
      expect(progress, equals(5));
    });

    test('should return default value for non-existent progress', () async {
      final progress = await storage.getLastUploadedChunk('non_existent');
      expect(progress, equals(0));
    });

    test('should remove progress', () async {
      await storage.saveProgress('test_upload_2', 10);
      await storage.removeProgress('test_upload_2');

      final progress = await storage.getLastUploadedChunk('test_upload_2');
      expect(progress, equals(0)); // Default value after removal
    });

    test('should handle multiple progress entries', () async {
      await storage.saveProgress('upload_1', 3);
      await storage.saveProgress('upload_2', 7);
      await storage.saveProgress('upload_3', 12);

      expect(await storage.getLastUploadedChunk('upload_1'), equals(3));
      expect(await storage.getLastUploadedChunk('upload_2'), equals(7));
      expect(await storage.getLastUploadedChunk('upload_3'), equals(12));
    });

    test('should handle zero progress', () async {
      await storage.saveProgress('test_upload_3', 0);
      final progress = await storage.getLastUploadedChunk('test_upload_3');
      expect(progress, equals(0));
    });

    test('should handle large progress values', () async {
      await storage.saveProgress('test_upload_4', 999999);
      final progress = await storage.getLastUploadedChunk('test_upload_4');
      expect(progress, equals(999999));
    });
  });
}
