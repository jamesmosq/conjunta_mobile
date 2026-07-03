import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_repository.dart';
import '../models/chat_models.dart';

// ── Conversations list ────────────────────────────────────────────────────────

class ChatConversationsNotifier
    extends AsyncNotifier<List<ChatConversation>> {
  @override
  Future<List<ChatConversation>> build() {
    return ref.read(chatRepositoryProvider).getConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).getConversations(),
    );
  }
}

final chatConversationsProvider =
    AsyncNotifierProvider<ChatConversationsNotifier, List<ChatConversation>>(
  ChatConversationsNotifier.new,
);

final unreadChatCountProvider = Provider<int>((ref) {
  return ref.watch(chatConversationsProvider).maybeWhen(
        data: (list) => list.fold(0, (sum, c) => sum + c.unreadCount),
        orElse: () => 0,
      );
});

// ── Chat thread (per conversation) ───────────────────────────────────────────

class ChatThreadState {
  const ChatThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool hasMore;
  final int currentPage;
  final String? error;

  ChatThreadState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
  }) {
    return ChatThreadState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatThreadNotifier extends FamilyNotifier<ChatThreadState, int> {
  int get _conversationId => arg;

  @override
  ChatThreadState build(int arg) {
    // Load first page immediately
    Future.microtask(_loadFirstPage);
    return const ChatThreadState(isLoading: true);
  }

  Future<void> _loadFirstPage() async {
    try {
      final result = await ref
          .read(chatRepositoryProvider)
          .getMessages(_conversationId, page: 1);
      // Reverse so oldest is at index 0
      final reversed = result.messages.reversed.toList();
      state = ChatThreadState(
        messages: reversed,
        hasMore: result.hasMore,
        currentPage: 1,
      );
      // Mark messages as read when thread opens
      _markRead();
    } catch (e) {
      state = ChatThreadState(error: _parseError(e));
    }
  }

  Future<void> loadOlderMessages() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await ref
          .read(chatRepositoryProvider)
          .getMessages(_conversationId, page: nextPage);
      // Older messages prepend to the front of the list
      final older = result.messages.reversed.toList();
      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoading: false,
        hasMore: result.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<bool> sendMessage({String? texto, File? adjunto}) async {
    state = state.copyWith(isSending: true, clearError: true);
    try {
      final message = await ref.read(chatRepositoryProvider).sendMessage(
            conversationId: _conversationId,
            texto: texto,
            adjunto: adjunto,
          );
      state = state.copyWith(
        messages: [...state.messages, message],
        isSending: false,
      );
      // Update conversation list
      ref.invalidate(chatConversationsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, error: _parseError(e));
      return false;
    }
  }

  void receiveMessage(ChatMessage message) {
    // Avoid duplicates from Reverb when we sent the message ourselves
    final alreadyExists = state.messages.any((m) => m.id == message.id);
    if (alreadyExists) return;
    state = state.copyWith(messages: [...state.messages, message]);
    // Auto-mark read since thread is open
    _markRead();
    ref.invalidate(chatConversationsProvider);
  }

  void markAllRead(int readByUserId) {
    final now = DateTime.now().toIso8601String();
    final updated = state.messages.map((m) {
      if (m.remitenteId != readByUserId && m.readAt == null) {
        return m.copyWithReadAt(now);
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
    ref.invalidate(chatConversationsProvider);
  }

  Future<void> _markRead() async {
    try {
      await ref.read(chatRepositoryProvider).markRead(_conversationId);
      ref.invalidate(chatConversationsProvider);
    } catch (_) {}
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }
}

final chatThreadProvider =
    NotifierProvider.family<ChatThreadNotifier, ChatThreadState, int>(
  ChatThreadNotifier.new,
);
