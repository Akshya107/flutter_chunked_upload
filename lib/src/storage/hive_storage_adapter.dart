import 'package:flutter_chunked_upload/src/storage/hive_init.dart';
import 'package:flutter_chunked_upload/src/storage/upload_storage_adapter.dart';
import 'package:hive/hive.dart';

class HiveStorageAdapter extends UploadStorageAdapter {
  static const _boxName = 'chunked_uploads';
  late Box<int> _box;

  Future<void> init() async {
    await HiveStorageInitializer.initialize();
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<int>(_boxName);
    } else {
      _box = Hive.box<int>(_boxName);
    }
  }

  @override
  Future<void> saveProgress(String uploadId, int lastUploadedChunk) async {
    await _box.put(uploadId, lastUploadedChunk);
  }

  @override
  Future<int> getLastUploadedChunk(String uploadId) async {
    return _box.get(uploadId, defaultValue: 0)!;
  }

  @override
  Future<void> removeProgress(String uploadId) async {
    await _box.delete(uploadId);
  }
}
