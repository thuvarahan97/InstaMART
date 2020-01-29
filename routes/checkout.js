var connection = require('./../config');

exports.viewCheckout = function(req, res){

     if(req.method == "POST"){

          var email = '';
          var firstname = '';
          var lastname = '';
          var address1 = '';
          var address2 = '';
          var zip = '';
          var province = '';
          var country = '';
          var phone = '';

          if (req.session.loggedin) {
               connection.query('SELECT email, firstname, lastname FROM tbl_customers WHERE customer_id=?', req.session.customer_id, function (error, result, fields) {
                    if (error) {
                         res.redirect('/cart');
                    }
                    else {
                         email = result[0]['email'];
                         firstname = result[0]['firstname'];
                         lastname = result[0]['lastname'];
                    }
               });

               connection.query('SELECT C.address_line1, C.address_line2, C.province, C.country, C.zip_code, D.telephone FROM tbl_orders B natural join tbl_shipping_address C, tbl_telephones D WHERE B.customer_id=? AND B.customer_id=D.customer_id ORDER BY C.order_id DESC LIMIT 1', req.session.customer_id, function (error, result, fields) {
                    if (error) {
                         res.redirect('/cart');
                    }
                    else {
                         address1 = result[0]['address_line1'];
                         address2 = result[0]['address_line2'];
                         zip = result[0]['zip_code'];
                         province = result[0]['province'];
                         country = result[0]['country'];
                         phone = result[0]['telephone'];
                    }
               });               
          }
          
          connection.query('SELECT * FROM view_cart_items WHERE customer_id=?', req.session.customer_id, function (error, result, fields) {
               if (error) {
                    res.redirect('/cart');
               }
               else {
                    res.render('checkout.ejs',{cart: result, user_details: {email: email, firstname: firstname, lastname: lastname, address1: address1, address2: address2, zip: zip, province: province, country: country, phone: phone}});
               }
          });

     } 
     else {
          res.redirect('/cart');
     }
};


exports.confirmPayment = function(req, res){

     if(req.method == "POST"){
 
          //Customer's Information
          var email = req.body.email;
          var firstname = req.body.firstname.charAt(0).toUpperCase() + req.body.firstname.slice(1).toLowerCase();
          var lastname = req.body.lastname.charAt(0).toUpperCase() + req.body.lastname.slice(1).toLowerCase();
          var address1 = req.body.address1;
          var address2 = req.body.address2;
          var zip = req.body.zip;
          var country = req.body.country;
          var province = req.body.province;
          var phone = req.body.phone;
          var mobile = req.body.mobile;
          
          //Delivery & Payment Methods
          var delivery_method = req.body.delivery_method;
          var payment_method = req.body.payment_method;

          var output = '';
          var message = '';
          var cart = [];

          connection.query('SELECT * FROM view_cart_items WHERE customer_id=?', req.session.customer_id, function (error, result, fields) {
               if (error) {
                    res.redirect('/cart');
               }
               else {
                    cart = result;
               }
          });

          connection.query('CALL PlaceOrder(?,?,?,?,?,?,?,?,?,?,?,?,?,@output); SELECT @output;',[req.session.customer_id,email,firstname,lastname,address1,address2,province,country,zip,phone,mobile,delivery_method,payment_method], function (error, result, fields) {
               if (error) {
                    message = "Failed to place your order at the moment! Try again.";
               }
               else{
                    output = result[1][0]['@output'];

                    switch (output){
                         case 'success':
                              message = "Some fields are empty!";
                              res.redirect('/order_success');
                              res.end();
                         break;
                         case 'failed':
                              message = "Failed to place your order! Try again.";
                              res.render('checkout.ejs',{message: message, cart: cart, user_details: {email: email, firstname: firstname, lastname: lastname, address1: address1, address2: address2, zip: zip, province: province, country: country, phone: phone}});
                              res.end();
                         break;
                         case 'email_exists':
                              message = "User account with this email already exists! Login to your user account or user another email address.";
                              res.render('checkout.ejs',{message: message, cart: cart, user_details: {email: email, firstname: firstname, lastname: lastname, address1: address1, address2: address2, zip: zip, province: province, country: country, phone: phone}});
                              res.end();
                         break;
                    }

               }
          });

     }
     else {
          res.redirect('/cart');          
     }
};