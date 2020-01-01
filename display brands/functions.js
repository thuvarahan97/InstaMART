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
                // var count = document.createElement("br")
            
                var textName = document.createTextNode(product_brand.product_brand);
                var textCount = document.createTextNode(" ("+product_brand.product_count+")");
                brand.appendChild(textName);
                brand.appendChild(textCount);
                console.log(brand)
                node.appendChild(brand);
                // node.appendChild(count);
                document.getElementById('product_brand').appendChild(node);
                
                // document.getElementById('product_brand').appendChild(count); 
            });
        }
    }
    xhttp.open("GET", "/brands", true);
    xhttp.send();
}


