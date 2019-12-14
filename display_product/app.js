const http = require('http');
const fs = require('fs');
const con = require("./DBConnection"); 
const hostname = '127.0.0.1'
const port = '3400'

const server = http.createServer((req, res) => {
    if(req.method == 'GET' && req.url == '/')
    {
        fs.createReadStream('./index.html').pipe(res);
    }
    
    else if(req.method == "GET" && req.url == '/product')
    {
        var conn = con.getConnection();
        conn.query('SELECT * FROM tbl_products', function(error, results, fields)
        {
            if(error) throw error;
            var products = JSON.stringify(results);
            res.end(products);
        });
        conn.end(); 
    }

    else if(req.method == "GET" && req.url == '/functions.js')
    {
    fs.createReadStream("./functions.js").pipe(res);
    }
});

server.listen(port, hostname, () =>{
    console.log(`Server running at http://${hostname}:${port}/`)
});