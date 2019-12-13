var connection = require('./../config');
var Cryptr = require('cryptr');
var cryptr = new Cryptr('InstaMARTUserPassword');

//---------------------------------------------signup page call------------------------------------------------------
exports.signup = function(req, res){
   var mode = 'signup';
   var output = 'error';
   var message = '';
   
   if(req.method == "POST"){
      var firstname = req.body.firstname.charAt(0).toUpperCase() + req.body.firstname.slice(1).toLowerCase();
      var lastname = req.body.lastname.charAt(0).toUpperCase() + req.body.lastname.slice(1).toLowerCase();
      var email = req.body.email;
      var username = req.body.username;
      var password = req.body.password;
      var encryptedString = cryptr.encrypt(password);
      connection.query('SELECT RegisterUser(?,?,?,?,?) AS output',[username,firstname,lastname,email,encryptedString], function (error, result, fields) {
         if (error) {
            message = "Error occured! Try again.";
            res.render('login.ejs',{mode: mode, output: output, message: message});
         }
         else{
            switch (result[0]['output']){
               case 'null_values':
                  message = "Some fields are empty!";
                  res.render('login.ejs',{mode: mode, output: output, message: message});
               break;
               case 'email_exists':
                  message = "Email already exists!";
                  res.render('login.ejs',{mode: mode, output: output, message: message});
               break;
               case 'username_exists':
                  message = "Username already exists!";
                  res.render('login.ejs',{mode: mode, output: output, message: message});
               break;
               case 'success':
                  output = 'success';
                  message = "Your account has been created successfully!";
                  res.render('login.ejs',{mode: mode, output: output, message: message});
               break;
            }
         }
      });
   } 
   else {
      if (req.session.loggedin) {
         res.redirect('/')
      }
      else {
         res.render('login.ejs',{mode: mode, output: output, message: message});   
      }
   }
};
 
//-----------------------------------------------login page call------------------------------------------------------
exports.login = function(req, res){
   var mode = 'login';
   var output = 'error';
   var message = '';

   if(req.method == "POST"){
      var username = req.body.username;
      var password = req.body.password;

      connection.query('SELECT * FROM tbl_users WHERE username = ?',[username], function (error, results, fields) {
         if (error) {
            message = 'Error occured! Try again.';
            res.render('login.ejs',{mode: mode, output: output, message: message});
         }
         else {
            if (results.length > 0) {
               decryptedString = cryptr.decrypt(results[0].password);
               if (password == decryptedString) {
                  req.session.loggedin = true;
                  req.session.user_id = results[0].user_id;
                  req.session.username = username;
                  res.redirect('/');
               }
               else {
                  message = 'Username and password do not match.';
                  res.render('login.ejs',{mode: mode, output: output, message: message});
               }
            }
            else {
               message = 'Username does not exist!';
               res.render('login.ejs',{mode: mode, output: output, message: message});
            }
         }
      });
   } 
   else {
      if (req.session.loggedin == true) {
         res.redirect('/');
      }
      else {
         res.render('login.ejs',{mode: mode, output: output, message: message}); 
      }
   }           
};

//------------------------------------logout functionality----------------------------------------------
exports.logout=function(req,res){
   req.session.destroy(function(err) {
      res.redirect("/login");
   })
};