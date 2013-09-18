library CorpusUI;

import 'dart:async';
import 'dart:html';

import "Settings.dart";

class APIHelper
{ 
  static Future<HttpRequest> call(String url, String method, 
                      [dynamic data = '', Map queryArgs = null])
  {
    Completer<HttpRequest> complete = new Completer<HttpRequest>();
    Map<String, String> headers = new Map<String, String>();
    Settings settings = new Settings();
    url = settings.conf.urls.corpus + url + "/";

    if (queryArgs != null) {
      url += "?";
      queryArgs.keys.forEach((String key) {
        url += key + "=" + queryArgs[key] + "&";
      });
    }
    
    HttpRequest request = new HttpRequest();
    request.open(method, url);
    request.onLoadEnd.listen((e) {
      complete.complete(request);
    });
    request.send(data);
    
    return complete.future;
  }
}
