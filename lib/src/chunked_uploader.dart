import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_chunked_upload/models/upload_job.dart';
import 'package:flutter_chunked_upload/src/storage/hive_init.dart';
import 'package:flutter_chunked_upload/src/storage/hive_storage_adapter.dart';
import 'package:flutter_chunked_upload/src/storage/upload_storage_adapter.dart';
import 'package:http/http.dart' as http;

///This fn runs in a separate isolate using compute
Future<bool> _uploadChunkInBG(Map<String, dynamic> args) async {
  final url = args['uploadUrl'] as String;
  final chunk = args['chunk'] as List<int>;
  final headers = Map<String, String>.from(args['headers'] as Map);
  final response =
      await http.post(Uri.parse(url), headers: headers, body: chunk);
  return response.statusCode == 200 || response.statusCode == 206;
}

class ChunkedUploader {
  late final UploadStorageAdapter _storage;

  ChunkedUploader({UploadStorageAdapter? storage})
      : _storage = storage ?? HiveStorageAdapter();

  Future<void> init() async {
    await HiveStorageInitializer.initialize();
    if (_storage is HiveStorageAdapter) {
      await (_storage).init();
    }
  }

  /// Upload file in chunks.
  Future<void> uploadFile(
      {required UploadJob job,
      bool Function()? isCancelled,
      bool Function()? isPaused}) async {
    final file = File(job.filePath);

    // Check if file exists
    if (!await file.exists()) {
      throw FileSystemException('File not found', job.filePath);
    }

    final totalSize = await file.length();
    final totalChunks = (totalSize / job.chunkSize).ceil();
    final startChunk = await _storage.getLastUploadedChunk(job.id);
    debugPrint('Resuming upload from chunk: $startChunk');

    for (int chunkIndex = startChunk; chunkIndex < totalChunks; chunkIndex++) {
      // Check for cancellation
      if (isCancelled?.call() ?? false) {
        debugPrint('[Uploader] Cancelled upload for: ${job.id}');
        return;
      }

      // Check for pause - if paused, save progress and exit
      if (isPaused?.call() ?? false) {
        debugPrint(
            '[Uploader] Paused upload for: ${job.id} at chunk: $chunkIndex');
        await _storage.saveProgress(job.id, chunkIndex);
        return;
      }

      try {
        final start = chunkIndex * job.chunkSize;
        final end = (start + job.chunkSize > totalSize)
            ? totalSize
            : start + job.chunkSize;
        final chunk = await _readChunk(file, start, end);

        // Check again for pause/cancel before uploading chunk
        if (isCancelled?.call() ?? false) {
          debugPrint('[Uploader] Cancelled upload for: ${job.id}');
          return;
        }
        if (isPaused?.call() ?? false) {
          debugPrint(
              '[Uploader] Paused upload for: ${job.id} at chunk: $chunkIndex');
          await _storage.saveProgress(job.id, chunkIndex);
          return;
        }

        final success = await _uploadChunk(
            uploadUrl: job.url,
            chunk: chunk,
            chunkIndex: chunkIndex,
            totalChunks: totalChunks,
            buildHeaders: job.headerBuilder);
        if (success) {
          final percent = ((chunkIndex + 1) / totalChunks);
          job.progress = percent;
          job.onProgress?.call(job.id, percent);
          debugPrint("Uploaded chunk ${chunkIndex + 1}/$totalChunks");
          await _storage.saveProgress(job.id, chunkIndex + 1);
        } else {
          debugPrint('Failed to upload chunk $chunkIndex');
          throw Exception('Failed to upload chunk $chunkIndex');
        }
      } catch (e) {
        debugPrint('Error uploading chunk $chunkIndex: $e');
        throw Exception('Error uploading chunk $chunkIndex: $e');
      }
    }
    debugPrint('Upload complete, clearing state.');
    await _storage.removeProgress(job.id);
  }

  /// Read a chunk from the file between byte offsets
  Future<List<int>> _readChunk(File file, int start, int end) async {
    final stream = file.openRead(start, end);
    final bytes = <int>[];
    await for (final data in stream) {
      bytes.addAll(data);
    }
    return bytes;
  }

  /// Uploads a chunk to the server
  Future<bool> _uploadChunk({
    required String uploadUrl,
    required List<int> chunk,
    required int chunkIndex,
    required int totalChunks,
    HeaderBuilder? buildHeaders,
  }) async {
    final headers = buildHeaders?.call(chunkIndex, totalChunks) ?? {};
    return await compute(_uploadChunkInBG,
        {'uploadUrl': uploadUrl, 'chunk': chunk, 'headers': headers});
  }
}
