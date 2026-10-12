import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/push/push_notification_service.dart';
import '../../../data/notification_repository.dart';
import 'notifications_state.dart';

/// The inbox and its unread count, for the role the UI is in.
///
/// Shell-scoped at both homes, so the bell's dot survives navigation; a role
/// switch or logout disposes the shell and starts a fresh inbox. The inbox is
/// the truth, because a push can be missed, so it refetches when the app
/// resumes and when a foreground push announces a new item. It never listens
/// to the ride socket.
///
/// Those refreshes run in the background and can land after the shell is
/// gone, and `emit` after `close` throws, so every emit that follows an
/// `await` checks [isClosed] first.
final class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState()) {
    _inboxSub = PushNotificationService.inboxChanges.listen((_) => _refresh());
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  final NotificationRepository _repository;
  late final StreamSubscription<void> _inboxSub;
  late final AppLifecycleListener _lifecycle;

  /// Bumped by every [load], so an older load that lands late can't
  /// overwrite a newer one.
  int _loadGeneration = 0;

  static const int _pageSize = 20;

  /// The bell's count. Best-effort: keeps the old count on error.
  Future<void> refreshUnreadCount() async {
    try {
      final count = await _repository.unreadCount();
      if (isClosed) return;
      emit(state.copyWith(unreadCount: count));
    } catch (_) {
      // Best-effort: keep the dot the bell already shows.
    }
  }

  /// Page 0 plus the count. [silent] keeps the current list on screen instead
  /// of the full-screen spinner; it is also the pull-to-refresh action.
  Future<void> load({bool silent = false}) async {
    final generation = ++_loadGeneration;
    if (!silent) {
      emit(state.copyWith(
        status: NotificationsStatus.loading,
        items: const [],
        currentPage: -1,
        totalPages: 0,
        errorMessage: '',
      ));
    }
    // Alongside the list rather than combined with it: a count failure must
    // not blank the list.
    unawaited(refreshUnreadCount());
    try {
      final page = await _repository.list(size: _pageSize);
      if (isClosed || generation != _loadGeneration) return;
      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: page.data,
        currentPage: page.page,
        totalPages: page.totalPages,
        errorMessage: '',
      ));
    } catch (e) {
      if (isClosed || generation != _loadGeneration) return;
      emit(silent
          // Keep what is on screen; only report the failure.
          ? state.copyWith(errorMessage: e.toString())
          : state.copyWith(
              status: NotificationsStatus.failure,
              errorMessage: e.toString(),
            ));
    }
  }

  /// Appends the next page. On error it keeps the items already on screen and
  /// reports the failure.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedMax) return;

    final nextPage = state.currentPage + 1;
    emit(state.copyWith(
      status: NotificationsStatus.loadingMore,
      errorMessage: '',
    ));
    try {
      final page = await _repository.list(page: nextPage, size: _pageSize);
      // A reload restarted the list meanwhile, so this page no longer
      // follows what is on screen.
      if (isClosed || state.currentPage != nextPage - 1) return;
      // New items push older ones across page boundaries, so an item can
      // come back on the next page.
      final known = {for (final item in state.items) item.id};
      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        items: [
          ...state.items,
          ...page.data.where((item) => !known.contains(item.id)),
        ],
        currentPage: page.page,
        totalPages: page.totalPages,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: NotificationsStatus.loaded,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Optimistic: the tile turns read at once. Any failure reloads silently to
  /// realign with the server. For a 404 (the item is gone) that is the whole
  /// answer, with no toast.
  Future<void> markRead(String id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1 || state.items[index].read) return;

    final items = [...state.items];
    items[index] = items[index].copyWith(read: true);
    emit(state.copyWith(
      items: items,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    ));
    try {
      await _repository.markRead(id);
    } catch (_) {
      if (!isClosed) await load(silent: true);
    }
  }

  /// Optimistic: every item turns read and the count drops to 0 at once. A
  /// failure reloads silently.
  Future<void> markAllRead() async {
    if (!state.hasUnread) return;

    emit(state.copyWith(
      items: [
        for (final item in state.items)
          item.read ? item : item.copyWith(read: true),
      ],
      unreadCount: 0,
    ));
    try {
      await _repository.markAllRead();
    } catch (_) {
      if (!isClosed) await load(silent: true);
    }
  }

  /// A foreground push announced an item, or the app came back. The list is
  /// reloaded only when it is already on screen, and that load brings the
  /// count with it.
  void _refresh() {
    if (state.status == NotificationsStatus.loaded) {
      unawaited(load(silent: true));
    } else {
      unawaited(refreshUnreadCount());
    }
  }

  @override
  Future<void> close() {
    _inboxSub.cancel();
    _lifecycle.dispose();
    return super.close();
  }
}
