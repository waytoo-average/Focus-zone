// --- New Download UI Components ---
import 'package:flutter/material.dart';
import '../../utils/download_manager_v2.dart';
import '../../../l10n/app_localizations.dart';

// --- Download Progress Card ---
class DownloadProgressCard extends StatelessWidget {
  final DownloadState state;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final String title;
  final String subtitle;
  final Color color;

  const DownloadProgressCard({
    super.key,
    required this.state,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Progress Section
            if (state.isActive || state.isPaused || state.hasError) ...[
              const SizedBox(height: 16),
              _buildProgressSection(context),
            ],

            // Controls Section
            if (state.canPause ||
                state.canResume ||
                state.canCancel ||
                state.canRetry) ...[
              const SizedBox(height: 16),
              _buildControlsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status and Progress Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getStatusText(s),
              style: TextStyle(
                fontSize: 14,
                color: _getStatusColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (state.isActive || state.isPaused)
              Text(
                '${(state.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Progress Bar
        if (state.isActive || state.isPaused)
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: theme.dividerColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),

        // Current File
        if (state.currentFile.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Current: ${state.currentFile}',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Error Message
        if (state.hasError && state.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlsSection(BuildContext context) {
    final s = AppLocalizations.of(context);

    return Row(
      children: [
        // Primary Action Button (Pause/Resume/Retry)
        if (state.canPause || state.canResume || state.canRetry) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.canPause
                  ? onPause
                  : state.canResume
                      ? onResume
                      : onRetry,
              icon: Icon(_getPrimaryActionIcon()),
              label: Text(_getPrimaryActionText(s)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getPrimaryActionColor(),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Cancel Button
        if (state.canCancel) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop),
              label: Text(s?.cancel ?? 'Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon() {
    if (state.hasError) return Icons.error_outline;
    if (state.isCompleted) return Icons.check_circle;
    if (state.isPaused) return Icons.pause_circle;
    if (state.isActive) return Icons.download;
    return Icons.download_outlined;
  }

  String _getStatusText(AppLocalizations? s) {
    if (state.hasError) return 'Download Error';
    if (state.isCompleted) return 'Download Completed';
    if (state.isPaused) return s?.pauseDownload ?? 'Download Paused';
    if (state.isActive) return s?.downloading ?? 'Downloading';
    return 'Ready to Download';
  }

  Color _getStatusColor(ThemeData theme) {
    if (state.hasError) return Colors.red;
    if (state.isCompleted) return Colors.green;
    if (state.isPaused) return Colors.orange;
    if (state.isActive) return theme.primaryColor;
    return theme.textTheme.bodyMedium?.color ?? Colors.grey;
  }

  IconData _getPrimaryActionIcon() {
    if (state.canPause) return Icons.pause;
    if (state.canResume) return Icons.play_arrow;
    if (state.canRetry) return Icons.refresh;
    return Icons.download;
  }

  String _getPrimaryActionText(AppLocalizations? s) {
    if (state.canPause) return s?.pauseDownload ?? 'Pause';
    if (state.canResume) return s?.resumeDownload ?? 'Resume';
    if (state.canRetry) return 'Retry';
    return 'Download';
  }

  Color _getPrimaryActionColor() {
    if (state.canPause) return Colors.orange;
    if (state.canResume) return Colors.green;
    if (state.canRetry) return Colors.blue;
    return Colors.blue;
  }
}

// --- Download Controls ---
class DownloadControls extends StatelessWidget {
  final bool isDownloading;
  final bool isPaused;
  final bool hasError;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;

  const DownloadControls({
    super.key,
    required this.isDownloading,
    required this.isPaused,
    required this.hasError,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);

    return Row(
      children: [
        // Primary Action Button
        if (isDownloading || isPaused || hasError) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isDownloading
                  ? onPause
                  : isPaused
                      ? onResume
                      : onRetry,
              icon: Icon(_getPrimaryIcon()),
              label: Text(_getPrimaryText(s)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getPrimaryColor(),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Cancel Button
        if (isDownloading || isPaused) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.stop),
              label: Text(s?.cancel ?? 'Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getPrimaryIcon() {
    if (isDownloading) return Icons.pause;
    if (isPaused) return Icons.play_arrow;
    if (hasError) return Icons.refresh;
    return Icons.download;
  }

  String _getPrimaryText(AppLocalizations? s) {
    if (isDownloading) return s?.pauseDownload ?? 'Pause';
    if (isPaused) return s?.resumeDownload ?? 'Resume';
    if (hasError) return 'Retry';
    return 'Download';
  }

  Color _getPrimaryColor() {
    if (isDownloading) return Colors.orange;
    if (isPaused) return Colors.green;
    if (hasError) return Colors.blue;
    return Colors.blue;
  }
}

// --- Download Status Indicator ---
class DownloadStatusIndicator extends StatelessWidget {
  final DownloadState state;
  final double size;

  const DownloadStatusIndicator({
    super.key,
    required this.state,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getIcon(),
        color: _getIconColor(),
        size: size * 0.6,
      ),
    );
  }

  Color _getBackgroundColor() {
    if (state.hasError) return Colors.red.shade100;
    if (state.isCompleted) return Colors.green.shade100;
    if (state.isPaused) return Colors.orange.shade100;
    if (state.isActive) return Colors.blue.shade100;
    return Colors.grey.shade100;
  }

  Color _getIconColor() {
    if (state.hasError) return Colors.red;
    if (state.isCompleted) return Colors.green;
    if (state.isPaused) return Colors.orange;
    if (state.isActive) return Colors.blue;
    return Colors.grey;
  }

  IconData _getIcon() {
    if (state.hasError) return Icons.error;
    if (state.isCompleted) return Icons.check;
    if (state.isPaused) return Icons.pause;
    if (state.isActive) return Icons.download;
    return Icons.download_outlined;
  }
}

// --- Download Error Widget ---
class DownloadErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const DownloadErrorWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null) ...[
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
          if (onDismiss != null) ...[
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: Colors.red.shade600, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}
