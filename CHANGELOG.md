# Changelog

## [1.0.2] - 2025-06-22

### Added
- Added demo GIFs to `README.md` to showcase the package in action.

## [1.0.1] - 2025-06-22

### Fixed
- Shortened the package description in `pubspec.yaml` to meet pub.dev's recommended length for better package scoring.

## [1.0.0] - 2025-06-22

### Added
- Initial release of flutter_chunked_upload package
- Chunked file upload functionality with resume capability
- Upload queue management with priority support
- Progress tracking and real-time updates
- Pause/resume/cancel functionality
- Persistent storage using Hive
- Automatic retry logic with exponential backoff
- Local notifications for upload status
- Cross-platform support (Android, iOS)
- Debug panel widget for monitoring uploads
- Comprehensive API documentation and examples

### Features
- `UploadJob` model with full Hive persistence
- `UploadQueueManager` singleton for queue management
- `ChunkedUploader` for handling file uploads
- `UploadJobsDebugPanel` for UI monitoring
- `NotificationService` for status notifications
- Custom storage adapters support
- Header builder for custom chunk headers
- Progress and status callbacks

### Technical Details
- Uses Hive for persistent storage
- Implements proper error handling
- Supports custom chunk sizes
- Configurable retry limits
- Priority-based queue ordering
- Memory-efficient chunk reading
- Background isolate support for uploads
