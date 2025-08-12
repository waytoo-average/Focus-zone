import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app/app_core.dart';


class FeedbackCenterScreen extends StatelessWidget {
  const FeedbackCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.feedbackCenter),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(s.yourSuggestions),
              subtitle: Text(s.yourSuggestionsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserFeedbackListScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text(s.developerSuggestions),
              subtitle: Text(s.developerSuggestionsDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeveloperSuggestionsScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(s.userInfo),
              subtitle: Text(s.userInfoDesc),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _UserInfoContent(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DeveloperSuggestionsScreen extends StatelessWidget {
  const DeveloperSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.developerSuggestions)),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: DeveloperSuggestionsWidget(),
      ),
    );
  }
}

class DeveloperSuggestionsWidget extends StatefulWidget {
  const DeveloperSuggestionsWidget({super.key});

  @override
  State<DeveloperSuggestionsWidget> createState() => _DeveloperSuggestionsWidgetState();
}

class _DeveloperSuggestionsWidgetState extends State<DeveloperSuggestionsWidget> {
  List<Map<String, String>> _suggestions = [
    {
      'id': 'study_offline_mode',
      'title': '📚 Study Features',
      'content':
          '• Add offline mode for downloaded materials\n• Implement study timers and Pomodoro technique\n• Add note-taking feature for PDFs\n• Create study groups and sharing',
    },
    {
      'id': 'task_management_improvements',
      'title': '✅ Task Management',
      'content':
          '• Add task categories and tags\n• Implement recurring task patterns\n• Add task priority levels\n• Create task templates',
    },
    {
      'id': 'islamic_features',
      'title': '🕌 Islamic Features',
      'content':
          '• Add more Azkar categories\n• Implement prayer time notifications\n• Add Quran bookmarking\n• Create custom Azkar collections',
    },
    {
      'id': 'app_improvements',
      'title': '⚙️ App Improvements',
      'content':
          '• Add dark/light theme toggle\n• Implement backup and restore\n• Add data export features\n• Create widget for quick access',
    },
    {
      'id': 'ux_enhancements',
      'title': '📱 User Experience',
      'content':
          '• Add gesture navigation\n• Implement haptic feedback\n• Add accessibility features\n• Create onboarding tutorial',
    },
  ];

