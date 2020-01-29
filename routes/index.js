var connection = require('./../config');

/*
* GET home page.
*/

exports.index = function(req, res){
  var message = '';
  res.render('index');
};


exports.loadCategories = function(req, res){
  connection.query('SELECT DISTINCT category_id, category_name, GROUP_CONCAT(subcategory_id) AS subcategory_ids, GROUP_CONCAT(subcategory_name) AS subcategory_names FROM `view_categories` GROUP BY category_name ORDER BY category_name, subcategory_name ASC', function (error, result, fields) {
    if (error) {
        res.send({});
    }
    else {
        res.send({result:result});
    }
  });
}

exports.loadFeaturedProducts = function(req, res){
    connection.query('SELECT product_id, product_name, sku, unit_price, product_variant_image FROM tbl_products NATURAL JOIN tbl_product_variants NATURAL JOIN tbl_order_details ORDER BY quantity DESC LIMIT 6;', function (error, result, fields) {
      if (error) {
          res.send({});
      }
      else {
          res.send({result:result});
      }
    });
  }

exports.loadRecommendedProducts = function(req, res){
  connection.query('SELECT DISTINCT product_id, product_name, sku, unit_price, product_variant_image FROM tbl_products NATURAL JOIN tbl_product_variants NATURAL JOIN tbl_carts WHERE item_status IN ("removed", "ordered") ORDER BY CASE item_status WHEN "removed" THEN 1 WHEN "ordered" THEN 2 ELSE 3 END, item_status ASC, CASE customer_id WHEN "?" THEN 1 ELSE 2 END, customer_id ASC, date_added DESC, quantity DESC LIMIT 6', req.session.customer_id, function (error, result, fields) {
    if (error) {
        res.send({});
    }
    else {
        res.send({result:result});
    }
  });
}

exports.loadBrands = function(req, res) {
  connection.query('SELECT product_brand, COUNT(product_id) AS product_count FROM tbl_products GROUP BY product_brand ORDER BY product_brand ASC;', function (error, result, fields) {
    if (error) {
        res.send({});
    }
    else {
        res.send({result:result});
    }
  });
}

exports.searchProducts = function(req, res) {
  connection.query('SELECT product_name from tbl_products where product_name like "%'+req.query.key+'%"', function(err, rows, fields) {
	  if (err) throw err;
    var data=[];
    for(i=0;i<rows.length;i++)
      {
        data.push(rows[i].product_name);
      }
      res.end(JSON.stringify(data));
	});
}