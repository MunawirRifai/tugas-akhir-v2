import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ChatRoomPage extends StatefulWidget {
  final String token;
  final String? roomId;
  final String? participantName;
  final String? foodName;
  final Map<String, dynamic>? food;

  const ChatRoomPage({
    super.key,
    required this.token,
    this.roomId,
    this.participantName,
    this.foodName,
    this.food,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<_ChatMessage> _messages;

  bool _isSending = false;
  bool _isTyping = false;

  String get _participantName {
    final String? explicitName = widget.participantName?.trim();

    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }

    final Object? donorName = widget.food?['donorName'] ??
        widget.food?['donor_name'] ??
        widget.food?['userName'] ??
        widget.food?['user_name'];

    final String parsedName = donorName?.toString().trim() ?? '';

    if (parsedName.isNotEmpty && parsedName != 'null') {
      return parsedName;
    }

    return 'Donatur';
  }

  String get _foodName {
    final String? explicitFoodName = widget.foodName?.trim();

    if (explicitFoodName != null && explicitFoodName.isNotEmpty) {
      return explicitFoodName;
    }

    final Object? foodName = widget.food?['foodName'] ??
        widget.food?['food_name'] ??
        widget.food?['name'] ??
        widget.food?['title'];

    final String parsedFoodName = foodName?.toString().trim() ?? '';

    if (parsedFoodName.isNotEmpty && parsedFoodName != 'null') {
      return parsedFoodName;
    }

    return 'Donasi Makanan';
  }

  @override
  void initState() {
    super.initState();

    _messages = _initialMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<_ChatMessage> _initialMessages() {
    final DateTime now = DateTime.now();

    return [
      _ChatMessage(
        id: 'msg-001',
        text:
            'Halo, saya tertarik mengambil $_foodName. Apakah masih tersedia?',
        timestamp: now.subtract(const Duration(minutes: 9)),
        isMe: true,
        status: _MessageStatus.read,
      ),
      _ChatMessage(
        id: 'msg-002',
        text:
            'Masih tersedia. Silakan datang sesuai titik pickup di aplikasi.',
        timestamp: now.subtract(const Duration(minutes: 7)),
        isMe: false,
        status: _MessageStatus.read,
      ),
      _ChatMessage(
        id: 'msg-003',
        text:
            'Baik. Saya akan mengikuti rute di aplikasi dan upload bukti foto setelah makanan diterima.',
        timestamp: now.subtract(const Duration(minutes: 5)),
        isMe: true,
        status: _MessageStatus.delivered,
      ),
    ];
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    FocusScope.of(context).unfocus();

    final _ChatMessage outgoingMessage = _ChatMessage(
      id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
      status: _MessageStatus.sending,
    );

    setState(() {
      _isSending = true;
      _messages.add(outgoingMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    await Future<void>.delayed(
      const Duration(milliseconds: 520),
    );

    if (!mounted) return;

    setState(() {
      _messages = _messages.map((message) {
        if (message.id == outgoingMessage.id) {
          return message.copyWith(
            status: _MessageStatus.delivered,
          );
        }

        return message;
      }).toList();

      _isSending = false;
      _isTyping = true;
    });

    _scrollToBottom();

    await Future<void>.delayed(
      const Duration(milliseconds: 820),
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(
        _ChatMessage(
          id: 'msg-${DateTime.now().microsecondsSinceEpoch}-reply',
          text:
              'Terima kasih. Gunakan fitur call di aplikasi jika perlu koordinasi tambahan.',
          timestamp: DateTime.now(),
          isMe: false,
          status: _MessageStatus.read,
        ),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openCallMock({
    required bool isVideo,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Text(
          isVideo
              ? 'Video call in-app akan dihubungkan ke modul VoIP.'
              : 'Audio call in-app akan dihubungkan ke modul VoIP.',
        ),
      ),
    );
  }

  void _showPrivacyInfo() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _PrivacyInfoSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: _ChatAppBarTitle(
          participantName: _participantName,
          foodName: _foodName,
        ),
        actions: [
          IconButton(
            tooltip: 'Audio call',
            onPressed: () => _openCallMock(isVideo: false),
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: () => _openCallMock(isVideo: true),
            icon: const Icon(Icons.videocam_outlined),
          ),
          IconButton(
            tooltip: 'Privasi',
            onPressed: _showPrivacyInfo,
            icon: const Icon(Icons.privacy_tip_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ConversationContextCard(
              foodName: _foodName,
              participantName: _participantName,
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingBubble();
                  }

                  final _ChatMessage message = _messages[index];

                  final bool showAvatar = index == 0 ||
                      _messages[index - 1].isMe != message.isMe;

                  return _ChatBubble(
                    message: message,
                    showAvatar: showAvatar,
                    participantName: _participantName,
                  );
                },
              ),
            ),
            _ChatInputBar(
              controller: _messageController,
              isSending: _isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  final String participantName;
  final String foodName;

  const _ChatAppBarTitle({
    required this.participantName,
    required this.foodName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ParticipantAvatar(
          name: participantName,
          size: 42,
        ),
        const SizedBox(width: AppSpacing.x1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                participantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 2),
              Text(
                foodName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConversationContextCard extends StatelessWidget {
  final String foodName;
  final String participantName;

  const _ConversationContextCard({
    required this.foodName,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x3,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koordinasi Pickup',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$foodName dengan $participantName. Hindari membagikan nomor pribadi.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool showAvatar;
  final String participantName;

  const _ChatBubble({
    required this.message,
    required this.showAvatar,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    final Alignment alignment =
        message.isMe ? Alignment.centerRight : Alignment.centerLeft;

    final Color bubbleColor =
        message.isMe ? AppColors.primary : AppColors.surface;

    final Color textColor = message.isMe ? Colors.white : AppColors.textPrimary;

    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadius.lg),
      topRight: const Radius.circular(AppRadius.lg),
      bottomLeft: Radius.circular(message.isMe ? AppRadius.lg : 4),
      bottomRight: Radius.circular(message.isMe ? 4 : AppRadius.lg),
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x1),
        child: Row(
          mainAxisAlignment:
              message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isMe) ...[
              if (showAvatar)
                _ParticipantAvatar(
                  name: participantName,
                  size: 32,
                )
              else
                const SizedBox(width: 32),
              const SizedBox(width: AppSpacing.x1),
            ],
            Flexible(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 292,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x2,
                  vertical: AppSpacing.x1_5,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: message.isMe
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  boxShadow: message.isMe ? AppShadows.brand : AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight:
                                message.isMe ? FontWeight.w500 : FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: message.isMe
                                        ? Colors.white.withValues(alpha: 0.76)
                                        : AppColors.textMuted,
                                  ),
                        ),
                        if (message.isMe) ...[
                          const SizedBox(width: 5),
                          Icon(
                            _statusIcon(message.status),
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.76),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (message.isMe) const SizedBox(width: 0),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  static IconData _statusIcon(_MessageStatus status) {
    switch (status) {
      case _MessageStatus.sending:
        return Icons.schedule_rounded;
      case _MessageStatus.delivered:
        return Icons.done_rounded;
      case _MessageStatus.read:
        return Icons.done_all_rounded;
    }
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x1),
        child: Row(
          children: [
            const SizedBox(width: 40),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.x2,
                  vertical: AppSpacing.x1_5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TypingDot(delay: 0),
                    SizedBox(width: 4),
                    _TypingDot(delay: 120),
                    SizedBox(width: 4),
                    _TypingDot(delay: 240),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({
    required this.delay,
  });

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.28,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future<void>.delayed(
      Duration(milliseconds: widget.delay),
      () {
        if (mounted) {
          _controller.repeat(reverse: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2,
            AppSpacing.x1,
            AppSpacing.x2,
            AppSpacing.x2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isSending,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan...',
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: isSending ? null : onSend,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Center(
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _ParticipantAvatar({
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = name.trim().isEmpty
        ? 'D'
        : name.trim().characters.first.toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _PrivacyInfoSheet extends StatelessWidget {
  const _PrivacyInfoSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            AppSpacing.x3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.privacy_tip_outlined,
                  color: AppColors.primaryDark,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Privasi Komunikasi',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                'Gunakan chat dan call in-app untuk koordinasi pickup. Hindari membagikan nomor pribadi, alamat rumah detail, atau data sensitif lain.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x3),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final _MessageStatus status;

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isMe,
    required this.status,
  });

  _ChatMessage copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    bool? isMe,
    _MessageStatus? status,
  }) {
    return _ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
    );
  }
}

enum _MessageStatus {
  sending,
  delivered,
  read,
}