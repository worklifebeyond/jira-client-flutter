import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jira_time/models/logtime.dart';

class LocalNotification {
  Function onSelect = (String payload) async {
    print('notification payload: ' + payload);
  };
  final _settingsAndroid = AndroidInitializationSettings('logo');
  final _settingsIOS = IOSInitializationSettings();
  var _notification;

  display(LogTime logTime) {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, autoCancel: false, ongoing: true);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    _notification.show(0, '[${logTime.issueKey}] Your Work Log is in Progress', logTime.taskName, platformChannelSpecifics, payload: logTime.toMap().toString());
  }

  Future<void> cancelAll() async {
    await _notification.cancelAll();
  }

  LocalNotification({this.onSelect}) {
    _notification = FlutterLocalNotificationsPlugin()
      ..initialize(InitializationSettings(_settingsAndroid, _settingsIOS),
          onSelectNotification: onSelect);
  }
}
