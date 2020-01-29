-- phpMyAdmin SQL Dump
-- version 4.8.4
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jan 29, 2020 at 08:13 AM
-- Server version: 10.1.37-MariaDB
-- PHP Version: 7.3.1

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `instamart`
--
CREATE DATABASE IF NOT EXISTS `instamart` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `instamart`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `desired_product`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `desired_product` (`period1` DATE, `period2` DATE)  BEGIN

SELECT product.product_name,SUM(order_detail.Quantity) as amount_sold

from  order_detail NATURAL JOIN  orders NATURAL JOIN product_variant NATURAL JOIN product

where date(orders.Order_date ) between period1 and period2

group by product_id

order by SUM(order_detail.Quantity) DESC;

end$$

DROP PROCEDURE IF EXISTS `most_sold_product`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `most_sold_product` (`period1` DATE, `period2` DATE)  BEGIN
SELECT tbl_products.product_name,SUM(tbl_order_details.quantity) as amount_sold
from  tbl_order_details NATURAL JOIN  tbl_orders NATURAL JOIN tbl_product_variants NATURAL JOIN tbl_products
where date(tbl_orders.Order_date ) between period1 and period2
group by product_id
order by SUM(tbl_order_details.quantity) DESC;
end$$

DROP PROCEDURE IF EXISTS `PlaceOrder`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `PlaceOrder` (IN `customerID` INT(10), IN `emailAddress` VARCHAR(100), IN `firstName` VARCHAR(50), IN `lastName` VARCHAR(50), IN `addressLine1` VARCHAR(200), IN `addressLine2` VARCHAR(200), IN `province` VARCHAR(50), IN `country` VARCHAR(50), IN `zipCode` INT(5), IN `phone` VARCHAR(15), IN `mobile` VARCHAR(15), IN `deliveryMethod` VARCHAR(25), IN `paymentMethod` VARCHAR(25), OUT `output` TEXT)  BEGIN
	
    DECLARE output_text TEXT;
    DECLARE orderID int(15);
    DECLARE totalPrice FLOAT;
    DECLARE userEmailAvailable int;
    DECLARE isGuest int;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION, SQLWARNING
    BEGIN
    	ROLLBACK;
    	SET output_text = 'failed';
    END;
    
    START TRANSACTION;
    
    SET output_text = 'success';

    SET userEmailAvailable = (SELECT count(*) FROM tbl_customers WHERE customer_id != customerID AND email = emailAddress AND customer_type = 'registered_user');

    SET isGuest = (SELECT count(*) FROM tbl_customers WHERE customer_id = customerID AND customer_type = 'guest');
    
    IF (userEmailAvailable = 0) THEN
        
        IF (isGuest = 1) THEN
            UPDATE tbl_customers SET email = emailAddress, firstname = firstName, lastname = lastName WHERE customer_id = customerID;
        END IF;

        SET totalPrice = (SELECT SUM(total_price) FROM view_cart_items WHERE customer_id = customerID);

        INSERT INTO tbl_orders (customer_id, order_date, total_price, delivery_method, delivery_date, order_status) VALUES (customerID, NOW(), totalPrice, deliveryMethod, NOW(), 'not_received');
        SET orderID = (SELECT LAST_INSERT_ID());

        INSERT INTO tbl_order_details (order_id, sku, quantity) SELECT orderID AS order_id, sku, quantity FROM view_cart_items WHERE customer_id = customerID;
        
        UPDATE tbl_carts SET item_status = 'ordered' WHERE customer_id = customerID AND item_status = 'added';

        IF (addressLine2 = '') THEN
            INSERT INTO tbl_shipping_address (order_id, address_line1, address_line2, province, country, zip_code) VALUES (orderID, addressLine1, NULL, province, country, zipCode);
        ELSE
            INSERT INTO tbl_shipping_address (order_id, address_line1, address_line2, province, country, zip_code) VALUES (orderID, addressLine1, address_line2, province, country, zipCode);
        END IF;

        IF (phone != '' AND (SELECT COUNT(*) FROM tbl_telephones WHERE customer_id = customerID AND telephone = phone) = 0) THEN
            INSERT INTO tbl_telephones (customer_id, telephone) VALUES (customerID, phone);
        END IF;

        IF (mobile != '' AND (SELECT COUNT(*) FROM tbl_telephones WHERE customer_id = customerID AND telephone = mobile) = 0) THEN
            INSERT INTO tbl_telephones (customer_id, telephone) VALUES (customerID, mobile);
        END IF;

        IF (paymentMethod = 'cash_on_delivery') THEN
            INSERT INTO tbl_payments (order_id, payment_date, payment_method, payment_status) VALUES (orderID, NULL, paymentMethod, 'pending');
        ELSEIF (paymentMethod = 'card') THEN
            INSERT INTO tbl_payments (order_id, payment_date, payment_method, payment_status) VALUES (orderID, NOW(), paymentMethod, 'paid');
        END IF;

        INSERT INTO tbl_freight_details (order_id, shipping_status) VALUES (orderID, 'not_shipped');

    ELSE
        ROLLBACK;
        SET output_text = 'email_exists';
    END IF;

    COMMIT;

    SELECT output_text into output;

END$$

DROP PROCEDURE IF EXISTS `product_analytics`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `product_analytics` (`product` VARCHAR(255))  BEGIN
SELECT tbl_products.product_name,month(tbl_orders.order_date) as interested_month,tbl_order_details.quantity as quantity
from tbl_products NATURAL JOIN tbl_product_variants NATURAL JOIN tbl_order_details NATURAL JOIN  tbl_orders
where lower(tbl_products.product_name) like concat('%',product,'%');
end$$

DROP PROCEDURE IF EXISTS `sales_report`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `sales_report` (IN `period` INT)  BEGIN
SELECT tbl_orders.order_id,tbl_orders.order_date,tbl_customers.firstName ,tbl_orders.total_Price ,tbl_orders.delivery_Method , 
tbl_payments.payment_status ,tbl_payments.payment_method,
tbl_shipping_address.address_line1,tbl_shipping_address.zip_code,tbl_freight_details.shipping_status 
FROM tbl_orders natural join tbl_customers natural left outer join tbl_shipping_address NATURAL left outer JOIN tbl_freight_details 
Natural left outer JOIN tbl_payments where year(tbl_orders.order_date)=period and month(tbl_orders.order_date) between 10 and 12;
end$$

--
-- Functions
--
DROP FUNCTION IF EXISTS `CalculateCartTotalPrice`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `CalculateCartTotalPrice` (`customerID` INT(10)) RETURNS DECIMAL(10,2) BEGIN
	DECLARE totalPrice DECIMAL(10,2);
	SET totalPrice = (SELECT SUM(total_price) FROM view_cart_items WHERE customer_id = customerID);
    
    RETURN totalPrice;
END$$

