const http = require('http');
const fs = require('fs');
const con = require("./DBConnection"); 

const hostname = '127.0.0.1'
const port = '3400'

const server = http.createServer((req, res) => {
    if(req.method == 'GET' && req.url == '/')
    {
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/html');
        fs.createReadStream('./index.html').pipe(res);
    }
    
    else if(req.method == "GET" && req.url == '/home')
    {
        res.statusCode == 200;
        res.setHeader('Content-Type', 'application/json');

        var conn = con.getConnection();

        conn.query('SELECT * FROM reviews.reviews order by date DESC', function(error, results, fields){
            if(error) throw error;
            
            var reviews = JSON.stringify(results);

            res.end(reviews);
        });

        conn.end(); 
    }
    else if(req.method == "POST" && req.url == "/insert")
    {
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain');

        var content = '';
        req.on('data', function(data){
            content += data;

            var obj = JSON.parse(content);

            console.log("The UserName is: "+ obj.name);
            console.log("The review is: "+ obj.message);
            var conn = con.getConnection();

            conn.query('INSERT INTO reviews.reviews (reviews.userName, reviews.review, reviews.date) VALUES (?,?,NOW())',[obj.name,obj.message], function(error, results, fields){
            if(error) throw error;
            console.log("Success!");
        });

        conn.end();
        res.end("Success!");
        });
    }
    else if(req.method == "GET" && req.url == '/functions.js')
    {
        res.writeHead(200, {"Content-Type":"text/javascript"});
        fs.createReadStream("./functions.js").pipe(res);
    }
});

server.listen(port, hostname, () =>{
    console.log(`Server running at http://${hostname}:${port}/`)
});