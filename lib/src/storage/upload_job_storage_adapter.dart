import 'package:flutter_chunked_upload/models/upload_job.dart';

abstract class UploadJobStorageAdapter {
  Future<void> saveJob(UploadJob job);

  Future<void> updateJob(String jobId, UploadJob job);

  Future<void> deleteJob(String jobId);

  Future<void> clearAllJobs();

  Future<List<UploadJob>> getPendingJobs();

  Future<List<UploadJob>> getPausedJobs();

  Future<List<UploadJob>> getAllJobs();

  Future<UploadJob?> getJob(String jobId);
}
