import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showFriendRequestReceivedNotification(
    String friendUsername,
  ) async {
    await _showNotification(
      id: 2001,
      title: 'New Friend Request',
      body: '$friendUsername sent you a friend request!',
    );
  }

  Future<void> showFriendRequestAcceptedNotification(
    String friendUsername,
  ) async {
    await _showNotification(
      id: 2002,
      title: 'Friend Request Accepted',
      body: '$friendUsername accepted your friend request!',
    );
  }

  Future<void> showFriendRequestRejectedNotification(
    String friendUsername,
  ) async {
    await _showNotification(
      id: 2003,
      title: 'Friend Request Rejected',
      body: '$friendUsername rejected your friend request.',
    );
  }

  Future<void> showBattleChallengeReceivedNotification(
    String friendUsername,
  ) async {
    await _showNotification(
      id: 2004,
      title: 'Battle Challenge!',
      body: '$friendUsername challenged you to a battle!',
    );
  }

  Future<void> showBattleChallengeAcceptedNotification(
    String friendUsername,
  ) async {
    await _showNotification(
      id: 2005,
      title: 'Challenge Accepted',
      body: '$friendUsername accepted your battle challenge!',
    );
  }

  Future<void> showBattleChallengeDeclinedNotification(
    String friendUsername,
  ) async {
    await _showNotification(
      id: 2006,
      title: 'Challenge Declined',
      body: '$friendUsername declined your battle challenge.',
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'battleboats_events',
      'Battle Events',
      channelDescription: 'Notifications for friend requests and battles',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
