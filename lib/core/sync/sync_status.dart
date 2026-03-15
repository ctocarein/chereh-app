/// État de synchronisation offline/online.
enum SyncStatus { idle, syncing, error }

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
}
