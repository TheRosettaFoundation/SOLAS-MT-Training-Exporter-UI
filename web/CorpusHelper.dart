library CorpusUI;

import "dart:async";
import "dart:html";

import "APIHelper.dart";
import "Settings.dart";

class CorpusHelper
{
  static Future<List<String>> getCorpusDatabases()
  {
    Future<List<String>> ret = APIHelper.call("dbs", "GET")
    .then((HttpRequest response) {
      List<String> databases = new List<String>();
      if (response.status < 400) {
        if (response.responseText.length > 0) {
          DomParser parser = new DomParser();
          Document doc = parser.parseFromString(response.responseText, "text/xml");
          ElementList dbs = doc.queryAll("db");
          dbs.forEach((Element db) {
            databases.add(db.attributes['id']);
          });
        } else {
          print("getCorpusDatabases didn't return anything");
        }
      }
      return databases;
    });
    return ret;
  }
  
  static Future<List<String>> getDatabaseDomains(String database)
  {
    Future<List<String>> ret = APIHelper.call("dbs/$database/domains", "GET")
    .then((HttpRequest response) {
      List<String> domains = new List<String>();
      if (response.status < 400) {
        if (response.responseText.length > 0) {
          DomParser parser = new DomParser();
          Document doc = parser.parseFromString(response.responseText, "text/xml");
          ElementList domainElements= doc.queryAll("domain");
          domainElements.forEach((Element domain) {
            domains.add(domain.attributes['id']);
          });
        } else {
          print("getDatabaseDomains didn't return anything");
        }
      }
      return domains;
    });
    return ret;
  }
  
  static Future<List<String>> getDomainDocuments(String database, String domain)
  {
    Future<List<String>> ret = APIHelper.call("dbs/$database/domains/$domain", "GET")
    .then((HttpRequest response) {
      List<String> docIds = new List<String>();
      if (response.status < 400) {
        if (response.responseText.length > 0) {
          DomParser parser = new DomParser();
          Document doc = parser.parseFromString(response.responseText, "text/xml");
          ElementList docs = doc.queryAll("doc");
          docs.forEach((Element doc) {
            docIds.add(doc.attributes['id']);
          });
        } else {
          print("getDomainDocuments didn't return anything");
        }
      }
      return docIds;
    });
    return ret;
  }
  
  static Future<bool> uploadXliffFile(File file, String dbName)
  {
    Completer<bool> completer = new Completer<bool>();
    FileReader reader = new FileReader();
    reader.onLoadEnd.listen((e) {
      dbName = Uri.encodeComponent(dbName);
      APIHelper.call("dbs/$dbName/docs", "POST", e.target.result)
      .then((HttpRequest response) {
        bool success = false;
        if (response.status < 400) {
          success = true;
        } else {
          print("Failed to upload file, server responded with: ");
          print(response.status.toString() + ": " + response.responseText);
        }
        completer.complete(success);
      });
    });
    reader.readAsArrayBuffer(file);
    return completer.future;
  }
  
  static String constructDownloadAllString(String database, String domain, [bool fullDocs = true])
  {
    Settings settings = new Settings();
    String url = settings.conf.urls.corpus + "dbs/$database/domains/$domain/";
    if (fullDocs) {
      url += "docs/";
    } else {
      url += "trans-units/";
    }
    return url;
  }
  
  static String constructDownloadSelectedString(String database, String domain, 
                                                List<String> docIds, [bool fullDocs = true])
  {
    Settings settings = new Settings();
    String url = settings.conf.urls.corpus + "dbs/$database/domains/$domain/";
    if (fullDocs) {
      url += "docs/";
    } else {
      url += "trans-units/";
    }
    String queryString = "?docIds='";
    if (docIds.length > 0) {
      docIds.forEach((String docId) {
        queryString += docId + "|";
      });
      queryString = queryString.substring(0, queryString.length - 1);
    }
    queryString += "'";
    return url + queryString;
  }
}