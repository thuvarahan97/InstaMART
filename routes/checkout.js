var connection = require('./../config');

exports.viewCheckout = function(req, res){
     var mode = 'signup';
     var output = 'error';
     var message = '';
     
     if(req.method == "POST"){
          
          connection.query('SELECT * FROM view_cart_items WHERE customer_id=?', '0000000086', function (error, result, fields) {
               if (error) {
                    res.redirect('/cart');
               }
               else {
                    res.render('checkout.ejs',{result:result});
               }
          });

          // if (req.session.loggedin) {
          //      res.render('checkout.ejs',{mode: mode, output: output, message: message});
          // }
          // else {
          //      res.render('checkout.ejs',{mode: mode, output: output, message: message});   
          // }
     } 
     else {
          res.redirect('/cart');
     }
};


exports.confirmPayment = function(req, res){
     var mode = 'signup';
     var output = 'error';
     var message = '';
     
     if(req.method == "POST"){
 
         //Customer's Information
          var email = req.body.email;
          // var firstname = req.body.firstname.charAt(0).toUpperCase() + req.body.firstname.slice(1).toLowerCase();
          // var lastname = req.body.lastname.charAt(0).toUpperCase() + req.body.lastname.slice(1).toLowerCase();
          var address1 = req.body.address1;
          var address2 = req.body.address2;
          var zip = req.body.zip;
          var country = req.body.country;
          var province = req.body.province;

          //Items' Information
          var sku_list = {'0':'0001','1':'0002','3':'0003'};
          var quantity = '2';
          var total_price = '20000';
          
          //Payment & Delivery Methods
          var payment_method = req.body.payment_method;
          var delivery_method = req.body.delivery_method;

          res.send({order_details: {sku_list: sku_list, qunatity: quantity, total_price: total_price, delivery_method: delivery_method}, shipping_address: {email: email, address1: address1, address2: address2, zip: zip, country: country, province: province}});

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
               res.render('payment.ejs',{mode: mode, output: output, message: message});
          }
          else {
               res.render('payment.ejs',{mode: mode, output: output, message: message});   
          }
     }
};