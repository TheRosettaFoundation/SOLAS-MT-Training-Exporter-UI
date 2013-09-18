library CorpusUI;

import 'dart:html';
import 'dart:async';
import "package:json_object/json_object.dart";

class Settings
{
  static final Settings _instance = new Settings._internal();
  
  JsonObject _conf;
  JsonObject get conf => _conf;
  
  factory Settings()
  {
    return _instance;
  }
    
  Future<bool> loadConf()
  {
    Future<bool> ret = HttpRequest.getString("conf.json")
    //Future<bool> ret = HttpRequest.getString(query("#ConfFileLocation").attributes['value'])
               .then((String data) {
                 _instance._conf = new JsonObject.fromJsonString(data);
                 return true;
               }).catchError((e) {
                 print("Error loading conf file: $e");
                 return false;
               });
    return ret;
  }
  
  Settings._internal();
}