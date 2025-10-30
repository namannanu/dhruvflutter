import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:talent/core/models/models.dart';
import 'package:talent/core/state/app_state.dart';
import 'package:talent/features/shared/services/conversation_api_service.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _conversationsTimer;
  bool _isFetchingConversations = false;
  final Map<String, DateTime> _conversationUpdateCache = {};
  
  final ConversationApiService _apiService = ConversationApiService();

  @override
  void initState() {
    super.initState();
    _loadConversations(showLoader: true, showErrorSnackBar: true);
    _startConversationPolling();
  }

  @override
  void dispose() {
    _conversationsTimer?.cancel();
    super.dispose();
  }

  void _startConversationPolling() {
    _conversationsTimer?.cancel();
    _conversationsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations({
    bool showLoader = false,
    bool showErrorSnackBar = false,
  }) async {
    if (_isFetchingConversations) return;
    _isFetchingConversations = true;

    if (showLoader && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final conversations = await _apiService.getConversations();
      if (!mounted) return;

      final newUnreadConversations = conversations.where((conversation) {
        final previousTimestamp = _conversationUpdateCache[conversation.id];
        final hasNewUpdate = previousTimestamp == null ||
            conversation.updatedAt.isAfter(previousTimestamp);
        return hasNewUpdate && conversation.unreadCount > 0;
      }).toList();

      if (!showLoader &&
          newUnreadConversations.isNotEmpty &&
          mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();

        final messageText = newUnreadConversations.length == 1
            ? 'New message in "${newUnreadConversations.first.title}"'
            : '${newUnreadConversations.length} conversations have new messages';

        messenger.showSnackBar(
          SnackBar(
            content: Text(messageText),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        unawaited(context.read<AppState>().loadNotifications());
      }

      setState(() {
        _conversations = conversations;
      });

      _conversationUpdateCache
        ..clear()
        ..addEntries(
          conversations.map(
            (conversation) => MapEntry(conversation.id, conversation.updatedAt),
          ),
        );
    } catch (error) {
      if (showErrorSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (showLoader && mounted) {
        setState(() => _isLoading = false);
      }
      _isFetchingConversations = false;
    }
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    
    return _conversations.where((conversation) {
      return conversation.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             conversation.lastMessagePreview.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _openConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationDetailScreen(conversation: conversation),
      ),
    ).then((_) {
      // Refresh conversations when returning from detail screen
      _loadConversations(showErrorSnackBar: true);
    });
  }

  void _startNewConversation() {
    // Implementation needed: Implement new conversation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Start new conversation feature coming soon...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MM/dd').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _startNewConversation,
            tooltip: 'New Message',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadConversations(showErrorSnackBar: true),
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            
            // Conversations list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredConversations.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            final conversation = _filteredConversations[index];
                            return _buildConversationTile(conversation);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start messaging with your team or workers',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewConversation,
            icon: const Icon(Icons.add_comment, color: Colors.white),
            label: const Text(
              'Start New Conversation',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[600],
          child: Text(
            conversation.title.isNotEmpty 
                ? conversation.title[0].toUpperCase()
                : 'C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.title,
                style: TextStyle(
                  fontWeight: conversation.unreadCount > 0 
                      ? FontWeight.bold 
                      : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              conversation.lastMessagePreview.isNotEmpty 
                  ? conversation.lastMessagePreview
                  : 'No messages yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: conversation.unreadCount > 0 
                    ? FontWeight.w500 
                    : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(conversation.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (conversation.jobId != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.work,
                          size: 10,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Job',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}

class ConversationDetailScreen extends StatefulWidget {
  const ConversationDetailScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isFetchingMessages = false;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _messagePollingTimer;
  final Set<String> _knownMessageIds = <String>{};
  
  final ConversationApiService _apiService = ConversationApiService();

  @override
  void initState() {
    super.initState();
    _loadMessages(
      initialLoad: true,
      showErrorSnackBar: true,
    );
    _markAsRead();
    _startMessagePolling();
  }

  @override
  void dispose() {
    _messagePollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startMessagePolling() {
    _messagePollingTimer?.cancel();
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages({
    bool initialLoad = false,
    bool showErrorSnackBar = false,
  }) async {
    if (_isFetchingMessages) return;
    _isFetchingMessages = true;

    if (initialLoad && mounted) {
      setState(() => _isLoading = true);
    }

    final previousLength = _messages.length;
    final previousLastId = _messages.isNotEmpty ? _messages.last.id : null;

    try {
      final messages = await _apiService.getMessages(widget.conversation.id);
      if (!mounted) return;

      final hasNewMessages = messages.length > previousLength ||
          (messages.isNotEmpty &&
              previousLastId != null &&
              messages.last.id != previousLastId);

      final currentUserId = context.read<AppState>().currentUser?.id;
      final newMessages = messages
          .where((message) => !_knownMessageIds.contains(message.id))
          .toList();
      final incomingMessages = newMessages
          .where((message) => message.senderId != currentUserId)
          .toList();
      final bool shouldHandleNewMessages =
          hasNewMessages || incomingMessages.isNotEmpty;

      setState(() {
        _messages = messages;
        if (initialLoad) {
          _isLoading = false;
        }
      });

      _knownMessageIds
        ..clear()
        ..addAll(messages.map((message) => message.id));

      if (mounted && (initialLoad || shouldHandleNewMessages)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      if (!initialLoad && incomingMessages.isNotEmpty && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();

        final latest = incomingMessages.last;
        final preview = latest.body.trim();
        final text = preview.isEmpty
            ? 'New message received'
            : 'New message: ${preview.length > 70 ? '${preview.substring(0, 70)}…' : preview}';

        messenger.showSnackBar(
          SnackBar(
            content: Text(text),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        unawaited(context.read<AppState>().loadNotifications());
      }

      if (initialLoad || shouldHandleNewMessages) {
        unawaited(_markAsRead());
      }
    } catch (error) {
      if (initialLoad && mounted) {
        setState(() => _isLoading = false);
      }

      if (showErrorSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isFetchingMessages = false;
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _apiService.markConversationRead(widget.conversation.id);
    } catch (error) {
      // Silently fail for marking as read
      debugPrint('Failed to mark conversation as read: $error');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final message = await _apiService.sendMessage(
        conversationId: widget.conversation.id,
        body: text,
      );
      
      setState(() {
        _messages.add(message);
      });
      
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $error'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Restore the text if sending failed
        _messageController.text = text;
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AppState>().currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.conversation.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Implementation needed: Show conversation info
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation info coming soon...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet.\nStart the conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.senderId == currentUser?.id;
                          
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey[100],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                message.senderId[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.body,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[600],
              child: Text(
                message.senderId[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