DROP FUNCTION IF EXISTS `delivery_date`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `delivery_date` (`city` VARCHAR(255)) RETURNS TEXT CHARSET latin1 BEGIN
	DECLARE output DATETIME;
    
    IF (city = 'Colombo') THEN
    	SET output = DATE_ADD(NOW(), INTERVAL 5 DAY);
    ELSEIF (city = 'Negombo') THEN
    	SET output = DATE_ADD(NOW(), INTERVAL 7 DAY);
    END IF;
    
    RETURN output;
END$$

DROP FUNCTION IF EXISTS `RegisterUser`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `RegisterUser` (`i_username` VARCHAR(50), `i_firstname` VARCHAR(50), `i_lastname` VARCHAR(50), `i_email` VARCHAR(100), `i_password` TEXT) RETURNS TEXT CHARSET latin1 BEGIN
    
    DECLARE output TEXT;
    DECLARE customer_id INT;

    SET output = 'none';
    SET customer_id = 0;
    
    IF (i_username != '' AND i_firstname != '' AND i_lastname != '' AND i_email != '' AND i_password != '' AND i_username IS NOT NULL AND i_firstname IS NOT NULL AND i_lastname IS NOT NULL AND i_email IS NOT NULL AND i_password IS NOT NULL) THEN
        IF NOT EXISTS ( SELECT email FROM tbl_customers WHERE email = i_email) THEN
            IF NOT EXISTS ( SELECT username FROM tbl_users WHERE username = i_username) THEN
                INSERT INTO tbl_customers (email, firstname, lastname, customer_type) VALUES (i_email, i_firstname, i_lastname, 'registered_user');
                SET customer_id = (SELECT LAST_INSERT_ID());

                INSERT INTO tbl_users (user_id, username,  password, date_registered) VALUES (customer_id, i_username, i_password, NOW());
                
                SET output = 'success';
            
            ELSE
                SET output = 'username_exists';
            END IF;
        ELSE
            SET output = 'email_exists';
        END IF;
    ELSE
        SET output = 'null_values';
    END IF;

    RETURN output;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `customer_order_report`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `customer_order_report`;
