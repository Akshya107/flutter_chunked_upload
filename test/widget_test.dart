import 'package:flutter/material.dart';
import 'package:flutter_chunked_upload/flutter_chunked_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

// Mock UploadQueueManager for testing
class MockUploadQueueManager implements UploadQueueManager {
  final StreamController<UploadJob> _jobUpdateController =
      StreamController.broadcast();
  final List<UploadJob> _mockJobs = [];

  @override
  Stream<UploadJob> get jobUpdateStream => _jobUpdateController.stream;

  void addMockJob(UploadJob job) {
    _mockJobs.add(job);
    _jobUpdateController.add(job);
  }

  @override
  Future<List<UploadJob>> getPendingJobs() async {
    return _mockJobs;
  }

  @override
  Future<List<UploadJob>> getPausedJobs() async {
    return _mockJobs.where((job) => job.isPaused).toList();
  }

  @override
  void pauseJob(String jobId) {
    final job = _mockJobs.firstWhere((j) => j.id == jobId);
    job.isPaused = true;
    job.isManuallyPaused = true;
    job.status = UploadJobStatus.pending;
    _jobUpdateController.add(job);
  }

  @override
  void resumeJob(String jobId) {
    final job = _mockJobs.firstWhere((j) => j.id == jobId);
    job.isPaused = false;
    job.isManuallyPaused = false;
    job.status = UploadJobStatus.pending;
    _jobUpdateController.add(job);
  }

  @override
  void cancelJob(String jobId) {
    final job = _mockJobs.firstWhere((j) => j.id == jobId);
    job.status = UploadJobStatus.failed;
    _jobUpdateController.add(job);
  }

  // Implement other required methods with empty implementations
  @override
  Future<void> addToQueue(UploadJob job) async {}
  @override
  void restorePendingJobs() {}
  @override
  void clearAllJobs() {}
  @override
  void dispose() {
    _jobUpdateController.close();
  }

  @override
  Future<void> initAsync(
      {UploadStorageAdapter? chunkStorage,
      UploadJobStorageAdapter? jobStorage,
      bool restore = true}) async {}
}

void main() {
  group('UploadJobsDebugPanel', () {
    late MockUploadQueueManager mockQueueManager;

    setUp(() {
      mockQueueManager = MockUploadQueueManager();
    });

    tearDown(() {
      mockQueueManager.dispose();
    });

    testWidgets('should render without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UploadJobsDebugPanel(queueManager: mockQueueManager),
          ),
        ),
      );

      // Should render without throwing
      expect(find.byType(UploadJobsDebugPanel), findsOneWidget);
    });

    testWidgets('should show "No upload jobs" when empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UploadJobsDebugPanel(queueManager: mockQueueManager),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Should show the "No upload jobs" message
      expect(find.text('No upload jobs'), findsOneWidget);
    });

    testWidgets('should handle different job statuses',
        (WidgetTester tester) async {
      // Add a mock job
      final mockJob = UploadJob(
        id: 'test-job',
        filePath: '/test/path',
        url: 'https://example.com/upload',
        priority: 5,
        status: UploadJobStatus.uploading,
      );
      mockQueueManager.addMockJob(mockJob);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UploadJobsDebugPanel(queueManager: mockQueueManager),
          ),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Should render without errors and show the job
      expect(find.byType(UploadJobsDebugPanel), findsOneWidget);
      expect(find.text('test-job'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget); // Priority text
      expect(find.text('Uploading'), findsOneWidget); // Status text
    });
  });
}
