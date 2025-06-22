import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chunked_upload/models/upload_job.dart';

void main() {
  group('Simple Unit Tests', () {
    test('UploadJobStatus enum values', () {
      expect(UploadJobStatus.values.length, equals(4));
      expect(UploadJobStatus.pending.name, equals('pending'));
      expect(UploadJobStatus.uploading.name, equals('uploading'));
      expect(UploadJobStatus.success.name, equals('success'));
      expect(UploadJobStatus.failed.name, equals('failed'));
    });

    test('UploadJob constructor with defaults', () {
      final job = UploadJob(
        id: 'test_id',
        filePath: '/test/path',
        url: 'https://test.com',
      );

      expect(job.id, equals('test_id'));
      expect(job.filePath, equals('/test/path'));
      expect(job.url, equals('https://test.com'));
      expect(job.status, equals(UploadJobStatus.pending));
      expect(job.chunkSize, equals(1024 * 1024)); // 1MB default
      expect(job.retryCount, equals(0));
      expect(job.maxRetries, equals(3));
      expect(job.isPaused, isFalse);
      expect(job.priority, equals(0));
      expect(job.progress, equals(0.0));
    });

    test('UploadJob JSON serialization', () {
      final job = UploadJob(
        id: 'json_test',
        filePath: '/test/file.txt',
        url: 'https://api.test.com/upload',
        chunkSize: 2048 * 1024,
        status: UploadJobStatus.uploading,
      );

      final json = job.toJson();
      expect(json['id'], equals('json_test'));
      expect(json['filePath'], equals('/test/file.txt'));
      expect(json['url'], equals('https://api.test.com/upload'));
      expect(json['chunkSize'], equals(2048 * 1024));
      expect(json['status'], equals('uploading'));
    });

    test('UploadJob JSON deserialization', () {
      final json = {
        'id': 'from_json',
        'filePath': '/test/file.pdf',
        'url': 'https://api.test.com/upload',
        'chunkSize': 512 * 1024,
        'status': 'failed',
      };

      final job = UploadJob.fromJson(json);
      expect(job.id, equals('from_json'));
      expect(job.filePath, equals('/test/file.pdf'));
      expect(job.url, equals('https://api.test.com/upload'));
      expect(job.chunkSize, equals(512 * 1024));
      expect(job.status, equals(UploadJobStatus.failed));
    });

    test('UploadJob with custom parameters', () {
      final job = UploadJob(
        id: 'custom_job',
        filePath: '/custom/path',
        url: 'https://custom.com',
        chunkSize: 4096 * 1024, // 4MB
        priority: 8,
        maxRetries: 5,
        status: UploadJobStatus.success,
        isPaused: true,
        isManuallyPaused: true,
      );

      expect(job.chunkSize, equals(4096 * 1024));
      expect(job.priority, equals(8));
      expect(job.maxRetries, equals(5));
      expect(job.status, equals(UploadJobStatus.success));
      expect(job.isPaused, isTrue);
      expect(job.isManuallyPaused, isTrue);
    });

    test('UploadJob progress updates', () {
      final job = UploadJob(
        id: 'progress_test',
        filePath: '/test/path',
        url: 'https://test.com',
      );

      expect(job.progress, equals(0.0));

      job.progress = 0.5;
      expect(job.progress, equals(0.5));

      job.progress = 1.0;
      expect(job.progress, equals(1.0));
    });

    test('UploadJob status transitions', () {
      final job = UploadJob(
        id: 'status_test',
        filePath: '/test/path',
        url: 'https://test.com',
      );

      expect(job.status, equals(UploadJobStatus.pending));

      job.status = UploadJobStatus.uploading;
      expect(job.status, equals(UploadJobStatus.uploading));

      job.status = UploadJobStatus.success;
      expect(job.status, equals(UploadJobStatus.success));

      job.status = UploadJobStatus.failed;
      expect(job.status, equals(UploadJobStatus.failed));
    });

    test('UploadJob retry count', () {
      final job = UploadJob(
        id: 'retry_test',
        filePath: '/test/path',
        url: 'https://test.com',
      );

      expect(job.retryCount, equals(0));

      job.retryCount++;
      expect(job.retryCount, equals(1));

      job.retryCount = 3;
      expect(job.retryCount, equals(3));
    });

    test('UploadJob pause/resume', () {
      final job = UploadJob(
        id: 'pause_test',
        filePath: '/test/path',
        url: 'https://test.com',
      );

      expect(job.isPaused, isFalse);
      expect(job.isManuallyPaused, isFalse);

      job.isPaused = true;
      job.isManuallyPaused = true;
      expect(job.isPaused, isTrue);
      expect(job.isManuallyPaused, isTrue);

      job.isPaused = false;
      job.isManuallyPaused = false;
      expect(job.isPaused, isFalse);
      expect(job.isManuallyPaused, isFalse);
    });

    test('UploadJob priority levels', () {
      final lowPriority = UploadJob(
        id: 'low',
        filePath: '/test/path',
        url: 'https://test.com',
        priority: 1,
      );

      final highPriority = UploadJob(
        id: 'high',
        filePath: '/test/path',
        url: 'https://test.com',
        priority: 9,
      );

      expect(lowPriority.priority, equals(1));
      expect(highPriority.priority, equals(9));
      expect(highPriority.priority > lowPriority.priority, isTrue);
    });

    test('UploadJob callback functions', () {
      bool progressCalled = false;
      bool completeCalled = false;
      bool failedCalled = false;

      final job = UploadJob(
        id: 'callback_test',
        filePath: '/test/path',
        url: 'https://test.com',
        onProgress: (id, progress) {
          progressCalled = true;
          expect(id, equals('callback_test'));
          expect(progress, equals(0.75));
        },
        onComplete: (id) {
          completeCalled = true;
          expect(id, equals('callback_test'));
        },
        onFailed: (id, error) {
          failedCalled = true;
          expect(id, equals('callback_test'));
          expect(error, equals('Test error'));
        },
      );

      // Test callbacks
      job.onProgress?.call(job.id, 0.75);
      job.onComplete?.call(job.id);
      job.onFailed?.call(job.id, 'Test error');

      expect(progressCalled, isTrue);
      expect(completeCalled, isTrue);
      expect(failedCalled, isTrue);
    });

    test('UploadJob header builder', () {
      final job = UploadJob(
        id: 'header_test',
        filePath: '/test/path',
        url: 'https://test.com',
        headerBuilder: (chunkIndex, totalChunks) {
          return {
            'X-Chunk-Index': chunkIndex.toString(),
            'X-Total-Chunks': totalChunks.toString(),
            'Content-Type': 'application/octet-stream',
            'Authorization': 'Bearer token123',
          };
        },
      );

      final headers = job.headerBuilder?.call(3, 10);

      expect(headers, isNotNull);
      expect(headers!['X-Chunk-Index'], equals('3'));
      expect(headers['X-Total-Chunks'], equals('10'));
      expect(headers['Content-Type'], equals('application/octet-stream'));
      expect(headers['Authorization'], equals('Bearer token123'));
    });
  });
}
