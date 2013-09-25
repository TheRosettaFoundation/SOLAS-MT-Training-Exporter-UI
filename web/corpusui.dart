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
    uniqueString = "vbi_fb";
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
      for (int i = 0; i < databases.length; i++) {
        LIElement db = new LIElement();
        AnchorElement link = new AnchorElement()
        ..id = "database_$i"
        ..text = databases[i];
        link.onClick.listen((MouseEvent e) => databaseClicked(e));
        db.append(link);
        databaseList.append(db);
      }
      databaseSelect.innerHtml = "";
      databaseSelect.append(databaseList);
    });
    ButtonElement element;
    element = query("#download-selected");
    element.onClick.listen((MouseEvent e) => this.downloadSelectedClicked(e));
    element = query("#download-all");
    element.onClick.listen((MouseEvent e) => this.downloadAllClicked(e));
    element = query("#file-upload-button");
    element.onClick.listen((MouseEvent e) => this.uploadFile(e));
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
        AnchorElement oldSelected = query("#database_" + selectedDatabase.toString());
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
        AnchorElement oldSelected = query("#domain_" + selectedDomain.toString());
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
    for (int i = 0; i < domains.length; i++) {
      LIElement domainEntry = new LIElement();
      AnchorElement link = new AnchorElement()
      ..id = "domain_$i"
      ..text = domains[i];
      link.onClick.listen((MouseEvent e) => domainClicked(e));
      domainEntry.append(link);
      domainList.append(domainEntry);
    }
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
    for (int i = 0; i < docIds.length; i++) {
      LIElement docEntry = new LIElement();
      AnchorElement link = new AnchorElement()
      ..id = "doc_$i"
      ..text = docIds[i];
      link.onClick.listen((MouseEvent e) => documentClicked(e));
      docEntry.append(link);
      documentList.append(docEntry);
    }
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
  
  void uploadFile(MouseEvent e)
  {
    this.clearUploadFeedback();
    File xliffFile;
    InputElement fileInput = query("#file-upload");
    FileList files = fileInput.files;
    if (files.length > 0) {
      xliffFile = files.elementAt(0);
      if (xliffFile.type == "application/x-xliff") {
        InputElement dbNameInput = query("#file-db-name");
        String dbName = dbNameInput.value;
        if (dbName.length > 0) {
          CorpusHelper.uploadXliffFile(xliffFile, dbName)
          .then((bool success) {
            if (success) {
              this.displayUploadSuccess("Yor file has been uploaded successfully");
            } else {
              this.displayUploadError("Your file was rejected by the server");
            }
          });
        } else {
          this.displayUploadError("Please enter the name of the database you want to store the file in");
        }
      } else {
        this.displayUploadError("The file you uploaded is not an Xliff. Please use a file with an xliff or xlf extension");
      }
    } else {
      this.displayUploadError("You must select a file to upload");
    }
  }
  
  void displayUploadError(String error)
  {
    DivElement errorDiv = query("#file-upload-feedback");
    errorDiv.classes.add("alert");
    errorDiv.classes.add("alert-danger");
    ParagraphElement errorText = new ParagraphElement()
    ..text = error;
    errorDiv.append(errorText);
  }
  
  void displayUploadSuccess(String message)
  {
    DivElement feedbackDiv = query("#file-upload-feedback");
    feedbackDiv.classes.add("alert");
    feedbackDiv.classes.add("alert-success");
    ParagraphElement successText = new ParagraphElement()
    ..text = message;
    feedbackDiv.append(successText);
  }
  
  void clearUploadFeedback()
  {
    DivElement errorDiv = query("#file-upload-feedback");
    errorDiv.classes.remove("alert");
    errorDiv.classes.remove("alert-danger");
    errorDiv.classes.remove("alert-success");
    errorDiv.innerHtml = "";
  }
}
