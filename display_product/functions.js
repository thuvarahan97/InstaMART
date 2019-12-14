function loadproducts(){
    
    var xhttp = new XMLHttpRequest();

    xhttp.onreadystatechange = function() {
        if(this.readyState == 4 && this.status == 200)
        {
            document.getElementById('products').innerHTML = '';
            var result = this.responseText;
            var results = JSON.parse(result);

            results.forEach((product)=>

            {
            
            var node = document.createElement("div");
            var product_name = document.createElement("H3");
            var product_brand = document.createElement("H5");
            var product_description = document.createElement("P");
            var img = document.createElement("img");
            

            var textName = document.createTextNode('Product Name: ' +product.product_name);
            var textBrand = document.createTextNode('Product Brand: ' + product.product_brand);
            var textImage = document.createTextNode(product.product_image);
            var textDescription = document.createTextNode('Product Description: ' + product.product_description);
            

            product_name.appendChild(textName);
            product_brand.appendChild(textBrand);
            product_description.appendChild(textDescription);
            
            img.src =textImage;

            console.log(textImage)

            node.appendChild(product_name);
            node.appendChild(product_brand);
            node.appendChild(img);
            node.appendChild(product_description);

            document.getElementById('products').appendChild(node);

            });
        }
    }
    xhttp.open("GET", "/product", true);
    xhttp.send();
}

