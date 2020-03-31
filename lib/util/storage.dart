import 'package:jira_time/models/logtime.dart';
import 'package:localstorage/localstorage.dart';

class Storage {

  LocalStorage storage;

  Storage(){
    storage = new LocalStorage('LogTime');
  }

  Future<bool> isCounting() async {
    Map<String, dynamic> m = storage.getItem("counting");
    await storage.ready;
    if(m == null) return false;
    else return m['counting'];
  }

  Future<void> setCounting(bool counting) async {
    await storage.ready;
    Map<String, dynamic> m = new Map();
    m['counting'] = counting;
    await storage.setItem("counting", m);
  }

  Future<String> getUser() async {
    await storage.ready;
    Map<String, dynamic> m = storage.getItem("user");
    return m['user'];
  }

  Future<void> setUser(String user) async {
    await storage.ready;
    Map<String, dynamic> m = new Map();
    m['user'] = user;
    await storage.setItem("user", m);
  }



  LogTime getCurrentLog(){
    return LogTime.fromMap(storage.getItem("log"));
  }

  Future<void> setLogTime(LogTime logTime) async {
    await storage.setItem("log", logTime.toMap());
  }

}
