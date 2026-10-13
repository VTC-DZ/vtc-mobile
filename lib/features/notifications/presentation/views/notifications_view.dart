import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/push/notification_navigator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../data/models/app_notification.dart';
import '../cubit/notifications_cubit/notifications_cubit.dart';
import '../cubit/notifications_cubit/notifications_state.dart';
import 'widgets/notification_tile.dart';

/// The inbox of the role the UI is in, newest first. Both shells route here;
/// the cubit is the shell's, so this screen and the bell's dot share one
/// unread count.
class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<NotificationsCubit>().load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  /// The cubit skips an item that is already read, so only unread taps reach
  /// the server.
  void _open(AppNotification item) {
    context.read<NotificationsCubit>().markRead(item.id);
    NotificationNavigator.open(item.eventKey, item.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocSelector<NotificationsCubit, NotificationsState, bool>(
              selector: (state) => state.hasUnread,
              builder: (context, hasUnread) => AppTopBar(
                title: 'Notifications',
                onLeadingTap: () => context.pop(),
                trailingIcon: hasUnread ? Icons.done_all_rounded : null,
                onTrailingTap: () =>
                    context.read<NotificationsCubit>().markAllRead(),
                showTrailingBadge: false,
              ),
            ),
            Expanded(
              child: BlocConsumer<NotificationsCubit, NotificationsState>(
                listenWhen: (prev, curr) =>
                    prev.errorMessage != curr.errorMessage &&
                    curr.errorMessage.isNotEmpty &&
                    curr.items.isNotEmpty,
                // Transient refresh/loadMore failures: toast them instead of
                // wiping the items already on screen.
                listener: (context, state) =>
                    AppToast.error(state.errorMessage),
                builder: (context, state) {
                  if (state.items.isEmpty) return _buildEmptyState(state);

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        context.read<NotificationsCubit>().load(silent: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                      itemCount:
                          state.items.length + (state.hasReachedMax ? 0 : 1),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return _ListFooter(isLoading: state.isLoadingMore);
                        }
                        final item = state.items[index];
                        return NotificationTile(
                          notification: item,
                          onTap: () => _open(item),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Full-screen placeholder shown while the first page is loading, on a
  /// first-load failure, or when the inbox is empty.
  Widget _buildEmptyState(NotificationsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == NotificationsStatus.failure) {
      return _Message(
        icon: Icons.error_outline_rounded,
        text: state.errorMessage.isEmpty
            ? 'Something went wrong'
            : state.errorMessage,
        // Resume and new pushes only refresh the count until a list has
        // loaded, so without this a failed first load would stay failed.
        onRetry: () => context.read<NotificationsCubit>().load(),
      );
    }
    return const _Message(
      icon: Icons.notifications_none_rounded,
      text: 'No notifications yet. Updates about your rides and account will '
          'appear here.',
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.w, color: AppColors.textSecondary(context)),
            SizedBox(height: 12.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 8.h),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
