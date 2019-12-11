var connection = require('./../config');
var Cryptr = require('cryptr');
var cryptr = new Cryptr('UserPassword');

module.exports.register = function(req,res){
  // var today = new Date();
  // var customers = {
  //   "email":req.query.email,
  //   "customer_type":req.query.customer_type
  // }
  var encryptedString = cryptr.encrypt(req.body.password);

  // connection.query('INSERT INTO tbl_customers SET ?',customers, function (error1, results1, fields1) {
  //   if (error1) {
  //     res.json({
  //       status:false,
  //       message:"Unable to insert data into customers table."
  //     });
  //   }
  //   else{
  //     var users = {
  //       "user_id":results1.insertId,
  //       "username":req.query.username,
  //       "firstname":req.query.firstname,
  //       "lastname":req.query.lastname,
  //       "password":encryptedString,
  //       "date_registered":today
  //     }
      
  //     connection.query('INSERT INTO tbl_users SET ?',users, function (error2, results2, fields2) {
  //       if (error2) {
  //         res.json({
  //           status:false,
  //           message:"Unable to insert data into users table."
  //         });
  //       }else{
  //         res.json({
  //           status:true,
  //           message:'User registered successfully!'
  //         });
  //       }
  //     });
  //   }
    
  // });

  connection.query('SELECT RegisterUser(?,?,?,?,?) AS output',[req.body.username,req.body.firstname,req.body.lastname,req.body.email,encryptedString], function (error, result, fields) {
    if (error) {
      res.redirect('/login');
    }
    else{
      switch (result[0]['output']){
        case 'null_values':
            res.redirect('/login');
          break;
        case 'email_exists':
            res.redirect('/login');
          break;
        case 'username_exists':
            res.redirect('/login');
          break;
        case 'success':
            res.redirect('/login.html?msg=success');
          break;
      }
    }
  });

}