CREATE TABLE `customer_order_report` (
`firstName` varchar(50)
,`order_ID` int(15) unsigned zerofill
,`order_date` datetime
,`total_Price` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `most_ordered_category_report`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `most_ordered_category_report`;
CREATE TABLE `most_ordered_category_report` (
`category_name` varchar(50)
,`counts` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_carts`
--

DROP TABLE IF EXISTS `tbl_carts`;
CREATE TABLE `tbl_carts` (
  `customer_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `sku` varchar(25) NOT NULL,
  `quantity` int(10) DEFAULT '1',
  `date_added` datetime NOT NULL,
  `item_status` enum('added','removed','ordered') DEFAULT 'added'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_carts`
--

INSERT INTO `tbl_carts` (`customer_id`, `sku`, `quantity`, `date_added`, `item_status`) VALUES
(0000000086, 'APPLE3', 1, '2020-01-02 13:40:58', 'added'),
(0000000116, 'APPLE2', 1, '2020-01-02 09:49:30', 'added'),
(0000000117, 'APPLE3', 3, '2020-01-02 09:49:38', 'added'),
(0000000118, 'APPLE2', 3, '2020-01-02 09:52:29', 'added'),
(0000000118, 'APPLE3', 1, '2020-01-02 09:52:39', 'added'),
(0000000120, 'APPLE2', 1, '2020-01-02 10:14:04', 'added'),
(0000000120, 'APPLE3', 1, '2020-01-02 10:12:10', 'removed'),
(0000000120, 'APPLE3', 2, '2020-01-02 10:12:19', 'removed'),
(0000000121, 'APPLE2', 1, '2020-01-02 10:19:27', 'added'),
(0000000121, 'APPLE3', 1, '2020-01-02 10:18:13', 'added'),
(0000000122, 'APPLE3', 1, '2020-01-02 10:22:40', 'added'),
(0000000122, 'APPLE3', 2, '2020-01-02 10:22:49', 'added'),
(0000000123, 'APPLE2', 1, '2020-01-02 10:24:31', 'added'),
(0000000123, 'APPLE2', 2, '2020-01-02 10:24:38', 'added'),
(0000000123, 'APPLE2', 1, '2020-01-02 10:25:29', 'added'),
(0000000124, 'APPLE2', 2, '0000-00-00 00:00:00', 'added'),
(0000000124, 'APPLE2', 1, '2020-01-02 10:27:55', 'added'),
(0000000125, 'APPLE2', 3, '0000-00-00 00:00:00', 'removed'),
(0000000125, 'APPLE2', 1, '2020-01-02 10:29:15', 'removed'),
(0000000126, 'ABC1', 6, '0000-00-00 00:00:00', 'added'),
(0000000126, 'ABC1', 2, '2020-01-02 11:03:36', 'added'),
(0000000127, 'ABC1', 3, '2020-01-02 11:12:58', 'added'),
(0000000127, 'APPLE3', 1, '2020-01-02 11:13:18', 'removed'),
(0000000128, 'APPLE2', 1, '2020-01-02 13:39:18', 'added'),
(0000000128, 'APPLE3', 4, '0000-00-00 00:00:00', 'added'),
(0000000128, 'APPLE3', 3, '2020-01-02 13:39:51', 'added');

--
-- Triggers `tbl_carts`
--
DROP TRIGGER IF EXISTS `check_cart_item`;
DELIMITER $$
CREATE TRIGGER `check_cart_item` BEFORE INSERT ON `tbl_carts` FOR EACH ROW BEGIN
	DECLARE quantity_val INT;
    DECLARE new_quantity_val INT;
    DECLARE date1 DATETIME;
    IF ((SELECT COUNT(*) FROM tbl_carts WHERE sku = NEW.sku AND customer_id = NEW.customer_id) != 0) THEN
		SET quantity_val = (SELECT quantity FROM tbl_carts WHERE customer_id = NEW.customer_id AND sku = NEW.sku);
        SET date1 = (SELECT quantity FROM tbl_carts WHERE customer_id = NEW.customer_id AND sku = NEW.sku);
        SET new_quantity_val = (quantity_val + NEW.quantity);
        SET NEW.quantity = new_quantity_val;
        SET NEW.date_added = date1;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_categories`
--

DROP TABLE IF EXISTS `tbl_categories`;
CREATE TABLE `tbl_categories` (
  `category_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `category_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_categories`
--

INSERT INTO `tbl_categories` (`category_id`, `category_name`) VALUES
(000000000000003, 'Bag\'s & Shoes'),
(000000000000010, 'Chargers'),
(000000000000004, 'Consumer Electronics'),
(000000000000008, 'CPUs'),
(000000000000005, 'Dresses'),
(000000000000006, 'Jackets'),
(000000000000002, 'Phones & Telecommunications'),
(000000000000007, 'Sweaters'),
(000000000000009, 'Tablets'),
(000000000000001, 'Women\'s Fashion');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_customers`
--

DROP TABLE IF EXISTS `tbl_customers`;
CREATE TABLE `tbl_customers` (
  `customer_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `firstname` varchar(50) DEFAULT NULL,
  `lastname` varchar(50) DEFAULT NULL,
  `customer_type` enum('registered_user','guest') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_customers`
--

INSERT INTO `tbl_customers` (`customer_id`, `email`, `firstname`, `lastname`, `customer_type`) VALUES
(0000000086, 'thuvarahan97@gmail.com', 'Thuva', 'Siva', 'registered_user'),
(0000000087, NULL, NULL, NULL, 'guest'),
(0000000088, NULL, NULL, NULL, 'guest'),
(0000000089, NULL, NULL, NULL, 'guest'),
(0000000090, NULL, NULL, NULL, 'guest'),
(0000000091, NULL, NULL, NULL, 'guest'),
(0000000092, NULL, NULL, NULL, 'guest'),
(0000000093, NULL, NULL, NULL, 'guest'),
(0000000094, NULL, NULL, NULL, 'guest'),
(0000000095, NULL, NULL, NULL, 'guest'),
(0000000096, NULL, NULL, NULL, 'guest'),
(0000000097, NULL, NULL, NULL, 'guest'),
(0000000098, NULL, NULL, NULL, 'guest'),
(0000000099, NULL, NULL, NULL, 'guest'),
(0000000100, NULL, NULL, NULL, 'guest'),
(0000000101, NULL, NULL, NULL, 'guest'),
(0000000102, NULL, NULL, NULL, 'guest'),
(0000000103, NULL, NULL, NULL, 'guest'),
(0000000104, NULL, NULL, NULL, 'guest'),
(0000000105, NULL, NULL, NULL, 'guest'),
(0000000106, NULL, NULL, NULL, 'guest'),
(0000000107, NULL, NULL, NULL, 'guest'),
(0000000108, NULL, NULL, NULL, 'guest'),
(0000000109, NULL, NULL, NULL, 'guest'),
(0000000110, NULL, NULL, NULL, 'guest'),
(0000000111, NULL, NULL, NULL, 'guest'),
(0000000112, NULL, NULL, NULL, 'guest'),
(0000000113, NULL, NULL, NULL, 'guest'),
(0000000114, NULL, NULL, NULL, 'guest'),
(0000000115, NULL, NULL, NULL, 'guest'),
(0000000116, NULL, NULL, NULL, 'guest'),
(0000000117, NULL, NULL, NULL, 'guest'),
(0000000118, NULL, NULL, NULL, 'guest'),
(0000000119, NULL, NULL, NULL, 'guest'),
(0000000120, NULL, NULL, NULL, 'guest'),
(0000000121, NULL, NULL, NULL, 'guest'),
(0000000122, NULL, NULL, NULL, 'guest'),
(0000000123, NULL, NULL, NULL, 'guest'),
(0000000124, NULL, NULL, NULL, 'guest'),
(0000000125, NULL, NULL, NULL, 'guest'),
(0000000126, NULL, NULL, NULL, 'guest'),
(0000000127, 'thuva@gmail.com', 'Thuva', 'Siva', 'registered_user'),
(0000000128, NULL, NULL, NULL, 'guest');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_customer_offers`
--

DROP TABLE IF EXISTS `tbl_customer_offers`;
CREATE TABLE `tbl_customer_offers` (
  `customer_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `offer_id` int(15) UNSIGNED ZEROFILL NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_freight_details`
--

DROP TABLE IF EXISTS `tbl_freight_details`;
CREATE TABLE `tbl_freight_details` (
  `tracking_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `order_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `shipping_date` datetime DEFAULT NULL,
  `shipping_status` enum('shipped','not_shipped') NOT NULL DEFAULT 'not_shipped'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_freight_details`
--

INSERT INTO `tbl_freight_details` (`tracking_id`, `order_id`, `shipping_date`, `shipping_status`) VALUES
(000000000000004, 000000000000002, NULL, 'not_shipped'),
(000000000000005, 000000000000003, NULL, 'not_shipped'),
(000000000000006, 000000000000004, NULL, 'not_shipped'),
(000000000000016, 000000000000005, NULL, 'not_shipped'),
(000000000000017, 000000000000006, NULL, 'not_shipped'),
(000000000000018, 000000000000007, NULL, 'not_shipped'),
(000000000000019, 000000000000008, NULL, 'not_shipped'),
(000000000000022, 000000000000009, NULL, 'not_shipped'),
(000000000000024, 000000000000010, NULL, 'not_shipped'),
(000000000000026, 000000000000011, NULL, 'not_shipped'),
(000000000000028, 000000000000012, NULL, 'not_shipped'),
(000000000000030, 000000000000013, NULL, 'not_shipped'),
(000000000000032, 000000000000014, NULL, 'not_shipped'),
(000000000000033, 000000000000015, NULL, 'not_shipped'),
(000000000000036, 000000000000016, NULL, 'not_shipped'),
(000000000000037, 000000000000017, NULL, 'not_shipped'),
(000000000000038, 000000000000018, NULL, 'not_shipped'),
(000000000000039, 000000000000019, NULL, 'not_shipped'),
(000000000000040, 000000000000020, NULL, 'not_shipped'),
(000000000000041, 000000000000021, NULL, 'not_shipped'),
(000000000000043, 000000000000022, NULL, 'not_shipped'),
(000000000000045, 000000000000023, NULL, 'not_shipped'),
(000000000000046, 000000000000024, NULL, 'not_shipped'),
(000000000000047, 000000000000025, NULL, 'not_shipped'),
(000000000000048, 000000000000026, NULL, 'not_shipped'),
(000000000000050, 000000000000027, NULL, 'not_shipped'),
(000000000000052, 000000000000028, NULL, 'not_shipped'),
(000000000000054, 000000000000029, NULL, 'not_shipped'),
(000000000000056, 000000000000030, NULL, 'not_shipped'),
(000000000000057, 000000000000031, NULL, 'not_shipped'),
(000000000000058, 000000000000032, NULL, 'not_shipped');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_offers`
--

DROP TABLE IF EXISTS `tbl_offers`;
CREATE TABLE `tbl_offers` (
  `offer_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `offer_title` varchar(200) NOT NULL,
  `offer_description` text NOT NULL,
  `offer_start_date` datetime NOT NULL,
  `offer_end_date` datetime NOT NULL,
  `offer_percentage` decimal(3,1) DEFAULT '0.0',
  `offer_image` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_orders`
--

DROP TABLE IF EXISTS `tbl_orders`;
CREATE TABLE `tbl_orders` (
  `order_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `customer_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `order_date` datetime NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `delivery_method` enum('store_pickup','delivery') NOT NULL,
  `delivery_date` datetime NOT NULL,
  `order_status` enum('received','not_received') NOT NULL DEFAULT 'not_received'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_orders`
--

INSERT INTO `tbl_orders` (`order_id`, `customer_id`, `order_date`, `total_price`, `delivery_method`, `delivery_date`, `order_status`) VALUES
(000000000000002, 0000000086, '2019-12-28 14:19:16', '320000.00', 'delivery', '2019-12-28 14:19:16', 'not_received'),
(000000000000003, 0000000086, '2019-12-28 14:24:00', '200000.00', 'delivery', '2019-12-28 14:24:00', 'not_received'),
(000000000000004, 0000000086, '2019-12-29 01:23:29', '200000.00', 'store_pickup', '2019-12-29 01:23:29', 'not_received'),
(000000000000005, 0000000086, '2019-12-29 01:34:27', '200000.00', 'store_pickup', '2019-12-29 01:34:27', 'not_received'),
(000000000000006, 0000000086, '2019-12-29 11:48:13', '290000.00', 'store_pickup', '2019-12-29 11:48:13', 'not_received'),
(000000000000007, 0000000086, '2019-12-29 12:19:12', '200000.00', 'delivery', '2019-12-29 12:19:12', 'not_received'),
(000000000000008, 0000000086, '2019-12-29 19:19:39', '300000.00', 'store_pickup', '2019-12-29 19:19:39', 'not_received'),
(000000000000009, 0000000086, '2019-12-29 19:20:11', '300000.00', 'store_pickup', '2019-12-29 19:20:11', 'not_received'),
(000000000000010, 0000000086, '2019-12-29 19:23:21', '100000.00', 'store_pickup', '2019-12-29 19:23:21', 'not_received'),
(000000000000011, 0000000086, '2019-12-29 19:24:42', '100000.00', 'store_pickup', '2019-12-29 19:24:42', 'not_received'),
(000000000000012, 0000000086, '2019-12-29 19:27:46', '100000.00', 'store_pickup', '2019-12-29 19:27:46', 'not_received'),
(000000000000013, 0000000086, '2019-12-29 19:28:29', '100000.00', 'store_pickup', '2019-12-29 19:28:29', 'not_received'),
(000000000000014, 0000000086, '2019-12-29 19:30:16', '100000.00', 'store_pickup', '2019-12-29 19:30:16', 'not_received'),
(000000000000015, 0000000086, '2019-12-29 19:34:43', '100000.00', 'store_pickup', '2019-12-29 19:34:43', 'not_received'),
(000000000000016, 0000000086, '2019-12-29 19:35:44', '100000.00', 'store_pickup', '2019-12-29 19:35:44', 'not_received'),
(000000000000017, 0000000086, '2019-12-29 19:40:09', '100000.00', 'store_pickup', '2019-12-29 19:40:09', 'not_received'),
(000000000000018, 0000000086, '2019-12-29 19:42:26', '100000.00', 'store_pickup', '2019-12-29 19:42:26', 'not_received'),
(000000000000019, 0000000086, '2019-12-29 19:43:34', '100000.00', 'store_pickup', '2019-12-29 19:43:34', 'not_received'),
(000000000000020, 0000000086, '2019-12-29 19:45:32', '100000.00', 'store_pickup', '2019-12-29 19:45:32', 'not_received'),
(000000000000021, 0000000086, '2019-12-29 19:46:37', '100000.00', 'store_pickup', '2019-12-29 19:46:37', 'not_received'),
(000000000000022, 0000000086, '2019-12-29 19:47:32', '100000.00', 'store_pickup', '2019-12-29 19:47:32', 'not_received'),
(000000000000023, 0000000086, '2019-12-29 19:48:31', '100000.00', 'store_pickup', '2019-12-29 19:48:31', 'not_received'),
(000000000000024, 0000000086, '2019-12-29 19:49:17', '100000.00', 'delivery', '2019-12-29 19:49:17', 'not_received'),
(000000000000025, 0000000086, '2019-12-29 19:49:39', '100000.00', 'store_pickup', '2019-12-29 19:49:39', 'not_received'),
(000000000000026, 0000000086, '2019-12-29 19:50:27', '100000.00', 'store_pickup', '2019-12-29 19:50:27', 'not_received'),
(000000000000027, 0000000086, '2019-12-29 19:51:19', '100000.00', 'store_pickup', '2019-12-29 19:51:19', 'not_received'),
(000000000000028, 0000000086, '2019-12-29 19:53:03', '100000.00', 'store_pickup', '2019-12-29 19:53:03', 'not_received'),
(000000000000029, 0000000086, '2019-12-29 19:54:24', '100000.00', 'store_pickup', '2019-12-29 19:54:24', 'not_received'),
(000000000000030, 0000000086, '2019-12-29 19:58:10', '300000.00', 'store_pickup', '2019-12-29 19:58:10', 'not_received'),
(000000000000031, 0000000086, '2019-12-29 19:59:05', '100000.00', 'store_pickup', '2019-12-29 19:59:05', 'not_received'),
(000000000000032, 0000000086, '2019-12-29 20:10:07', '200000.00', 'delivery', '2019-12-29 20:10:07', 'not_received');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_order_details`
--

DROP TABLE IF EXISTS `tbl_order_details`;
CREATE TABLE `tbl_order_details` (
  `order_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `sku` varchar(25) NOT NULL,
  `quantity` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_order_details`
--

INSERT INTO `tbl_order_details` (`order_id`, `sku`, `quantity`) VALUES
(000000000000002, 'ABC1', 4),
(000000000000002, 'APPLE2', 2),
(000000000000003, 'APPLE2', 2),
(000000000000004, 'APPLE2', 2),
(000000000000005, 'APPLE2', 2),
(000000000000006, 'ABC1', 3),
(000000000000006, 'APPLE2', 2),
(000000000000007, 'APPLE2', 2),
(000000000000008, 'APPLE2', 3),
(000000000000009, 'APPLE2', 3),
(000000000000010, 'APPLE3', 2),
(000000000000011, 'APPLE3', 2),
(000000000000012, 'APPLE3', 2),
(000000000000013, 'APPLE3', 2),
(000000000000014, 'APPLE3', 2),
(000000000000015, 'APPLE3', 2),
(000000000000016, 'APPLE3', 2),
(000000000000017, 'APPLE3', 2),
(000000000000018, 'APPLE3', 2),
(000000000000019, 'APPLE3', 2),
(000000000000020, 'APPLE3', 2),
(000000000000021, 'APPLE3', 2),
(000000000000022, 'APPLE3', 2),
(000000000000023, 'APPLE3', 2),
(000000000000024, 'APPLE3', 2),
(000000000000025, 'APPLE3', 2),
(000000000000026, 'APPLE3', 2),
(000000000000027, 'APPLE3', 2),
(000000000000028, 'APPLE3', 2),
(000000000000029, 'APPLE3', 2),
(000000000000030, 'APPLE2', 3),
(000000000000031, 'APPLE3', 2),
(000000000000032, 'APPLE3', 4);

--
-- Triggers `tbl_order_details`
--
DROP TRIGGER IF EXISTS `reduce_ordered_stock`;
DELIMITER $$
CREATE TRIGGER `reduce_ordered_stock` AFTER INSERT ON `tbl_order_details` FOR EACH ROW BEGIN
	DECLARE stock_val INT;
    DECLARE new_stock_val INT;
    SET stock_val = (SELECT stock FROM tbl_product_variants WHERE sku = NEW.sku);
    SET new_stock_val = (stock_val - NEW.quantity);
    IF (new_stock_val < 0) THEN
		UPDATE tbl_product_variants SET stock = 0 WHERE sku = NEW.sku;
    ELSE
    	UPDATE tbl_product_variants SET stock = new_stock_val WHERE sku = NEW.sku;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_payments`
--

DROP TABLE IF EXISTS `tbl_payments`;
CREATE TABLE `tbl_payments` (
  `payment_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `order_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `payment_date` datetime DEFAULT NULL,
  `payment_method` enum('cash_on_delivery','card') NOT NULL,
  `payment_status` enum('paid','pending') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_payments`
--

INSERT INTO `tbl_payments` (`payment_id`, `order_id`, `payment_date`, `payment_method`, `payment_status`) VALUES
(000000000000002, 000000000000002, '2019-12-28 14:19:16', 'card', 'paid'),
(000000000000003, 000000000000003, NULL, 'cash_on_delivery', 'pending'),
(000000000000004, 000000000000004, NULL, 'cash_on_delivery', 'pending'),
(000000000000014, 000000000000005, NULL, 'cash_on_delivery', 'pending'),
(000000000000015, 000000000000006, NULL, 'cash_on_delivery', 'pending'),
(000000000000016, 000000000000007, '2019-12-29 12:19:13', 'card', 'paid'),
(000000000000017, 000000000000008, NULL, 'cash_on_delivery', 'pending'),
(000000000000020, 000000000000009, NULL, 'cash_on_delivery', 'pending'),
(000000000000022, 000000000000010, NULL, 'cash_on_delivery', 'pending'),
(000000000000024, 000000000000011, NULL, 'cash_on_delivery', 'pending'),
(000000000000026, 000000000000012, NULL, 'cash_on_delivery', 'pending'),
(000000000000028, 000000000000013, NULL, 'cash_on_delivery', 'pending'),
(000000000000030, 000000000000014, NULL, 'cash_on_delivery', 'pending'),
(000000000000031, 000000000000015, NULL, 'cash_on_delivery', 'pending'),
(000000000000034, 000000000000016, NULL, 'cash_on_delivery', 'pending'),
(000000000000035, 000000000000017, NULL, 'cash_on_delivery', 'pending'),
(000000000000036, 000000000000018, NULL, 'cash_on_delivery', 'pending'),
(000000000000037, 000000000000019, NULL, 'cash_on_delivery', 'pending'),
(000000000000038, 000000000000020, NULL, 'cash_on_delivery', 'pending'),
(000000000000039, 000000000000021, NULL, 'cash_on_delivery', 'pending'),
(000000000000041, 000000000000022, NULL, 'cash_on_delivery', 'pending'),
(000000000000043, 000000000000023, NULL, 'cash_on_delivery', 'pending'),
(000000000000044, 000000000000024, NULL, 'cash_on_delivery', 'pending'),
(000000000000045, 000000000000025, NULL, 'cash_on_delivery', 'pending'),
(000000000000046, 000000000000026, NULL, 'cash_on_delivery', 'pending'),
(000000000000048, 000000000000027, NULL, 'cash_on_delivery', 'pending'),
(000000000000050, 000000000000028, NULL, 'cash_on_delivery', 'pending'),
(000000000000052, 000000000000029, NULL, 'cash_on_delivery', 'pending'),
(000000000000054, 000000000000030, NULL, 'cash_on_delivery', 'pending'),
(000000000000055, 000000000000031, NULL, 'cash_on_delivery', 'pending'),
(000000000000056, 000000000000032, NULL, 'cash_on_delivery', 'pending');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_products`
--

DROP TABLE IF EXISTS `tbl_products`;
CREATE TABLE `tbl_products` (
  `product_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `product_name` varchar(100) NOT NULL,
  `product_brand` varchar(50) NOT NULL,
  `product_description` text NOT NULL,
  `product_image` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_products`
--

INSERT INTO `tbl_products` (`product_id`, `product_name`, `product_brand`, `product_description`, `product_image`) VALUES
(000000000000001, 'Product1', 'Samsung', 'Good smartphone', NULL),
(000000000000002, 'Product2', 'Apple', 'Good smartphone', NULL),
(000000000000003, 'Product3', 'Huaweii', 'dsfbdfbdfbdfbfdbdfbfb', NULL),
(000000000000004, 'Product4', 'Galaxy', 'sdnviohdsiuvhiudsghik', NULL),
(000000000000005, 'Product5', 'Adobe', 'gfdbgbdgbdf', NULL),
(000000000000006, 'Product6', 'Huaweii', 'sdvdsvds', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_product_categories`
--

DROP TABLE IF EXISTS `tbl_product_categories`;
CREATE TABLE `tbl_product_categories` (
  `product_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `category_id` int(15) UNSIGNED ZEROFILL NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_product_categories`
--

INSERT INTO `tbl_product_categories` (`product_id`, `category_id`) VALUES
(000000000000004, 000000000000001),
(000000000000001, 000000000000003),
(000000000000004, 000000000000005),
(000000000000001, 000000000000008),
(000000000000003, 000000000000008),
(000000000000005, 000000000000008),
(000000000000006, 000000000000008),
(000000000000002, 000000000000009);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_product_variants`
--

DROP TABLE IF EXISTS `tbl_product_variants`;
CREATE TABLE `tbl_product_variants` (
  `sku` varchar(25) NOT NULL,
  `product_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `weight` double NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `stock` int(10) NOT NULL,
  `product_variant_image` text,
  `avg_ratings` decimal(2,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_product_variants`
--

INSERT INTO `tbl_product_variants` (`sku`, `product_id`, `weight`, `unit_price`, `stock`, `product_variant_image`, `avg_ratings`) VALUES
('ABC1', 000000000000001, 50, '30000.00', 30, 'images/cart/one.png', NULL),
('APPLE2', 000000000000002, 60, '100000.00', 50, 'images/cart/two.png', NULL),
('APPLE3', 000000000000002, 55, '50000.00', 7, 'images/cart/one.png', NULL),
('sku5', 000000000000003, 0, '0.00', 0, 'images/cart/one.png', NULL),
('sku6', 000000000000004, 0, '0.00', 0, 'images/cart/one.png', NULL),
('sku7', 000000000000005, 0, '0.00', 0, NULL, NULL),
('sku8', 000000000000006, 0, '0.00', 0, 'images/cart/one.png', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_product_variant_details`
--

DROP TABLE IF EXISTS `tbl_product_variant_details`;
CREATE TABLE `tbl_product_variant_details` (
  `sku` varchar(25) NOT NULL,
  `attribute_name` varchar(50) NOT NULL,
  `attribute_value` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_product_variant_details`
--

INSERT INTO `tbl_product_variant_details` (`sku`, `attribute_name`, `attribute_value`) VALUES
('ABC1', 'color', 'red'),
('APPLE2', 'camera', '50MP'),
('APPLE2', 'color', 'red'),
('APPLE3', 'camera', '77MP'),
('APPLE3', 'color', 'blue');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_product_variant_offers`
--

DROP TABLE IF EXISTS `tbl_product_variant_offers`;
CREATE TABLE `tbl_product_variant_offers` (
  `sku` varchar(25) NOT NULL,
  `offer_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `min_quantity` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_product_variant_promos`
--

DROP TABLE IF EXISTS `tbl_product_variant_promos`;
CREATE TABLE `tbl_product_variant_promos` (
  `sku` varchar(25) NOT NULL,
  `promo_id` int(15) UNSIGNED ZEROFILL NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_product_variant_ratings_reviews`
--

DROP TABLE IF EXISTS `tbl_product_variant_ratings_reviews`;
CREATE TABLE `tbl_product_variant_ratings_reviews` (
  `sku` varchar(25) NOT NULL,
  `user_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `rating` decimal(2,1) DEFAULT NULL,
  `review` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_promos`
--

DROP TABLE IF EXISTS `tbl_promos`;
CREATE TABLE `tbl_promos` (
  `promo_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `promo_title` varchar(200) NOT NULL,
  `promo_description` text NOT NULL,
  `promo_code` varchar(20) NOT NULL,
  `promo_start_date` datetime NOT NULL,
  `promo_end_date` datetime NOT NULL,
  `promo_min_amount` decimal(10,2) NOT NULL,
  `promo_max_discount` decimal(10,2) NOT NULL,
  `promo_percentage` decimal(3,1) DEFAULT '0.0',
  `promo_image` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `tbl_shipping_address`
--

DROP TABLE IF EXISTS `tbl_shipping_address`;
CREATE TABLE `tbl_shipping_address` (
  `order_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `address_line1` varchar(200) NOT NULL,
  `address_line2` varchar(200) DEFAULT NULL,
  `province` varchar(50) NOT NULL,
  `country` varchar(50) NOT NULL,
  `zip_code` int(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_shipping_address`
--

INSERT INTO `tbl_shipping_address` (`order_id`, `address_line1`, `address_line2`, `province`, `country`, `zip_code`) VALUES
(000000000000002, 'asndjnjdsnj', NULL, 'jaffna', 'sri lanka', 40000),
(000000000000003, 'dsfdsvcfds', NULL, 'Jaffna', 'Sri Lanka', 34534),
(000000000000004, 'sdv', NULL, 'Jaffna', 'Sri Lanka', 67676),
(000000000000005, 'sdv', NULL, 'Jaffna', 'Sri Lanka', 67676),
(000000000000006, 'sdv', NULL, 'Jaffna', 'Sri Lanka', 67676),
(000000000000007, 'asdf', NULL, 'Jaffna', 'Sri Lanka', 0),
(000000000000008, 'asdf', NULL, 'Jaffna', 'Sri Lanka', 34344),
(000000000000009, 'asdf', NULL, 'Jaffna', 'Sri Lanka', 34344),
(000000000000010, 'asdf', NULL, 'Jaffna', 'Sri Lanka', 34344),
(000000000000011, 'asdf', NULL, 'Jaffna', 'Sri Lanka', 34344),
(000000000000012, 'asdf', NULL, 'Jaffna', 'Sri Lanka', 34344),
(000000000000013, 'asdf', NULL, 'Jaffna', 'Sri Lanka', 34344),
(000000000000014, 'hasiudfhi', NULL, 'jaffna', 'sri lanka', 49000),
(000000000000015, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000016, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000017, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000018, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000019, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000020, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000021, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000022, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000023, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000024, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000025, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000026, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000027, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000028, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000029, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000030, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000031, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000),
(000000000000032, 'hasiudfhi', NULL, 'Jaffna', 'Sri Lanka', 49000);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_subcategories`
--

DROP TABLE IF EXISTS `tbl_subcategories`;
CREATE TABLE `tbl_subcategories` (
  `category_id` int(15) UNSIGNED ZEROFILL NOT NULL,
  `subcategory_id` int(15) UNSIGNED ZEROFILL NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_subcategories`
--

INSERT INTO `tbl_subcategories` (`category_id`, `subcategory_id`) VALUES
(000000000000001, 000000000000005),
(000000000000001, 000000000000006),
(000000000000001, 000000000000007),
(000000000000002, 000000000000010),
(000000000000004, 000000000000008),
(000000000000004, 000000000000009),
(000000000000004, 000000000000010);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_telephones`
--

DROP TABLE IF EXISTS `tbl_telephones`;
CREATE TABLE `tbl_telephones` (
  `customer_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `telephone` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_telephones`
--

INSERT INTO `tbl_telephones` (`customer_id`, `telephone`) VALUES
(0000000086, '07634343434'),
(0000000086, '0763966034'),
(0000000086, '0774873870'),
(0000000086, '0779536167'),
(0000000086, '1234567890'),
(0000000086, '2398923892');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_users`
--

DROP TABLE IF EXISTS `tbl_users`;
CREATE TABLE `tbl_users` (
  `user_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` text NOT NULL,
  `date_registered` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `tbl_users`
--

INSERT INTO `tbl_users` (`user_id`, `username`, `password`, `date_registered`) VALUES
(0000000086, 'thuva', 'e632913900dd44e4d0648110d5f3c59d027fc9a1141c53f3d907692ef0924500c6331322f948158f9272f21bb05eb2b3af1c1853025ec34c25fae0dc355e1d2c29de01d0e4e8dd7f457436471299390fe49a1242cdc0ec3a460f6e9574d999afe965799993', '2019-12-12 22:01:01'),
(0000000127, 'thuva1', '3d91d085f0e5a7788d97091a8f9747cf423c2e4637841a8b08afb22a16eea896ace69f2bcbe2394e2ee1bdcf2574101dc30512d8f15a6e5cc7b92f353f003b0f0b8629afa08eb4a0c934d69ceb7bee313e71331685412f0465fe2819aae56f0a09c660d77ae7facdfd15', '2020-01-02 11:12:15');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_user_promos`
--

DROP TABLE IF EXISTS `tbl_user_promos`;
CREATE TABLE `tbl_user_promos` (
  `user_id` int(10) UNSIGNED ZEROFILL NOT NULL,
  `promo_id` int(15) UNSIGNED ZEROFILL NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_cart_items`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `view_cart_items`;
CREATE TABLE `view_cart_items` (
`customer_id` int(10) unsigned zerofill
,`sku` varchar(25)
,`product_name` varchar(100)
,`product_brand` varchar(50)
,`product_image` text
,`product_variant_image` text
,`quantity` int(10)
,`unit_price` decimal(10,2)
,`total_price` decimal(20,2)
,`date_added` datetime
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `view_categories`
-- (See below for the actual view)
--
DROP VIEW IF EXISTS `view_categories`;
CREATE TABLE `view_categories` (
`category_id` int(15) unsigned zerofill
,`category_name` varchar(50)
,`subcategory_id` int(15) unsigned zerofill
,`subcategory_name` varchar(50)
);

-- --------------------------------------------------------

--
-- Structure for view `customer_order_report`
--
DROP TABLE IF EXISTS `customer_order_report`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `customer_order_report`  AS  select `tbl_customers`.`firstname` AS `firstName`,`tbl_orders`.`order_id` AS `order_ID`,`tbl_orders`.`order_date` AS `order_date`,`tbl_orders`.`total_price` AS `total_Price` from (`tbl_customers` join `tbl_orders` on((`tbl_customers`.`customer_id` = `tbl_orders`.`customer_id`))) ;

-- --------------------------------------------------------

--
-- Structure for view `most_ordered_category_report`
--
DROP TABLE IF EXISTS `most_ordered_category_report`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `most_ordered_category_report`  AS  select `tbl_categories`.`category_name` AS `category_name`,count(`tbl_order_details`.`quantity`) AS `counts` from (((`tbl_categories` join `tbl_product_categories` on((`tbl_categories`.`category_id` = `tbl_product_categories`.`category_id`))) join `tbl_product_variants` on((`tbl_product_categories`.`product_id` = `tbl_product_variants`.`product_id`))) join `tbl_order_details` on((`tbl_product_variants`.`sku` = `tbl_order_details`.`sku`))) group by `tbl_categories`.`category_id` ;

-- --------------------------------------------------------

--
-- Structure for view `view_cart_items`
--
DROP TABLE IF EXISTS `view_cart_items`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_cart_items`  AS  select `tbl_carts`.`customer_id` AS `customer_id`,`tbl_carts`.`sku` AS `sku`,`tbl_products`.`product_name` AS `product_name`,`tbl_products`.`product_brand` AS `product_brand`,`tbl_products`.`product_image` AS `product_image`,`tbl_product_variants`.`product_variant_image` AS `product_variant_image`,`tbl_carts`.`quantity` AS `quantity`,`tbl_product_variants`.`unit_price` AS `unit_price`,(`tbl_carts`.`quantity` * `tbl_product_variants`.`unit_price`) AS `total_price`,`tbl_carts`.`date_added` AS `date_added` from (`tbl_carts` join (`tbl_product_variants` join `tbl_products` on((`tbl_product_variants`.`product_id` = `tbl_products`.`product_id`)))) where ((`tbl_carts`.`sku` = `tbl_product_variants`.`sku`) and (`tbl_carts`.`item_status` = 'added')) ;

-- --------------------------------------------------------

--
-- Structure for view `view_categories`
--
DROP TABLE IF EXISTS `view_categories`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `view_categories`  AS  select `a`.`category_id` AS `category_id`,`a`.`category_name` AS `category_name`,`b`.`subcategory_id` AS `subcategory_id`,`c`.`category_name` AS `subcategory_name` from (`tbl_categories` `a` left join (`tbl_subcategories` `b` join `tbl_categories` `c` on((`b`.`subcategory_id` = `c`.`category_id`))) on((`a`.`category_id` = `b`.`category_id`))) where (not(`a`.`category_id` in (select `tbl_subcategories`.`subcategory_id` from `tbl_subcategories`))) order by `a`.`category_id`,`b`.`subcategory_id` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tbl_carts`
--
ALTER TABLE `tbl_carts`
  ADD PRIMARY KEY (`customer_id`,`sku`,`date_added`),
  ADD KEY `sku` (`sku`);

--
-- Indexes for table `tbl_categories`
--
ALTER TABLE `tbl_categories`
  ADD PRIMARY KEY (`category_id`) USING BTREE,
  ADD UNIQUE KEY `category_name` (`category_name`);

--
-- Indexes for table `tbl_customers`
--
ALTER TABLE `tbl_customers`
  ADD PRIMARY KEY (`customer_id`);

--
-- Indexes for table `tbl_customer_offers`
--
ALTER TABLE `tbl_customer_offers`
  ADD PRIMARY KEY (`customer_id`,`offer_id`),
  ADD KEY `offer_id` (`offer_id`);

--
-- Indexes for table `tbl_freight_details`
--
ALTER TABLE `tbl_freight_details`
  ADD PRIMARY KEY (`tracking_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `tbl_offers`
--
ALTER TABLE `tbl_offers`
  ADD PRIMARY KEY (`offer_id`);

--
-- Indexes for table `tbl_orders`
--
ALTER TABLE `tbl_orders`
  ADD PRIMARY KEY (`order_id`),
  ADD KEY `customer_id` (`customer_id`);

--
-- Indexes for table `tbl_order_details`
--
ALTER TABLE `tbl_order_details`
  ADD PRIMARY KEY (`order_id`,`sku`),
  ADD KEY `sku` (`sku`);

--
-- Indexes for table `tbl_payments`
--
ALTER TABLE `tbl_payments`
  ADD PRIMARY KEY (`payment_id`),
  ADD KEY `order_id` (`order_id`);

--
-- Indexes for table `tbl_products`
--
ALTER TABLE `tbl_products`
  ADD PRIMARY KEY (`product_id`);

--
-- Indexes for table `tbl_product_categories`
--
ALTER TABLE `tbl_product_categories`
  ADD PRIMARY KEY (`category_id`,`product_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `tbl_product_variants`
--
ALTER TABLE `tbl_product_variants`
  ADD PRIMARY KEY (`sku`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `tbl_product_variant_details`
--
ALTER TABLE `tbl_product_variant_details`
  ADD PRIMARY KEY (`sku`,`attribute_name`);

--
-- Indexes for table `tbl_product_variant_offers`
--
ALTER TABLE `tbl_product_variant_offers`
  ADD PRIMARY KEY (`sku`,`offer_id`),
  ADD KEY `offer_id` (`offer_id`);

--
-- Indexes for table `tbl_product_variant_promos`
--
ALTER TABLE `tbl_product_variant_promos`
  ADD PRIMARY KEY (`sku`,`promo_id`),
  ADD KEY `promo_id` (`promo_id`);

--
-- Indexes for table `tbl_product_variant_ratings_reviews`
--
ALTER TABLE `tbl_product_variant_ratings_reviews`
  ADD PRIMARY KEY (`sku`,`user_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `tbl_promos`
--
ALTER TABLE `tbl_promos`
  ADD PRIMARY KEY (`promo_id`),
  ADD UNIQUE KEY `promo_code` (`promo_code`);

--
-- Indexes for table `tbl_shipping_address`
--
ALTER TABLE `tbl_shipping_address`
  ADD PRIMARY KEY (`order_id`);

--
-- Indexes for table `tbl_subcategories`
--
ALTER TABLE `tbl_subcategories`
  ADD PRIMARY KEY (`category_id`,`subcategory_id`),
  ADD KEY `subcategory_id` (`subcategory_id`);

--
-- Indexes for table `tbl_telephones`
--
ALTER TABLE `tbl_telephones`
  ADD PRIMARY KEY (`customer_id`,`telephone`);

--
-- Indexes for table `tbl_users`
--
ALTER TABLE `tbl_users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `tbl_user_promos`
--
ALTER TABLE `tbl_user_promos`
  ADD PRIMARY KEY (`user_id`,`promo_id`),
  ADD KEY `promo_id` (`promo_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tbl_categories`
--
ALTER TABLE `tbl_categories`
  MODIFY `category_id` int(15) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `tbl_customers`
--
ALTER TABLE `tbl_customers`
  MODIFY `customer_id` int(10) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=129;

--
-- AUTO_INCREMENT for table `tbl_freight_details`
--
ALTER TABLE `tbl_freight_details`
  MODIFY `tracking_id` int(15) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- AUTO_INCREMENT for table `tbl_offers`
--
ALTER TABLE `tbl_offers`
  MODIFY `offer_id` int(15) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tbl_orders`
--
ALTER TABLE `tbl_orders`
  MODIFY `order_id` int(15) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=33;

--
-- AUTO_INCREMENT for table `tbl_payments`
--
ALTER TABLE `tbl_payments`
  MODIFY `payment_id` int(15) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

--
-- AUTO_INCREMENT for table `tbl_products`
--
ALTER TABLE `tbl_products`
  MODIFY `product_id` int(15) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `tbl_promos`
--
ALTER TABLE `tbl_promos`
  MODIFY `promo_id` int(15) UNSIGNED ZEROFILL NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `tbl_carts`
--
ALTER TABLE `tbl_carts`
  ADD CONSTRAINT `tbl_carts_ibfk_2` FOREIGN KEY (`sku`) REFERENCES `tbl_product_variants` (`sku`),
  ADD CONSTRAINT `tbl_carts_ibfk_3` FOREIGN KEY (`customer_id`) REFERENCES `tbl_customers` (`customer_id`);

--
-- Constraints for table `tbl_customer_offers`
--
ALTER TABLE `tbl_customer_offers`
  ADD CONSTRAINT `tbl_customer_offers_ibfk_2` FOREIGN KEY (`offer_id`) REFERENCES `tbl_offers` (`offer_id`),
  ADD CONSTRAINT `tbl_customer_offers_ibfk_3` FOREIGN KEY (`customer_id`) REFERENCES `tbl_customers` (`customer_id`);

--
-- Constraints for table `tbl_freight_details`
--
ALTER TABLE `tbl_freight_details`
  ADD CONSTRAINT `tbl_freight_details_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `tbl_orders` (`order_id`);

--
-- Constraints for table `tbl_orders`
--
ALTER TABLE `tbl_orders`
  ADD CONSTRAINT `tbl_orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `tbl_customers` (`customer_id`);

--
-- Constraints for table `tbl_order_details`
--
ALTER TABLE `tbl_order_details`
  ADD CONSTRAINT `tbl_order_details_ibfk_2` FOREIGN KEY (`sku`) REFERENCES `tbl_product_variants` (`sku`),
  ADD CONSTRAINT `tbl_order_details_ibfk_3` FOREIGN KEY (`order_id`) REFERENCES `tbl_orders` (`order_id`);

--
-- Constraints for table `tbl_payments`
--
ALTER TABLE `tbl_payments`
  ADD CONSTRAINT `tbl_payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `tbl_orders` (`order_id`);

--
-- Constraints for table `tbl_product_categories`
--
ALTER TABLE `tbl_product_categories`
  ADD CONSTRAINT `tbl_product_categories_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `tbl_products` (`product_id`),
  ADD CONSTRAINT `tbl_product_categories_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `tbl_categories` (`category_id`);

--
-- Constraints for table `tbl_product_variants`
--
ALTER TABLE `tbl_product_variants`
  ADD CONSTRAINT `tbl_product_variants_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `tbl_products` (`product_id`);

--
-- Constraints for table `tbl_product_variant_details`
--
ALTER TABLE `tbl_product_variant_details`
  ADD CONSTRAINT `tbl_product_variant_details_ibfk_1` FOREIGN KEY (`sku`) REFERENCES `tbl_product_variants` (`sku`);

--
-- Constraints for table `tbl_product_variant_offers`
--
ALTER TABLE `tbl_product_variant_offers`
  ADD CONSTRAINT `tbl_product_variant_offers_ibfk_1` FOREIGN KEY (`sku`) REFERENCES `tbl_product_variants` (`sku`),
  ADD CONSTRAINT `tbl_product_variant_offers_ibfk_2` FOREIGN KEY (`offer_id`) REFERENCES `tbl_offers` (`offer_id`);

--
-- Constraints for table `tbl_product_variant_promos`
--
ALTER TABLE `tbl_product_variant_promos`
  ADD CONSTRAINT `tbl_product_variant_promos_ibfk_1` FOREIGN KEY (`sku`) REFERENCES `tbl_product_variants` (`sku`),
  ADD CONSTRAINT `tbl_product_variant_promos_ibfk_2` FOREIGN KEY (`promo_id`) REFERENCES `tbl_promos` (`promo_id`);

--
-- Constraints for table `tbl_product_variant_ratings_reviews`
--
ALTER TABLE `tbl_product_variant_ratings_reviews`
  ADD CONSTRAINT `tbl_product_variant_ratings_reviews_ibfk_1` FOREIGN KEY (`sku`) REFERENCES `tbl_product_variants` (`sku`),
  ADD CONSTRAINT `tbl_product_variant_ratings_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `tbl_users` (`user_id`);

--
-- Constraints for table `tbl_shipping_address`
--
ALTER TABLE `tbl_shipping_address`
  ADD CONSTRAINT `tbl_shipping_address_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `tbl_orders` (`order_id`);

--
-- Constraints for table `tbl_subcategories`
--
ALTER TABLE `tbl_subcategories`
  ADD CONSTRAINT `tbl_subcategories_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `tbl_categories` (`category_id`),
  ADD CONSTRAINT `tbl_subcategories_ibfk_2` FOREIGN KEY (`subcategory_id`) REFERENCES `tbl_categories` (`category_id`);

--
-- Constraints for table `tbl_telephones`
--
ALTER TABLE `tbl_telephones`
  ADD CONSTRAINT `tbl_telephones_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `tbl_customers` (`customer_id`);

--
-- Constraints for table `tbl_users`
--
ALTER TABLE `tbl_users`
  ADD CONSTRAINT `tbl_users_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `tbl_customers` (`customer_id`);

--
-- Constraints for table `tbl_user_promos`
--
ALTER TABLE `tbl_user_promos`
  ADD CONSTRAINT `tbl_user_promos_ibfk_2` FOREIGN KEY (`promo_id`) REFERENCES `tbl_promos` (`promo_id`),
  ADD CONSTRAINT `tbl_user_promos_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `tbl_users` (`user_id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
