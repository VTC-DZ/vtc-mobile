import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapidoo/core/errors/api_exception.dart';
import 'package:rapidoo/core/models/page_response.dart';
import 'package:rapidoo/core/push/push_notification_service.dart';
import 'package:rapidoo/features/notifications/data/models/app_notification.dart';
import 'package:rapidoo/features/notifications/data/notification_repository.dart';
import 'package:rapidoo/features/notifications/presentation/cubit/notifications_cubit/notifications_cubit.dart';
import 'package:rapidoo/features/notifications/presentation/cubit/notifications_cubit/notifications_state.dart';

/// Serves canned pages and a count. A test can make calls fail, or hold a
/// list or count call until it completes the matching completer.
class _FakeNotificationRepository extends NotificationRepository {
  final pages = <int, PageResponse<AppNotification>>{};
  int count = 0;
  Object? listError;
  Object? markError;

  final listHolds = <int, Completer<void>>{};
  Completer<void>? countHold;

  final listCalls = <int>[];
  final markedRead = <String>[];
  int markAllCalls = 0;

  @override
  Future<PageResponse<AppNotification>> list({
    int page = 0,
    int size = 20,
  }) async {
    listCalls.add(page);
    final hold = listHolds.remove(page);
    if (hold != null) await hold.future;
    final error = listError;
    if (error != null) throw error;
    return pages[page] ?? const PageResponse.empty();
  }

  @override
  Future<int> unreadCount() async {
    final hold = countHold;
    countHold = null;
    if (hold != null) await hold.future;
    return count;
  }

  @override
  Future<void> markRead(String id) async {
    markedRead.add(id);
    final error = markError;
    if (error != null) throw error;
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    final error = markError;
    if (error != null) throw error;
    return 0;
  }
}

