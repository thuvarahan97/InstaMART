var connection = require('./../config');
var Cryptr = require('cryptr');
var cryptr = new Cryptr('UserPassword');

module.exports.authenticate = function(req,res){
  var username = req.query.username;
  var password = req.query.password;

  connection.query('SELECT * FROM tbl_users WHERE username = ?',[username], function (error, results, fields) {
    if (error) {
      res.json({
        status:false,
        message:'There are some errors with query.'
      });
    }
    else {
      if (results.length > 0) {
        decryptedString = cryptr.decrypt(results[0].password);
        if (password == decryptedString) {
          res.json({
            status:true,
            message:'Successfully authenticated!'
          });
        }
        else {
          res.json({
            status:false,
            message:"Username and password do not match."
          });
        }
      }
      else {
        res.json({
          status:false,    
          message:"Username does not exist."
        });
      }
    }
  });

}