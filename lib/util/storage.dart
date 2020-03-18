import 'package:localstorage/localstorage.dart';

class Storage {

  LocalStorage storage;

  Storage(){
    storage = new LocalStorage('LogTime');
  }

  bool isCounting() {
    return storage.getItem("counting") ?? false;
  }

  Future<void> setCounting(bool counting) async {
    await storage.setItem("counting", counting);
  }

}
