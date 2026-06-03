import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CallPage extends StatefulWidget {
  final String token;
  final String? participantName;
  final String? foodName;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.token,
    this.participantName,
    this.foodName,
    this.isVideoCall = false,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Timer? _connectTimer;
  Timer? _durationTimer;

  Duration _duration = Duration.zero;
  _CallStatus _status = _CallStatus.connecting;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraEnabled = true;
  bool _isFrontCamera = true;

  String get _participantName {
    final String name = widget.participantName?.trim() ?? '';

    if (name.isEmpty || name == 'null') {
      return 'Donatur';
    }

    return name;
  }

  String get _foodName {
    final String foodName = widget.foodName?.trim() ?? '';

    if (foodName.isEmpty || foodName == 'null') {
      return 'Donasi Makanan';
    }

    return foodName;
  }

  bool get _isVideoCall {
    return widget.isVideoCall;
  }

  @override
  void initState() {
    super.initState();

    _connectTimer = Timer(
      const Duration(milliseconds: 1200),
      _activateCall,
    );
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  void _activateCall() {
    if (!mounted || _status == _CallStatus.ended) return;

    setState(() {
      _status = _CallStatus.active;
    });

    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted || _status != _CallStatus.active) return;

        setState(() {
          _duration += const Duration(seconds: 1);
        });
      },
    );
  }

  void _toggleMute() {
    if (_status == _CallStatus.ended) return;

    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleSpeaker() {
    if (_status == _CallStatus.ended) return;

    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  void _toggleCamera() {
    if (_status == _CallStatus.ended || !_isVideoCall) return;

    setState(() {
      _isCameraEnabled = !_isCameraEnabled;
    });
  }

  void _switchCamera() {
    if (_status == _CallStatus.ended || !_isVideoCall || !_isCameraEnabled) {
      return;
    }

    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  Future<void> _endCall() async {
    if (_status == _CallStatus.ended) return;

    _connectTimer?.cancel();
    _durationTimer?.cancel();

    setState(() {
      _status = _CallStatus.ended;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 520),
    );

    if (!mounted) return;

    Navigator.of(context).maybePop();
  }

  String _durationLabel() {
    final int minutes = _duration.inMinutes;
    final int seconds = _duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _statusLabel() {
    switch (_status) {
      case _CallStatus.connecting:
        return 'Menghubungkan...';
      case _CallStatus.active:
        return _durationLabel();
      case _CallStatus.ended:
        return 'Panggilan selesai';
    }
  }

  void _showMockInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.textPrimary,
        content: Text(
          'Panggilan ini masih berupa mock UI. Integrasi VoIP/WebRTC dapat ditambahkan pada tahap backend/real-time service.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnded = _status == _CallStatus.ended;

    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _CallBackground(
                isVideoCall: _isVideoCall,
                isCameraEnabled: _isCameraEnabled,
                participantName: _participantName,
              ),
            ),
            Positioned(
              left: AppSpacing.x2,
              right: AppSpacing.x2,
              top: AppSpacing.x2,
              child: _CallTopBar(
                isVideoCall: _isVideoCall,
                onClose: _endCall,
                onInfo: _showMockInfo,
              ),
            ),
            Positioned(
              left: AppSpacing.x3,
              right: AppSpacing.x3,
              top: 128,
              child: _ParticipantInfo(
                participantName: _participantName,
                foodName: _foodName,
                statusLabel: _statusLabel(),
                isMuted: _isMuted,
                isSpeakerOn: _isSpeakerOn,
                isVideoCall: _isVideoCall,
                isCameraEnabled: _isCameraEnabled,
              ),
            ),
            if (_isVideoCall && _isCameraEnabled)
              Positioned(
                right: AppSpacing.x3,
                bottom: 190,
                child: _SelfPreview(
                  isMuted: _isMuted,
                  isFrontCamera: _isFrontCamera,
                ),
              ),
            Positioned(
              left: AppSpacing.x3,
              right: AppSpacing.x3,
              bottom: AppSpacing.x3,
              child: _CallControls(
                isVideoCall: _isVideoCall,
                isMuted: _isMuted,
                isSpeakerOn: _isSpeakerOn,
                isCameraEnabled: _isCameraEnabled,
                isEnded: isEnded,
                onToggleMute: _toggleMute,
                onToggleSpeaker: _toggleSpeaker,
                onToggleCamera: _toggleCamera,
                onSwitchCamera: _switchCamera,
                onEndCall: _endCall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallTopBar extends StatelessWidget {
  final bool isVideoCall;
  final VoidCallback onClose;
  final VoidCallback onInfo;

  const _CallTopBar({
    required this.isVideoCall,
    required this.onClose,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopIconButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: 'Tutup panggilan',
          onTap: onClose,
        ),
        const Spacer(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x2,
              vertical: AppSpacing.x1,
            ),
            child: Row(
              children: [
                Icon(
                  isVideoCall ? Icons.videocam_rounded : Icons.call_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isVideoCall ? 'Video Call' : 'Audio Call',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        _TopIconButton(
          icon: Icons.info_outline_rounded,
          tooltip: 'Info',
          onTap: onInfo,
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CallBackground extends StatelessWidget {
  final bool isVideoCall;
  final bool isCameraEnabled;
  final String participantName;

  const _CallBackground({
    required this.isVideoCall,
    required this.isCameraEnabled,
    required this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    if (isVideoCall && isCameraEnabled) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.textPrimary,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.90),
                    AppColors.textPrimary,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.person_rounded,
              size: 164,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.textPrimary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 120,
            right: -24,
            child: _SoftCircle(
              size: 180,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            left: -50,
            bottom: 130,
            child: _SoftCircle(
              size: 220,
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          Center(
            child: _LargeAvatar(
              participantName: participantName,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantInfo extends StatelessWidget {
  final String participantName;
  final String foodName;
  final String statusLabel;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isVideoCall;
  final bool isCameraEnabled;

  const _ParticipantInfo({
    required this.participantName,
    required this.foodName,
    required this.statusLabel,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isVideoCall,
    required this.isCameraEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          participantName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          foodName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
        ),
        const SizedBox(height: AppSpacing.x2),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.x1,
          runSpacing: AppSpacing.x1,
          children: [
            _CallStatusPill(
              icon: Icons.timer_outlined,
              label: statusLabel,
              color: AppColors.accent,
            ),
            if (isMuted)
              const _CallStatusPill(
                icon: Icons.mic_off_rounded,
                label: 'Muted',
                color: AppColors.danger,
              ),
            if (isSpeakerOn)
              const _CallStatusPill(
                icon: Icons.volume_up_rounded,
                label: 'Speaker',
                color: AppColors.teal,
              ),
            if (isVideoCall && !isCameraEnabled)
              const _CallStatusPill(
                icon: Icons.videocam_off_rounded,
                label: 'Camera Off',
                color: AppColors.danger,
              ),
          ],
        ),
      ],
    );
  }
}

class _LargeAvatar extends StatelessWidget {
  final String participantName;

  const _LargeAvatar({
    required this.participantName,
  });

  @override
  Widget build(BuildContext context) {
    final String initial = participantName.trim().isEmpty
        ? 'D'
        : participantName.trim().characters.first.toUpperCase();

    return Container(
      width: 156,
      height: 156,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.26),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontSize: 58,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _SelfPreview extends StatelessWidget {
  final bool isMuted;
  final bool isFrontCamera;

  const _SelfPreview({
    required this.isMuted,
    required this.isFrontCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 164,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.teal.withValues(alpha: 0.90),
                      AppColors.primaryDark,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                isFrontCamera
                    ? Icons.person_rounded
                    : Icons.camera_rear_rounded,
                color: Colors.white.withValues(alpha: 0.82),
                size: 52,
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Anda',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  final bool isVideoCall;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraEnabled;
  final bool isEnded;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onEndCall;

  const _CallControls({
    required this.isVideoCall,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isCameraEnabled,
    required this.isEnded,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                _ControlButton(
                  icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: isMuted ? 'Unmute' : 'Mute',
                  isActive: isMuted,
                  onTap: isEnded ? null : onToggleMute,
                ),
                _ControlButton(
                  icon: isSpeakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  label: 'Speaker',
                  isActive: isSpeakerOn,
                  onTap: isEnded ? null : onToggleSpeaker,
                ),
                if (isVideoCall)
                  _ControlButton(
                    icon: isCameraEnabled
                        ? Icons.videocam_rounded
                        : Icons.videocam_off_rounded,
                    label: isCameraEnabled ? 'Camera' : 'Off',
                    isActive: !isCameraEnabled,
                    onTap: isEnded ? null : onToggleCamera,
                  ),
                if (isVideoCall)
                  _ControlButton(
                    icon: Icons.cameraswitch_rounded,
                    label: 'Switch',
                    isActive: false,
                    onTap:
                        isEnded || !isCameraEnabled ? null : onSwitchCamera,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            Material(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: isEnded ? null : onEndCall,
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.call_end_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      Text(
                        'Akhiri Panggilan',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isActive
        ? AppColors.surface
        : Colors.white.withValues(alpha: 0.14);

    final Color foregroundColor =
        isActive ? AppColors.textPrimary : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 54,
              height: 54,
              child: Icon(
                icon,
                color: foregroundColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: onTap == null ? 0.42 : 0.88),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _CallStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CallStatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x1,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

enum _CallStatus {
  connecting,
  active,
  ended,
}