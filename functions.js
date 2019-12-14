function loadreviews(){
    var xhttp = new XMLHttpRequest();

    xhttp.onreadystatechange = function() {
        if(this.readyState == 4 && this.status == 200)
        {
            document.getElementById('reviews').innerHTML = '';
            var result = this.responseText;
            var results = JSON.parse(result);

            results.forEach((review)=>
            {
            var node = document.createElement("div");
            var name = document.createElement("H5");
            var date = document.createElement("H6");
            var message = document.createElement("P");

            var textName = document.createTextNode('Name: ' + review.userName);
            var textDate = document.createTextNode('Date: ' +review.date);
            var textMessage = document.createTextNode(review.review);

            name.appendChild(textName);
            date.appendChild(textDate);
            message.appendChild(textMessage);

            node.appendChild(name);
            node.appendChild(date);
            node.appendChild(message);

            document.getElementById('reviews').appendChild(node);

            });
        }
    }

    xhttp.open("GET", "/view", true);
    xhttp.send();
}

function insertreview()
{
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function(){
        if(this.readyState == 4 && this.status == 200)
        {
        var result = this.responseText;
        console.log(result);
        loadreviews();
        } 
    }

    var name = document.getElementById('name').value;
    var message = document.getElementById('message').value;

    xhttp.open("POST", "/insert", true);
    xhttp.setRequestHeader("Content-Type", "application/json");
    xhttp.send('{"name":"'+name+'", "message":"'+message+'"}');

}
