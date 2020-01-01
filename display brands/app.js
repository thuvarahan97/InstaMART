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
    
    else if (req.method == "GET" && req.url == '/brands')
    {
        var connection=con.getConnection();
        connection.query('select * from view_product_brands', function(error, results, fields)
        {
            if(error) throw error;
            var product_brand = JSON.stringify(results);
            res.end(product_brand);
        });
        connection.end();
    }

    else if(req.method == "GET" && req.url == '/functions.js')
    {
    fs.createReadStream("./functions.js").pipe(res);
    }
});

server.listen(port, hostname, () =>{
    console.log(`Server running at http://${hostname}:${port}/`)
});