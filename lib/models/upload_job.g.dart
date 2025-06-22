// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_job.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UploadJobAdapter extends TypeAdapter<UploadJob> {
  @override
  final int typeId = 0;

  @override
  UploadJob read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UploadJob(
      id: fields[0] as String,
      filePath: fields[1] as String,
      url: fields[2] as String,
      chunkSize: fields[3] as int,
      maxRetries: fields[6] as int,
      retryCount: fields[5] as int,
      status: fields[4] as UploadJobStatus,
      priority: fields[8] as int,
      isPaused: fields[7] as bool? ?? false,
      isManuallyPaused: fields[10] as bool? ?? false,
    )..progress = fields[9] as double? ?? 0.0;
  }

  @override
  void write(BinaryWriter writer, UploadJob obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.chunkSize)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.maxRetries)
      ..writeByte(7)
      ..write(obj.isPaused)
      ..writeByte(10)
      ..write(obj.isManuallyPaused)
      ..writeByte(8)
      ..write(obj.priority)
      ..writeByte(9)
      ..write(obj.progress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadJobAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UploadJobStatusAdapter extends TypeAdapter<UploadJobStatus> {
  @override
  final int typeId = 1;

  @override
  UploadJobStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UploadJobStatus.pending;
      case 1:
        return UploadJobStatus.uploading;
      case 2:
        return UploadJobStatus.success;
      case 3:
        return UploadJobStatus.failed;
      default:
        return UploadJobStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, UploadJobStatus obj) {
    switch (obj) {
      case UploadJobStatus.pending:
        writer.writeByte(0);
        break;
      case UploadJobStatus.uploading:
        writer.writeByte(1);
        break;
      case UploadJobStatus.success:
        writer.writeByte(2);
        break;
      case UploadJobStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UploadJobStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
