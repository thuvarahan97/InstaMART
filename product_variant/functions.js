function loadvariants(){
    
    var xhttp = new XMLHttpRequest();

    xhttp.onreadystatechange = function() {
        if(this.readyState == 4 && this.status == 200)
        {
            document.getElementById('skus').innerHTML = '';
            var result = this.responseText;
            var results = JSON.parse(result);

            results.forEach((result)=>

            {
            
            var list = result.attribute_value.split(',');

            var node = document.createElement("div");
            var attribute_name = document.createElement("H3");
            var attribute_value = document.createElement("H5");
            

            var textName = document.createTextNode(result.attribute_name);
            for (var i=0; i<list.length; i++){
                var radio_button = document.createElement("INPUT");
                radio_button.setAttribute("type", "radio");
                radio_button.setAttribute("name",result.attribute_name);
                radio_button.setAttribute("value", list[i]);
                radio_button.setAttribute("class",result.attribute_name);
                var linebreak = document.createElement("br");
                var textValue = document.createTextNode(list[i]);
                
                attribute_value.appendChild(radio_button);
                attribute_value.appendChild(textValue);
                attribute_value.appendChild(linebreak);
                
            }

            attribute_name.appendChild(textName);
            
            node.appendChild(attribute_name);
            node.appendChild(attribute_value);
            
            document.getElementById('skus').appendChild(node);

            });
        }
    }
    xhttp.open("GET", "/product", true);
    xhttp.send();
}

function displayRadioValue() { 
    document.getElementById("skus").innerHTML = ""; 
    var ele = document.getElementsByTagName("INPUT"); 
      
    for(i = 0; i < ele.length; i++) { 
          
            if(ele[i].checked){
            document.getElementById("skus").innerHTML 
                        += ele[i].name + " Value: " 
                        + ele[i].value + "<br>"; 
        } 
    } 
} 