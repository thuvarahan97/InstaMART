var connection = require('./../config');

exports.checkout = function(req, res){
    var mode = 'signup';
    var output = 'error';
    var message = '';
    
    if(req.method == "POST"){
    //    var firstname = req.body.firstname.charAt(0).toUpperCase() + req.body.firstname.slice(1).toLowerCase();
    //    var lastname = req.body.lastname.charAt(0).toUpperCase() + req.body.lastname.slice(1).toLowerCase();
    //    var email = req.body.email;
    //    var username = req.body.username;
    //    var password = req.body.password;
    //    var encryptedString = cryptr.encrypt(password);
    //    connection.query('SELECT RegisterUser(?,?,?,?,?) AS output',[username,firstname,lastname,email,encryptedString], function (error, result, fields) {
    //       if (error) {
    //          message = "Error occured! Try again.";
    //          res.render('login.ejs',{mode: mode, output: output, message: message});
    //       }
    //       else{
    //          switch (result[0]['output']){
    //             case 'null_values':
    //                message = "Some fields are empty!";
    //                res.render('login.ejs',{mode: mode, output: output, message: message});
    //             break;
    //             case 'email_exists':
    //                message = "Email already exists!";
    //                res.render('login.ejs',{mode: mode, output: output, message: message});
    //             break;
    //             case 'username_exists':
    //                message = "Username already exists!";
    //                res.render('login.ejs',{mode: mode, output: output, message: message});
    //             break;
    //             case 'success':
    //                output = 'success';
    //                message = "Your account has been created successfully!";
    //                res.render('login.ejs',{mode: mode, output: output, message: message});
    //             break;
    //          }
    //       }
    //    });
    } 
    else {
       if (req.session.loggedin) {
            res.render('checkout.ejs',{mode: mode, output: output, message: message});
       }
       else {
            res.render('checkout.ejs',{mode: mode, output: output, message: message});   
       }
    }
 };