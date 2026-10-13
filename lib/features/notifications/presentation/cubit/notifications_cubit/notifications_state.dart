import 'package:equatable/equatable.dart';

import '../../../data/models/app_notification.dart';

enum NotificationsStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  failure,
}

final class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.currentPage = -1,
    this.totalPages = 0,
    this.unreadCount = 0,
    this.errorMessage = '',
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final int currentPage;
  final int totalPages;

  /// The server's count for the whole inbox, not only the loaded pages. It
  /// drives the bell's badge.
  final int unreadCount;
  final String errorMessage;

  bool get isLoading => status == NotificationsStatus.loading;
  bool get isLoadingMore => status == NotificationsStatus.loadingMore;
  bool get hasUnread => unreadCount > 0;

  /// Whether the last page has been fetched. Guards against `totalPages == 0`
  /// (an empty inbox) so we never paginate into nothing.
  bool get hasReachedMax {
    if (totalPages <= 0) return true;
    return currentPage + 1 >= totalPages;
  }

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    int? currentPage,
    int? totalPages,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, currentPage, totalPages, unreadCount, errorMessage];
}
