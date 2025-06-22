abstract class UploadStorageAdapter {
  Future<void> saveProgress(String uploadId, int lastUploadedChunk);

  Future<int> getLastUploadedChunk(String uploadId);

  Future<void> removeProgress(String uploadId);
}
