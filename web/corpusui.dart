import 'dart:html';
import 'dart:async';


void main() 
{
  var temp = new  CorpusUI();
  temp.init();
  
  
}



class CorpusUI 
{
  void init()
  {
    domainsInDatabase();
    
  }
  
  void domainsInDatabase()
  {
    var input = query("#a1");
    input.onClick.listen
    (
      (e)
      {
        var databaseName = query("#database-name");
        var url = "http://127.0.0.1:8080/databases/" + databaseName.value + "/domains";
        HttpRequest.getString(url).then
        (
          (response) 
          {
            query("#domain-list").text = "<li><a href=" + "#" + ">" + response.toString() + "</a></li>";
            print(response);
          }
        );
        
        // stop event
        //e.preventDefault();
        //e.stopPropagation();
      }
    );
    
    
  }
  
  

}
