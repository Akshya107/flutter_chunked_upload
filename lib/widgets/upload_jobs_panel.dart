import 'package:flutter/material.dart';
import 'package:flutter_chunked_upload/models/upload_job.dart';
import 'package:flutter_chunked_upload/src/upload_queue_manager.dart';
import 'package:rxdart/rxdart.dart';

class UploadJobsDebugPanel extends StatefulWidget {
  final UploadQueueManager queueManager;

  const UploadJobsDebugPanel({
    super.key,
    required this.queueManager,
  });

  @override
  State<UploadJobsDebugPanel> createState() => _UploadJobsDebugPanelState();
}

class _UploadJobsDebugPanelState extends State<UploadJobsDebugPanel> {
  late Stream<List<UploadJob>> _jobsStream;
  final dummyJob = UploadJob(
    id: 'init',
    filePath: '',
    url: '',
    priority: 0,
    status: UploadJobStatus.pending,
  );

  @override
  void initState() {
    super.initState();

    _jobsStream = widget.queueManager.jobUpdateStream
        .startWith(dummyJob)
        .asyncMap((_) async => widget.queueManager.getPendingJobs());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UploadJob>>(
      stream: _jobsStream,
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? [];

        if (jobs.isEmpty) {
          return const Center(child: Text('No upload jobs'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final job = jobs[index];
            return UploadJobCard(
              job: job,
              onPause: () => widget.queueManager.pauseJob(job.id),
              onResume: () => widget.queueManager.resumeJob(job.id),
              onCancel: () => widget.queueManager.cancelJob(job.id),
            );
          },
        );
      },
    );
  }
}

class UploadJobCard extends StatelessWidget {
  final UploadJob job;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const UploadJobCard({
    super.key,
    required this.job,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  Color _priorityColor(int priority) {
    if (priority >= 8) return Colors.red;
    if (priority >= 5) return Colors.orange;
    return Colors.green;
  }

  String _priorityText(int priority) {
    if (priority >= 8) return 'High';
    if (priority >= 5) return 'Medium';
    return 'Low';
  }

  String _statusText(UploadJobStatus status) {
    switch (status) {
      case UploadJobStatus.pending:
        return 'Pending';
      case UploadJobStatus.uploading:
        return 'Uploading';
      case UploadJobStatus.success:
        return 'Success';
      case UploadJobStatus.failed:
        return 'Failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _extractProgress(job);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Priority badge + Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.id,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(job.priority).withValues(red: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _priorityText(job.priority),
                    style: TextStyle(
                      color: _priorityColor(job.priority),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _statusText(job.status),
                  style: TextStyle(
                    color: job.status == UploadJobStatus.failed
                        ? Colors.red
                        : (job.status == UploadJobStatus.success
                            ? Colors.green
                            : Colors.grey[700]),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: job.status == UploadJobStatus.failed
                  ? Colors.red
                  : Colors.blue,
              minHeight: 8,
            ),

            const SizedBox(height: 8),

            // Action buttons: Pause / Resume / Cancel
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (job.status == UploadJobStatus.uploading &&
                    !job.isPaused) ...[
                  TextButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                ] else if ((job.status == UploadJobStatus.pending ||
                        job.isPaused) &&
                    job.status != UploadJobStatus.success) ...[
                  TextButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                ],
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style:
                      TextButton.styleFrom(foregroundColor: Colors.redAccent),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Try to extract progress from the job, fallback to 0 if unknown
  double _extractProgress(UploadJob job) {
    // Use the progress value stored in the job
    return job.progress;
  }
}
