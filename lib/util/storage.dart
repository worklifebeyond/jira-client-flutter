import 'package:jira_time/models/logtime.dart';
import 'package:localstorage/localstorage.dart';

class Storage {

  LocalStorage storage;

  Storage(){
    storage = new LocalStorage('LogTime');
  }

  bool isCounting() {
    return storage.getItem("counting") ?? false;
  }

  String getUser(){
    Map<String, dynamic> m = storage.getItem("user");
    return m['user'];
  }

  Future<void> setUser(String user) async {
    Map<String, dynamic> m = new Map();
    m['user'] = user;
    await storage.setItem("user", m);
  }

  Future<void> setCounting(bool counting) async {
    await storage.setItem("counting", counting);
  }

  LogTime getCurrentLog(){
    return LogTime.fromMap(storage.getItem("log"));
  }

  Future<void> setLogTime(LogTime logTime) async {
    await storage.setItem("log", logTime.toMap());
  }

}
