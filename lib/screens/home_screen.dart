import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../sync/powersync_client.dart';
import '../utils/utils.dart';
import 'data_collection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, Object?>> feedbackList = [];
  bool _isOnline = true;
  bool _shouldReloadOnReconnect = false;
  bool _isLoading = false;

  late final StreamSubscription<List<ConnectivityResult>> _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoad();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  void _listenToConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final isConnected = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (!_isOnline && isConnected) {
        setState(() => _isOnline = true);
        if (_shouldReloadOnReconnect) {
          await _loadFeedbackData();
          setState(() => _shouldReloadOnReconnect = false);
        }
      } else if (!isConnected) {
        setState(() => _isOnline = false);
      }
    });
  }

  Future<void> _checkConnectivityAndLoad() async {
    final result = await Connectivity().checkConnectivity();
    final isConnected = result != ConnectivityResult.none;
    setState(() => _isOnline = isConnected);

    if (isConnected) {
      await _loadFeedbackData();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection')));
    }
  }

  Future<void> _loadFeedbackData() async {
    setState(() => _isLoading = true);
    final results = await db.execute(
      "SELECT id, user_id, email, name, phone, comments, created_at, synced, image_path, image_url FROM feedback WHERE id IS NOT NULL AND id != ''",
    );
    setState(() {
      feedbackList = results;
      _isLoading = false;
    });
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataCollectionScreen()),
    );

    if (result == true) {
      if (_isOnline) {
        await _loadFeedbackData();
      } else {
        _shouldReloadOnReconnect = true;
        if (mounted) {
          await _loadFeedbackData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feedback saved locally. Will sync when online.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _onRefresh() async {
    await _checkConnectivityAndLoad();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Complaints"),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnectivityAndLoad,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Tooltip(
              message: _isOnline ? 'Online' : 'Offline',
              child: Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: _isOnline
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : feedbackList.isEmpty
            ? Center(
                child: Text(
                  _isOnline ? 'No feedback available' : 'Offline',
                  style: const TextStyle(fontSize: 16),
                ),
              )
            : ListView.separated(
                itemCount: feedbackList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = feedbackList[index];
                  final name = item['name']?.toString() ?? '';
                  final email = item['email']?.toString() ?? '';
                  final comments = item['comments']?.toString() ?? '';
                  final created = formatTimestamp(item['created_at']);
                  final synced = item['synced'] == 1;
                  final imageUrl = item['image_url']?.toString() ?? '';
                  final imagepath = item['image_path']?.toString() ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                      ),
                    ),
                    title: Text(name.isEmpty ? 'No Name' : name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comments.isEmpty ? 'No comments' : comments,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isEmpty ? '—' : email,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),

                        const SizedBox(height: 4),
                        Row(
                          children: [
                            imagepath.isNotEmpty
                                ? const Icon(
                                    Icons.attach_email_outlined,
                                    size: 16,
                                  )
                                : const SizedBox.shrink(),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                created,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          label: Text(synced ? 'Synced' : 'Local'),
                          backgroundColor: synced
                              ? theme.colorScheme.secondaryContainer
                              : theme.colorScheme.errorContainer,
                          labelStyle: TextStyle(
                            color: synced
                                ? theme.colorScheme.onSecondaryContainer
                                : theme.colorScheme.onErrorContainer,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                    onTap: () {
                      final imagePath =
                          feedbackList[index]['image_path']?.toString() ?? '';
                      if (imagePath.isNotEmpty) {
                        showImageDialog(context, imagePath);
                      }
                     
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToForm,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
    );
  }

  void showImageDialog(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uploaded Image'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Image.file(
            File(imagePath),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
