const mysql = require('mysql');

function getConnection(){
    var con = mysql.createConnection({
        host:"localhost",
        user:"root",
        password:"",
        database:"sem4_dbms_project"
    });
    return con;
}

module.exports.getConnection = getConnection;