  Map<String, Map<String, int>> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final remote = await FeedbackManager.fetchSuggestions();
      if (remote.isNotEmpty) {
        _suggestions = remote
            .map((e) => {
                  'id': (e['id'] ?? '').toString(),
                  'title': (e['title'] ?? '').toString(),
                  'content': (e['content'] ?? '').toString(),
                })
            .toList();
      }
      _stats = await FeedbackManager.fetchSuggestionStats();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showAddCommentDialog(BuildContext context, String suggestionId) {
    final controller = TextEditingController();
    final s = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addComment),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: s.opinionHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final provider = Provider.of<DeveloperSuggestionsProvider>(
                    context,
                    listen: false);
                await provider.addComment(suggestionId, text);
                final ok = await FeedbackManager.addSuggestionComment(
                    suggestionId: suggestionId, content: text);
                if (ok) {
                  setState(() {
                    final m = _stats[suggestionId] ??= {
                      'likes': 0,
                      'dislikes': 0,
                      'comments': 0,
                    };
                    m['comments'] = (m['comments'] ?? 0) + 1;
                  });
                }
                if (context.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(s.save),
          )
        ],
      ),
    );
  }

  Future<void> _handleVote(
      BuildContext context, String suggestionId, int targetVote) async {
    final provider =
        Provider.of<DeveloperSuggestionsProvider>(context, listen: false);
    final previous = provider.stateFor(suggestionId).vote;
    await provider.setVote(suggestionId, targetVote);
    final current = provider.stateFor(suggestionId).vote;

    // Optimistically update counts
    setState(() {
      final m =
          _stats[suggestionId] ??= {'likes': 0, 'dislikes': 0, 'comments': 0};
      // apply transition previous -> current
      if (previous == 1) m['likes'] = (m['likes'] ?? 0) - 1;
      if (previous == -1) m['dislikes'] = (m['dislikes'] ?? 0) - 1;
      if (current == 1) m['likes'] = (m['likes'] ?? 0) + 1;
      if (current == -1) m['dislikes'] = (m['dislikes'] ?? 0) + 1;
    });

    final ok = await FeedbackManager.upsertVote(
        suggestionId: suggestionId, vote: current);
    if (!ok) {
      // revert
      await provider.setVote(suggestionId, previous);
      setState(() {
        final m =
            _stats[suggestionId] ??= {'likes': 0, 'dislikes': 0, 'comments': 0};
        if (current == 1) m['likes'] = (m['likes'] ?? 0) - 1;
        if (current == -1) m['dislikes'] = (m['dislikes'] ?? 0) - 1;
        if (previous == 1) m['likes'] = (m['likes'] ?? 0) + 1;
        if (previous == -1) m['dislikes'] = (m['dislikes'] ?? 0) + 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.feedbackError)),
        );
      }
    }
  }

  String _formatTimeAgo(BuildContext context, DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final provider = Provider.of<DeveloperSuggestionsProvider>(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          final id = item['id']!;
          final state = provider.stateFor(id);
          final counts =
              _stats[id] ?? {'likes': 0, 'dislikes': 0, 'comments': 0};

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']!,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['content']!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Row(
                            children: [
                              // Like with badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    tooltip: s.like,
                                    icon: Icon(
                                      Icons.thumb_up,
                                      color: state.vote == 1
                                          ? Theme.of(context)
                                              .colorScheme
                                              .secondary
                                          : Theme.of(context).hintColor,
                                    ),
                                    onPressed: () =>
                                        _handleVote(context, id, 1),
                                  ),
                                  if ((counts['likes'] ?? 0) > 0)
                                    Positioned(
                                      right: 0,
                                      top: -2,
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        child: Text(
                                          '${counts['likes'] ?? 0}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Dislike with badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    tooltip: s.dislike,
                                    icon: Icon(
                                      Icons.thumb_down,
                                      color: state.vote == -1
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context).hintColor,
                                    ),
                                    onPressed: () =>
                                        _handleVote(context, id, -1),
                                  ),
                                  if ((counts['dislikes'] ?? 0) > 0)
                                    Positioned(
                                      right: 0,
                                      top: -2,
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundColor:
                                            Theme.of(context).colorScheme.error,
                                        child: Text(
                                          '${counts['dislikes'] ?? 0}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              // Comment button with count badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    tooltip: s.addComment,
                                    icon: const Icon(Icons.comment_outlined),
                                    onPressed: () => _showAddCommentDialog(
                                      context,
                                      id,
                                    ),
                                  ),
                                  if ((counts['comments'] ?? 0) > 0)
                                    Positioned(
                                      right: 0,
                                      top: -2,
                                      child: CircleAvatar(
                                        radius: 9,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        child: Text(
                                          '${counts['comments'] ?? 0}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (state.comments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(s.recentComments,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...state.comments.take(3).map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.account_circle, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            c.content,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimeAgo(context,
                                              c.updatedAt ?? c.createdAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .hintColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserInfoContent extends StatefulWidget {
  const _UserInfoContent({super.key, this.onFinished});
  final VoidCallback? onFinished;

  @override
  State<_UserInfoContent> createState() => _UserInfoContentState();
}

class _UserInfoContentState extends State<_UserInfoContent> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Prefill from stored values if any
    final userInfo = Provider.of<UserInfoProvider>(context, listen: false);
    _nameController.text = userInfo.userName ?? '';
    _phoneController.text = userInfo.userPhone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    setState(() => _isSubmitting = true);
    final userInfoProvider =
        Provider.of<UserInfoProvider>(context, listen: false);
    await userInfoProvider.setUserInfo(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    );
    if (!userInfoProvider.hasSeenUserInfoScreen) {
      await userInfoProvider.markUserInfoScreenSeen();
    }
    setState(() => _isSubmitting = false);
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final hasSeen =
        Provider.of<UserInfoProvider>(context).hasSeenUserInfoScreen;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.enterYourInfo,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                labelText: s.name,
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                labelText: s.phoneNumber,
                prefixIcon: const Icon(Icons.phone_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleContinue,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(hasSeen ? s.save : s.continue_),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final userInfoProvider = Provider.of<UserInfoProvider>(
                            context,
                            listen: false);
                        if (!userInfoProvider.hasSeenUserInfoScreen) {
                          await userInfoProvider.markUserInfoScreenSeen();
                        }
                        widget.onFinished?.call();
                      },
                child: Text(hasSeen ? s.close : s.skip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserFeedbackListScreen extends StatelessWidget {
  const UserFeedbackListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.yourSuggestions),
      ),
      body: Consumer<UserFeedbackProvider>(
        builder: (context, provider, _) {
          if (provider.feedbackItems.isEmpty) {
            return Center(
              child: Text(
                s.noRecentFiles, // reuse a neutral string if no specific one
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.feedbackItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = provider.feedbackItems[index];
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(
                  item.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.submittedAt.toLocal()}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubmitFeedbackScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SubmitFeedbackScreen extends StatefulWidget {
  const SubmitFeedbackScreen({super.key});

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = AppLocalizations.of(context)!;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.feedbackEmpty), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      // Submit to backend
      final userInfo = Provider.of<UserInfoProvider>(context, listen: false);
      final ok = await FeedbackManager.submitFeedback(
        type: 'general_${DateTime.now().millisecondsSinceEpoch}',
        content: text,
        name: userInfo.userName,
        phone: userInfo.userPhone,
      );
      if (ok) {
        // Store locally
        await Provider.of<UserFeedbackProvider>(context, listen: false)
            .addFeedback(text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(s.feedbackSubmitted),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.feedbackError), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.yourSuggestions)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: s.suggestionHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.submitSuggestion),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FeedbackFormWidget extends StatefulWidget {
  final String type;
  final String hintText;
  final String submitButtonText;

  const FeedbackFormWidget({
    super.key,
    required this.type,
    required this.hintText,
    required this.submitButtonText,
  });

  @override
  State<FeedbackFormWidget> createState() => _FeedbackFormWidgetState();
}

class _FeedbackFormWidgetState extends State<FeedbackFormWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.feedbackEmpty),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userInfoProvider =
          Provider.of<UserInfoProvider>(context, listen: false);
      final success = await FeedbackManager.submitFeedback(
        type: widget.type,
        content: _controller.text.trim(),
        name: userInfoProvider.userName,
        phone: userInfoProvider.userPhone,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.feedbackSubmitted),
              backgroundColor: Colors.green,
            ),
          );
          _controller.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.feedbackError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.feedbackError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitButtonText),
        ),
      ],
    );
  }
}

class FeedbackManager {
  static const String _baseUrl = 'https://vqxvkpbbwssywdntitjf.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxeHZrcGJid3NzeXdkbnRpdGpmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1NDI0NTgsImV4cCI6MjA3MDExODQ1OH0.PyKwaRT1RLYE4KhYYV-nzPMWiKDaXXokUf_HpnnZSCs';

  // ---- Device ID ----
  static const String _deviceIdKey = 'device_id';
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    // Lightweight ID generator: timestamp + random
    final millis = DateTime.now().millisecondsSinceEpoch;
    final r = (millis * 2654435761) ^ (millis >> 7);
    final id = 'dev_${millis.toRadixString(36)}_${r.toRadixString(36)}';
    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  // ---- Feedback submission (existing) ----
  static Future<bool> submitFeedback({
    required String type,
    required String content,
    String? name,
    String? phone,
  }) async {
    try {
      // Get app version and device info
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      String deviceInfoString = 'Unknown';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceInfoString = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceInfoString = '${iosInfo.name} ${iosInfo.model}';
      }

      final deviceId = await getDeviceId();

      final Map<String, dynamic> payload = {
        'type': type,
        'content': content,
        'app_version': packageInfo.version,
        'device_info': deviceInfoString,
        'device_id': deviceId,
        'submitted_at': DateTime.now().toIso8601String(),
      };
      if (name != null && name.isNotEmpty) payload['name'] = name;
      if (phone != null && phone.isNotEmpty) payload['phone_number'] = phone;

      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/feedback'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
            'Error submitting feedback: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception submitting feedback: $e');
      return false;
    }
  }

  // ---- Developer Suggestions API ----
  static Future<List<Map<String, dynamic>>> fetchSuggestions() async {
    final uri = Uri.parse(
        '$_baseUrl/rest/v1/developer_suggestions?select=id,title,content,active&active=is.true&order=created_at.asc');
    final res = await http.get(uri, headers: {
      'apikey': _anonKey,
      'Authorization': 'Bearer $_anonKey',
    });
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    print('fetchSuggestions failed: ${res.statusCode} - ${res.body}');
    return [];
  }

  static Future<Map<String, Map<String, int>>> fetchSuggestionStats() async {
    // returns: { suggestionId: { likes: n, dislikes: n, comments: n } }
    final uri =
        Uri.parse('$_baseUrl/rest/v1/developer_suggestion_stats?select=*');
    final res = await http.get(uri, headers: {
      'apikey': _anonKey,
      'Authorization': 'Bearer $_anonKey',
    });
    final Map<String, Map<String, int>> result = {};
    if (res.statusCode == 200) {
      final List<dynamic> list = jsonDecode(res.body) as List<dynamic>;
      for (final row in list) {
        final m = row as Map<String, dynamic>;
        final id = m['suggestion_id'] as String?;
        if (id == null) continue;
        result[id] = {
          'likes': (m['likes_count'] as num?)?.toInt() ?? 0,
          'dislikes': (m['dislikes_count'] as num?)?.toInt() ?? 0,
          'comments': (m['comments_count'] as num?)?.toInt() ?? 0,
        };
      }
    } else {
      print('fetchSuggestionStats failed: ${res.statusCode} - ${res.body}');
    }
    return result;
  }

  static Future<bool> upsertVote({
    required String suggestionId,
    required int vote, // -1,0,1
  }) async {
    try {
      final deviceId = await getDeviceId();
      final uri = Uri.parse(
          '$_baseUrl/rest/v1/suggestion_votes?on_conflict=suggestion_id,device_id');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'suggestion_id': suggestionId,
          'device_id': deviceId,
          'vote': vote,
        }),
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      print('upsertVote error: $e');
      return false;
    }
  }

  static Future<bool> addSuggestionComment({
    required String suggestionId,
    required String content,
  }) async {
    try {
      final deviceId = await getDeviceId();
      final uri = Uri.parse('$_baseUrl/rest/v1/suggestion_comments');
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'apikey': _anonKey,
          'Authorization': 'Bearer $_anonKey',
        },
        body: jsonEncode({
          'suggestion_id': suggestionId,
          'device_id': deviceId,
          'content': content,
        }),
      );
      return res.statusCode == 201;
    } catch (e) {
      print('addSuggestionComment error: $e');
      return false;
    }
  }
}
