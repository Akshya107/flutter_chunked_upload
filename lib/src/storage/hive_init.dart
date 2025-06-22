import 'package:flutter_chunked_upload/models/upload_job.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class HiveStorageInitializer {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
    Hive.registerAdapter(UploadJobAdapter());
    Hive.registerAdapter(UploadJobStatusAdapter());

    _initialized = true;
  }
}
