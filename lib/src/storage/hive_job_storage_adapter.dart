import 'package:flutter_chunked_upload/src/storage/hive_init.dart';
import 'package:flutter_chunked_upload/src/storage/upload_job_storage_adapter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_chunked_upload/models/upload_job.dart';

class HiveUploadJobStorageAdapter implements UploadJobStorageAdapter {
  static const String boxName = 'upload_jobs';
  late final Box<UploadJob> _box;

  Future<void> init() async {
    await HiveStorageInitializer.initialize();
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<UploadJob>(boxName);
    } else {
      _box = Hive.box<UploadJob>(boxName);
    }
  }

  @override
  Future<void> saveJob(UploadJob job) async {
    await _box.put(job.id, job);
  }

  @override
  Future<void> deleteJob(String jobId) async {
    await _box.delete(jobId);
  }

  @override
  Future<List<UploadJob>> getAllJobs() async {
    return _box.values.toList();
  }

  @override
  Future<UploadJob?> getJob(String jobId) async {
    return _box.get(jobId);
  }

  @override
  Future<void> clearAllJobs() async {
    _box.clear();
  }

  @override
  Future<List<UploadJob>> getPausedJobs() async {
    return _box.values
        .where(
          (j) => j.isPaused,
        )
        .toList();
  }

  @override
  Future<List<UploadJob>> getPendingJobs() async {
    return _box.values
        .where(
          (j) => j.status != UploadJobStatus.success,
        )
        .toList();
  }

  @override
  Future<void> updateJob(String jobId, UploadJob job) async {
    _box.put(job.id, job);
  }
}
