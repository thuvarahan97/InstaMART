var connection = require('./../config');
var Cryptr = require('cryptr');
var cryptr = new Cryptr('UserPassword');

module.exports.authenticate = function(req,res){
  var username = req.body.username;
  var password = req.body.password;

  connection.query('SELECT * FROM tbl_users WHERE username = ?',[username], function (error, results, fields) {
    if (error) {
      // res.json({
      //   status:false,
      //   message:'There are some errors with query.'
      // });
      res.redirect('/login');
      res.end();
    }
    else {
      if (results.length > 0) {
        decryptedString = cryptr.decrypt(results[0].password);
        if (password == decryptedString) {
          // res.json({
          //   status:true,
          //   message:'Successfully authenticated!'
          // });
          req.session.loggedin = true;
  				req.session.username = username;
          // res.redirect('/login');
          var message = '';
          message = 'Successfully Logged-in!';
          res.render('login',{login_message: message});
        }
        else {
          // res.json({
          //   status:false,
          //   message:"Username and password do not match."
          // });
          // res.redirect('/login');
          var message = '';
          message = 'Successfully Logged-in!';
          res.render('login.ejs',{login_message: message});
        }
        res.end();
      }
      else {
        // res.json({
        //   status:false,    
        //   message:"Username does not exist."
        // });
        // res.redirect('/login');
          var message = '';
          message = 'Successfully Logged-in!';
          res.render('login.ejs',{login_message: message});
        res.end();
      }
    }
  });

}