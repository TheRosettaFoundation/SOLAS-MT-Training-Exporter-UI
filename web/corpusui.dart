import 'dart:html';
import 'dart:async';

import "Settings.dart";
import "CorpusHelper.dart";

void main() 
{
  Settings settings = new Settings();
  settings.loadConf().then((bool success) {
    CorpusUI app = new  CorpusUI();
    app.init();
  });
}

class CorpusUI 
{
  List<String> databases;
  List<String> domains;
  List<String> docIds;
  String uniqueString;
  
  int selectedDatabase;
  int selectedDomain;
  List<int> selectedDocs;
  
  CorpusUI()
  {
    uniqueString = "jbseakyugrfvbi_fbveaiun";
    selectedDatabase = -1;
    selectedDomain = -1;
    selectedDocs = new List<int>();
    databases = new List<String>();
    domains = new List<String>();
    docIds = new List<String>();
  }
  
  void init()
  {
    this.loadDatabases().then((bool success) {
      DivElement databaseSelect = query("#database-select");
      UListElement databaseList = new UListElement()
      ..classes.add("nav")
      ..classes.add("nav-pills")
      ..classes.add("nav-stacked");
      databases.forEach((String dbName) {
        LIElement db = new LIElement();
        AnchorElement link = new AnchorElement()
        ..id = dbName.replaceAll(" ", uniqueString)
        ..text = dbName;
        link.onClick.listen((MouseEvent e) => databaseClicked(e));
        db.append(link);
        databaseList.append(db);
      });
      databaseSelect.innerHtml = "";
      databaseSelect.append(databaseList);
    });
    ButtonElement element;
    element = query("#download-selected");
    element.onClick.listen((MouseEvent e) => this.downloadSelectedClicked(e));
    element = query("#download-all");
    element.onClick.listen((MouseEvent e) => this.downloadAllClicked(e));
  }
  
  Future<bool> loadDatabases()
  {
    Completer<bool> complete = new Completer<bool>();
    CorpusHelper.getCorpusDatabases()
    .then((List<String> dbs) {
      databases = dbs;
      complete.complete(true);
    });
    return complete.future;
  }
  
  Future<bool> loadDomains()
  {
    Completer<bool> complete = new Completer<bool>();
    domains.clear();
    docIds.clear();
    CorpusHelper.getDatabaseDomains(databases.elementAt(selectedDatabase))
    .then((List<String> doms) {
      domains = doms;
      complete.complete(true);
    });
    return complete.future;
  }
  
  Future<bool> loadDocuments()
  {
    Completer<bool> complete = new Completer<bool>();
    docIds.clear();
    CorpusHelper.getDomainDocuments(databases.elementAt(selectedDatabase), domains.elementAt(selectedDomain))
    .then((List<String> docs) {
      docIds = docs;
      complete.complete(true);
    });
    return complete.future;
  }
  
  void databaseClicked(MouseEvent e)
  {
    int clickedIndex = databases.indexOf(e.target.text);
    if (clickedIndex != selectedDatabase) {
      if (selectedDatabase >= 0) {
        AnchorElement oldSelected = query("#" + databases.elementAt(selectedDatabase).replaceAll(" ", uniqueString));
        oldSelected.parent.classes.remove("active");
      }
      selectedDatabase = clickedIndex;
      selectedDomain = -1;
      e.target.parent.classes.add("active");
      this.loadDomains()
      .then((bool loaded) {
        this.databaseChanged();
        this.domainChanged();
      });
    }
  }
  
  void domainClicked(MouseEvent e)
  {
    int clickedElement = domains.indexOf(e.target.text);
    if (selectedDomain != clickedElement) {
      if (selectedDomain >= 0) {
        AnchorElement oldSelected = query("#" + domains.elementAt(selectedDomain).replaceAll(" ", uniqueString));
        oldSelected.parent.classes.remove("active");
      }
      selectedDomain = clickedElement;
      e.target.parent.classes.add("active");
      this.loadDocuments()
      .then((bool loaded) {
        this.domainChanged();
      });
    }
  }
  
