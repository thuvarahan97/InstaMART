function loadcategories(){
    
    var xhttp = new XMLHttpRequest();

    xhttp.onreadystatechange = function() {
        if(this.readyState == 4 && this.status == 200)
        {
            document.getElementById('categories').innerHTML = '';
            var result = this.responseText;
            var results = JSON.parse(result);

            results.forEach((category)=>{
                var node = document.createElement("div");
                var category_name = document.createElement("H3");
            
                var textName = document.createTextNode(category.category_name);
           
                category_name.appendChild(textName);

                node.appendChild(category_name);
          
                document.getElementById('categories').appendChild(node);
            });
        } 
    }
    xhttp.open("GET", "/category", true);
    xhttp.send();
}

function loadbrands(){
    
    var xhttp = new XMLHttpRequest();

    xhttp.onreadystatechange = function() {
        if(this.readyState == 4 && this.status == 200)
        {
            document.getElementById('product_brand').innerHTML = '';
            var result = this.responseText;
            var results = JSON.parse(result);

            results.forEach((product_brand)=>{
                var node = document.createElement("div");
                var brand = document.createElement("H3");
            
                var textName = document.createTextNode(product_brand.product_brand);
           
                brand.appendChild(textName);

                node.appendChild(brand);
          
                document.getElementById('product_brand').appendChild(node);
            });
        }
    }
    xhttp.open("GET", "/brands", true);
    xhttp.send();
}


