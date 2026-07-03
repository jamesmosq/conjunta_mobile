import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/services/reverb_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversationId,
    required this.contraparteName,
  });

  final int conversationId;
  final String contraparteName;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  File? _pendingAttachment;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Subscribe to Reverb channel for this conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(reverbServiceProvider)
          .subscribeChatThread(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load older messages when near the top
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 100) {
      ref
          .read(chatThreadProvider(widget.conversationId).notifier)
          .loadOlderMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatThreadProvider(widget.conversationId));
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserId = currentUser?.id ?? -1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.teal.shade300,
              child: Text(
                widget.contraparteName.isNotEmpty
                    ? widget.contraparteName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.contraparteName),
          ],
        ),
      ),
      body: Column(
        children: [
          // Loading indicator for older messages
          if (state.isLoading && state.messages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.teal.shade50,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cargando mensajes anteriores...',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          // Messages
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.messages.isEmpty
                    ? Center(child: Text(state.error!))
                    : _MessageList(
                        messages: state.messages,
                        currentUserId: currentUserId,
                        scrollController: _scrollController,
                      ),
          ),
          // Pending attachment preview
          if (_pendingAttachment != null)
            _AttachmentPreview(
              file: _pendingAttachment!,
              onRemove: () => setState(() => _pendingAttachment = null),
            ),
          // Input bar
          _ChatInputBar(
            controller: _textController,
            isSending: state.isSending,
            onSend: _send,
            onAttachImage: _pickImage,
            onAttachFile: _pickFile,
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    final attachment = _pendingAttachment;

    if (text.isEmpty && attachment == null) return;

    _textController.clear();
    setState(() => _pendingAttachment = null);

    await ref
        .read(chatThreadProvider(widget.conversationId).notifier)
        .sendMessage(texto: text.isEmpty ? null : text, adjunto: attachment);

    // Scroll to bottom after send
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile != null) setState(() => _pendingAttachment = File(xFile.path));
  }

  Future<void> _pickFile() async {
    // Re-use image_picker for camera; for PDFs user can pick from gallery
    final xFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (xFile != null) setState(() => _pendingAttachment = File(xFile.path));
  }
}

// ── Message list ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final int currentUserId;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'Escribe un mensaje para comenzar la conversación.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final message = messages[i];
        final isMine = message.remitenteId == currentUserId;
        final showDateDivider = i == 0 ||
            _isDifferentDay(messages[i - 1].sentAt, message.sentAt);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDateDivider) _DateDivider(dateStr: message.sentAt),
            _MessageBubble(message: message, isMine: isMine),
          ],
        );
      },
    );
  }

  bool _isDifferentDay(String a, String b) {
    try {
      final da = DateTime.parse(a);
      final db = DateTime.parse(b);
      return da.day != db.day ||
          da.month != db.month ||
          da.year != db.year;
    } catch (_) {
      return false;
    }
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.dateStr});

  final String dateStr;

  @override
  Widget build(BuildContext context) {
    String label;
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        label = 'Hoy';
      } else if (dt.day == now.day - 1 &&
          dt.month == now.month &&
          dt.year == now.year) {
        label = 'Ayer';
      } else {
        label = DateFormat('EEEE d \'de\' MMMM', 'es').format(dt);
      }
    } catch (_) {
      label = '';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ── Bubble ────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMine ? Colors.teal.shade600 : Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.remitentNombre,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
              if (message.adjunto != null)
                _AttachmentWidget(
                  attachment: message.adjunto!,
                  isMine: isMine,
                ),
              if (message.texto != null && message.texto!.isNotEmpty)
                Text(
                  message.texto!,
                  style: TextStyle(
                    color: isMine ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white70
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _ReadReceipt(isRead: message.isRead),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return '';
    }
  }
}

// ✓ / ✓✓ indicator
class _ReadReceipt extends StatelessWidget {
  const _ReadReceipt({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.done,
          size: 12,
          color: isRead ? Colors.lightBlueAccent : Colors.white60,
        ),
        if (isRead)
          Icon(Icons.done, size: 12, color: Colors.lightBlueAccent,
              // Second checkmark overlaps slightly
              shadows: [Shadow(color: Colors.teal.shade600, offset: const Offset(-4, 0))]),
      ],
    );
  }
}

// ── Attachment widget (inline in bubble) ─────────────────────────────────────

class _AttachmentWidget extends StatelessWidget {
  const _AttachmentWidget({required this.attachment, required this.isMine});

  final ChatAttachment attachment;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    if (attachment.isImage) {
      return GestureDetector(
        onTap: () => _viewImage(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: attachment.url,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(
              width: 200,
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          ),
        ),
      );
    }

    // PDF or other file
    return GestureDetector(
      onTap: () => OpenFilex.open(attachment.url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf,
              color: isMine ? Colors.white70 : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              'Ver documento',
              style: TextStyle(
                fontSize: 13,
                color: isMine ? Colors.white : Colors.black87,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: CachedNetworkImage(
            imageUrl: attachment.url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ── Pending attachment preview ────────────────────────────────────────────────

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.teal.shade50,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(file, width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.path.split('/').last,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onAttachImage,
    required this.onAttachFile,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttachImage;
  final VoidCallback onAttachFile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.image_outlined, color: Colors.teal.shade600),
              onPressed: onAttachImage,
              tooltip: 'Adjuntar imagen',
            ),
            IconButton(
              icon: Icon(Icons.camera_alt_outlined, color: Colors.teal.shade600),
              onPressed: onAttachFile,
              tooltip: 'Tomar foto',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            isSending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.send, color: Colors.teal.shade700),
                    onPressed: onSend,
                    tooltip: 'Enviar',
                  ),
          ],
        ),
      ),
    );
  }
}