  void documentClicked(MouseEvent e)
  {
    bool active = e.target.parent.classes.contains("active");
    if (active) {
      selectedDocs.remove(docIds.indexOf(e.target.attributes['id']));
      e.target.parent.classes.remove("active");
    } else {
      selectedDocs.add(docIds.indexOf(e.target.attributes['id']));
      e.target.parent.classes.add("active");
    }
  }
  
  void databaseChanged()
  {
    DivElement domainSelect = query("#domain-select");
    UListElement domainList = new UListElement()
    ..classes.add("nav")
    ..classes.add("nav-pills")
    ..classes.add("nav-stacked");
    domains.forEach((String domain) {
      LIElement domainEntry = new LIElement();
      AnchorElement link = new AnchorElement()
      ..id = domain.replaceAll(" ", uniqueString)
      ..text = domain;
      link.onClick.listen((MouseEvent e) => domainClicked(e));
      domainEntry.append(link);
      domainList.append(domainEntry);
    });
    domainSelect.innerHtml = "";
    domainSelect.append(domainList);
  }
  
  void domainChanged()
  {
    selectedDocs.clear();
    DivElement documentSelect = query("#document-select");
    UListElement documentList = new UListElement()
    ..classes.add("nav")
    ..classes.add("nav-pills")
    ..classes.add("nav-stacked");
    docIds.forEach((String docId) {
      LIElement docEntry = new LIElement();
      AnchorElement link = new AnchorElement()
      ..id = docId
      ..text = docId;
      link.onClick.listen((MouseEvent e) => documentClicked(e));
      docEntry.append(link);
      documentList.append(docEntry);
    });
    documentSelect.innerHtml = "";
    documentSelect.append(documentList);
  }
  
  void downloadAllClicked(MouseEvent e)
  {
    InputElement fullTextRadioBtn = query("#fullDocRadioBtn");
    bool fullDoc = fullTextRadioBtn.checked;
    if (selectedDatabase >= 0 && selectedDomain >= 0) {
      IFrameElement mFrame = query("#download-frame");
      if (fullDoc) {
        mFrame.attributes['src'] = 
            CorpusHelper.constructDownloadAllString(
                databases.elementAt(selectedDatabase), 
                domains.elementAt(selectedDomain), true);
      } else {
        mFrame.attributes['src'] = 
            CorpusHelper.constructDownloadAllString(
                databases.elementAt(selectedDatabase), 
                domains.elementAt(selectedDomain), false);
      }
    } else {
      print("Failed to download files, no database or domain selected");
    }
  }
  
  void downloadSelectedClicked(MouseEvent e)
  {
    InputElement fullTextRadioBtn = query("#fullDocRadioBtn");
    bool fullDoc = fullTextRadioBtn.checked;
    if (selectedDatabase >= 0 && selectedDomain >= 0) {
      if (selectedDocs.length > 0) {
        List<String> selectedIds = new List<String>();
        selectedDocs.forEach((int index) {
          selectedIds.add(docIds.elementAt(index));
        });
        IFrameElement mFrame = query("#download-frame");
        if (fullDoc) {
          mFrame.attributes['src'] = 
              CorpusHelper.constructDownloadSelectedString(
                  databases.elementAt(selectedDatabase), 
                  domains.elementAt(selectedDomain), 
                  selectedIds, true);
        } else {
          mFrame.attributes['src'] = 
              CorpusHelper.constructDownloadSelectedString(
                  databases.elementAt(selectedDatabase), 
                  domains.elementAt(selectedDomain), 
                  selectedIds, false);
        }
      } else {
        print("Failed to download files, not docs selected");
      }
    } else {
      print("Failed to download files, no database or domain selected");
    }
  }
}
