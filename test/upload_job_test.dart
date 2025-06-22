import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chunked_upload/models/upload_job.dart';

void main() {
  group('UploadJob', () {
    test('should create UploadJob with required parameters', () {
      final job = UploadJob(
        id: 'test_job_1',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
      );

      expect(job.id, equals('test_job_1'));
      expect(job.filePath, equals('/path/to/file.txt'));
      expect(job.url, equals('https://api.example.com/upload'));
      expect(job.status, equals(UploadJobStatus.pending));
      expect(job.chunkSize, equals(1024 * 1024)); // Default 1MB
      expect(job.retryCount, equals(0));
      expect(job.maxRetries, equals(3));
      expect(job.isPaused, isFalse);
      expect(job.priority, equals(0));
      expect(job.progress, equals(0.0));
    });

    test('should create UploadJob with custom parameters', () {
      final job = UploadJob(
        id: 'test_job_2',
        filePath: '/path/to/file.mp4',
        url: 'https://api.example.com/upload',
        chunkSize: 2048 * 1024, // 2MB chunks
        priority: 8,
        maxRetries: 5,
        status: UploadJobStatus.uploading,
        isPaused: true,
      );

      expect(job.chunkSize, equals(2048 * 1024));
      expect(job.priority, equals(8));
      expect(job.maxRetries, equals(5));
      expect(job.status, equals(UploadJobStatus.uploading));
      expect(job.isPaused, isTrue);
      expect(job.progress, equals(0.0)); // Default value
    });

    test('should convert to JSON correctly', () {
      final job = UploadJob(
        id: 'test_job_3',
        filePath: '/path/to/file.pdf',
        url: 'https://api.example.com/upload',
        chunkSize: 512 * 1024,
        status: UploadJobStatus.success,
      );

      final json = job.toJson();

      expect(json['id'], equals('test_job_3'));
      expect(json['filePath'], equals('/path/to/file.pdf'));
      expect(json['url'], equals('https://api.example.com/upload'));
      expect(json['chunkSize'], equals(512 * 1024));
      expect(json['status'], equals('success'));
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': 'test_job_4',
        'filePath': '/path/to/file.jpg',
        'url': 'https://api.example.com/upload',
        'chunkSize': 1024 * 1024,
        'status': 'failed',
      };

      final job = UploadJob.fromJson(json);

      expect(job.id, equals('test_job_4'));
      expect(job.filePath, equals('/path/to/file.jpg'));
      expect(job.url, equals('https://api.example.com/upload'));
      expect(job.chunkSize, equals(1024 * 1024));
      expect(job.status, equals(UploadJobStatus.failed));
    });

    test('should handle unknown status in fromJson', () {
      final json = {
        'id': 'test_job_5',
        'filePath': '/path/to/file.txt',
        'url': 'https://api.example.com/upload',
        'chunkSize': 1024 * 1024,
        'status': 'unknown_status',
      };

      final job = UploadJob.fromJson(json);

      expect(job.status, equals(UploadJobStatus.pending)); // Default fallback
    });

    test('should handle callbacks', () {
      bool progressCalled = false;
      bool completeCalled = false;
      bool failedCalled = false;

      final job = UploadJob(
        id: 'test_job_6',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
        onProgress: (id, progress) {
          progressCalled = true;
          expect(id, equals('test_job_6'));
          expect(progress, equals(0.75));
        },
        onComplete: (id) {
          completeCalled = true;
          expect(id, equals('test_job_6'));
        },
        onFailed: (id, error) {
          failedCalled = true;
          expect(id, equals('test_job_6'));
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

    test('should handle header builder', () {
      final job = UploadJob(
        id: 'test_job_7',
        filePath: '/path/to/file.txt',
        url: 'https://api.example.com/upload',
        headerBuilder: (chunkIndex, totalChunks) {
          return {
            'X-Chunk-Index': chunkIndex.toString(),
            'X-Total-Chunks': totalChunks.toString(),
            'Content-Type': 'application/octet-stream',
          };
        },
      );

      final headers = job.headerBuilder?.call(2, 10);

      expect(headers, isNotNull);
      expect(headers!['X-Chunk-Index'], equals('2'));
      expect(headers['X-Total-Chunks'], equals('10'));
      expect(headers['Content-Type'], equals('application/octet-stream'));
    });
  });

  group('UploadJobStatus', () {
    test('should have correct enum values', () {
      expect(UploadJobStatus.pending, isNotNull);
      expect(UploadJobStatus.uploading, isNotNull);
      expect(UploadJobStatus.success, isNotNull);
      expect(UploadJobStatus.failed, isNotNull);
    });

    test('should have correct string representations', () {
      expect(UploadJobStatus.pending.name, equals('pending'));
      expect(UploadJobStatus.uploading.name, equals('uploading'));
      expect(UploadJobStatus.success.name, equals('success'));
      expect(UploadJobStatus.failed.name, equals('failed'));
    });
  });
}
