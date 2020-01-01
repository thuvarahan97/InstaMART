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
        conn.query('SELECT attribute_name,GROUP_CONCAT(DISTINCT attribute_value) as attribute_value FROM tbl_product_variant_details GROUP BY attribute_name', function(error, results)
        {
            if(error) throw error;
            var value = JSON.stringify(results);
            res.end(value);
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