/// Records the errors a cubit reports, such as an emit after close.
class _ErrorObserver extends BlocObserver {
  final errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

AppNotification _item(String id, {bool read = false}) => AppNotification(
      id: id,
      eventKey: 'ride.completed',
      title: 'Course terminée',
      body: 'Merci.',
      data: const {},
      read: read,
      createdAt: '2026-10-12T10:00:00Z',
    );

PageResponse<AppNotification> _page(
  int page,
  List<AppNotification> items, {
  int totalPages = 1,
}) =>
    PageResponse(
      data: items,
      page: page,
      size: 20,
      totalElements: items.length,
      totalPages: totalPages,
    );

const _offline = ApiException(message: 'No connection. Check your network.');

void main() {
  // AppLifecycleListener needs a binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeNotificationRepository repository;
  late NotificationsCubit cubit;

  setUp(() {
    repository = _FakeNotificationRepository();
    cubit = NotificationsCubit(repository);
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  List<String> ids() => [for (final item in cubit.state.items) item.id];

  test('load fills the list, the pages and the count', () async {
    repository
      ..pages[0] = _page(0, [_item('a'), _item('b', read: true)], totalPages: 2)
      ..count = 1;

    await cubit.load();
    await pumpEventQueue();

    expect(cubit.state.status, NotificationsStatus.loaded);
    expect(ids(), ['a', 'b']);
    expect(cubit.state.currentPage, 0);
    expect(cubit.state.hasReachedMax, isFalse);
    expect(cubit.state.unreadCount, 1);
    expect(cubit.state.hasUnread, isTrue);
  });

  group('markRead', () {
    test('flips the item and lowers the count, never below 0', () async {
      repository
        ..pages[0] = _page(0, [_item('a'), _item('b')])
        // The server count can lag behind the list.
        ..count = 1;
      await cubit.load();
      await pumpEventQueue();

      await cubit.markRead('a');
      expect(cubit.state.items.first.read, isTrue);
      expect(cubit.state.unreadCount, 0);

      await cubit.markRead('b');
      expect(cubit.state.items.last.read, isTrue);
      expect(cubit.state.unreadCount, 0);
      expect(repository.markedRead, ['a', 'b']);
    });

    test('skips an item that is already read or not loaded', () async {
      repository.pages[0] = _page(0, [_item('a', read: true)]);
      await cubit.load();

      await cubit.markRead('a');
      await cubit.markRead('missing');

      expect(repository.markedRead, isEmpty);
    });

    test('a failure reloads silently, with no error shown', () async {
      repository.pages[0] = _page(0, [_item('a')]);
      await cubit.load();
      repository
        ..markError = const ApiException(
          message: 'Notification not found',
          code: 'NOTIFICATION_NOT_FOUND',
          statusCode: 404,
        )
        // The item is gone on the server.
        ..pages[0] = _page(0, const []);

      await cubit.markRead('a');

      expect(repository.listCalls, [0, 0]);
      expect(cubit.state.status, NotificationsStatus.loaded);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.errorMessage, isEmpty);
    });
  });

  group('markAllRead', () {
    test('marks every item read and zeroes the count', () async {
      repository
        ..pages[0] = _page(0, [_item('a'), _item('b')])
        ..count = 5;
      await cubit.load();
      await pumpEventQueue();

      await cubit.markAllRead();

      expect(cubit.state.items.every((item) => item.read), isTrue);
      expect(cubit.state.unreadCount, 0);
      expect(repository.markAllCalls, 1);
    });

    test('a failure reloads the server state', () async {
      repository
        ..pages[0] = _page(0, [_item('a')])
        ..count = 1;
      await cubit.load();
      await pumpEventQueue();
      repository.markError =
          const ApiException(message: 'Server error', statusCode: 500);

      await cubit.markAllRead();
      await pumpEventQueue();

      expect(repository.listCalls, [0, 0]);
      expect(cubit.state.items.single.read, isFalse);
      expect(cubit.state.unreadCount, 1);
    });
  });

  group('loadMore', () {
    test('appends the next page without duplicate ids', () async {
      repository
        ..pages[0] = _page(0, [_item('a'), _item('b')], totalPages: 2)
        // A new item pushed 'b' onto page 1 as well.
        ..pages[1] = _page(1, [_item('b'), _item('c')], totalPages: 2);
      await cubit.load();

      await cubit.loadMore();

      expect(ids(), ['a', 'b', 'c']);
      expect(cubit.state.currentPage, 1);
      expect(cubit.state.hasReachedMax, isTrue);
    });

    test('drops a page that lands after a reload restarted the list', () async {
      repository
        ..pages[0] = _page(0, [_item('a')], totalPages: 3)
        ..pages[1] = _page(1, [_item('b')], totalPages: 3)
        ..pages[2] = _page(2, [_item('c')], totalPages: 3);
      await cubit.load();
      await cubit.loadMore();
      final held = Completer<void>();
      repository.listHolds[2] = held;

      final more = cubit.loadMore();
      repository.pages[0] = _page(0, [_item('new'), _item('a')], totalPages: 3);
      await cubit.load(silent: true);
      held.complete();
      await more;

      expect(ids(), ['new', 'a']);
      expect(cubit.state.currentPage, 0);
      expect(cubit.state.status, NotificationsStatus.loaded);
    });
  });

  group('load failures', () {
    test('a silent one keeps the list and reports the error', () async {
      repository.pages[0] = _page(0, [_item('a')]);
      await cubit.load();
      repository.listError = _offline;

      await cubit.load(silent: true);

      expect(cubit.state.status, NotificationsStatus.loaded);
      expect(ids(), ['a']);
      expect(cubit.state.errorMessage, _offline.message);
    });

    test('a non-silent one shows the failure state', () async {
      repository.listError = _offline;

      await cubit.load();

      expect(cubit.state.status, NotificationsStatus.failure);
      expect(cubit.state.errorMessage, _offline.message);
    });
  });

  group('inbox changes', () {
    test('reload a list that is on screen', () async {
      repository.pages[0] = _page(0, [_item('a')]);
      await cubit.load();
      repository.pages[0] = _page(0, [_item('new'), _item('a')]);

      PushNotificationService.notifyInboxChanged();
      await pumpEventQueue();

      expect(ids(), ['new', 'a']);
    });

    test('only refresh the count before the list is loaded', () async {
      repository.count = 3;

      PushNotificationService.notifyInboxChanged();
      await pumpEventQueue();

      expect(repository.listCalls, isEmpty);
      expect(cubit.state.unreadCount, 3);
    });
  });

  test('a load that lands after close emits nothing', () async {
    final previousObserver = Bloc.observer;
    final observer = _ErrorObserver();
    Bloc.observer = observer;
    addTearDown(() => Bloc.observer = previousObserver);

    final heldList = Completer<void>();
    final heldCount = Completer<void>();
    repository
      ..listHolds[0] = heldList
      ..countHold = heldCount;

    final loading = cubit.load();
    await cubit.close();
    heldList.complete();
    heldCount.complete();
    await loading;
    await pumpEventQueue();

    expect(observer.errors, isEmpty);
  });
}
