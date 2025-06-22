import 'package:hive/hive.dart';

part 'upload_job.g.dart';

/// Status of an upload job
@HiveType(typeId: 1)
enum UploadJobStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  uploading,
  @HiveField(2)
  success,
  @HiveField(3)
  failed,
}

/// Function type for building custom headers for each chunk
typedef HeaderBuilder = Map<String, String> Function(
    int chunkIndex, int totalChunks);

/// Callback function for upload progress updates
typedef ProgressCallback = void Function(String uploadId, double progress);

/// Callback function for successful upload completion
typedef UploadCompleteCallback = void Function(String uploadId);

/// Callback function for upload failures
typedef UploadFailedCallback = void Function(String uploadId, Object error);

/// Represents a file upload job with chunked upload support
///
/// This class contains all the information needed to upload a file in chunks,
/// including file path, upload URL, chunk size, and various callbacks for
/// progress tracking and status updates.
@HiveType(typeId: 0)
class UploadJob extends HiveObject {
  /// Unique identifier for the upload job
  @HiveField(0)
  String id;

  /// Path to the file to be uploaded
  @HiveField(1)
  String filePath;

  /// URL where the file chunks will be uploaded
  @HiveField(2)
  String url;

  /// Size of each chunk in bytes (default: 1MB)
  @HiveField(3)
  int chunkSize;

  /// Current status of the upload job
  @HiveField(4)
  UploadJobStatus status;

  /// Number of retry attempts made for this job
  @HiveField(5)
  int retryCount = 0;

  /// Maximum number of retry attempts before marking as failed
  @HiveField(6)
  int maxRetries = 3;

  /// Whether the job is currently paused
  @HiveField(7)
  bool isPaused = false;

  /// Whether the job was manually paused by the user (vs automatically paused due to connectivity loss)
  @HiveField(10)
  bool isManuallyPaused = false;

  /// Priority level for queue ordering (higher = higher priority)
  @HiveField(8)
  int priority;

  /// Current upload progress (0.0 to 1.0)
  @HiveField(9)
  double progress = 0.0;

  /// Optional function to build custom headers for each chunk
  HeaderBuilder? headerBuilder;

  /// Callback function for progress updates
  ProgressCallback? onProgress;

  /// Callback function for successful completion
  UploadCompleteCallback? onComplete;

  /// Callback function for failures
  UploadFailedCallback? onFailed;

  /// Creates a new upload job
  ///
  /// [id] must be unique across all upload jobs
  /// [filePath] must point to an existing file
  /// [url] is the endpoint where chunks will be uploaded
  /// [chunkSize] determines how the file is split (default: 1MB)
  /// [priority] affects queue ordering (default: 0)
  /// [maxRetries] sets retry limit (default: 3)
  UploadJob(
      {required this.id,
      required this.filePath,
      required this.url,
      this.chunkSize = 1024 * 1024,
      this.headerBuilder,
      this.onProgress,
      this.maxRetries = 3,
      this.retryCount = 0,
      this.status = UploadJobStatus.pending,
      this.onComplete,
      this.onFailed,
      this.priority = 0,
      this.isPaused = false,
      this.isManuallyPaused = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'url': url,
        'chunkSize': chunkSize,
        'status': status.name,
      };

  factory UploadJob.fromJson(Map<String, dynamic> json) => UploadJob(
        id: json['id'],
        filePath: json['filePath'],
        url: json['url'],
        chunkSize: json['chunkSize'],
        status: UploadJobStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => UploadJobStatus.pending,
        ),
      );
}
