-- MySQL dump 10.13  Distrib 8.0.30, for Linux (x86_64)
--
-- Host: localhost    Database: DevOps
-- ------------------------------------------------------
-- Server version       8.0.30

CREATE USER IF NOT EXISTS lambda IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS'; 
GRANT ALL PRIVILEGES ON DevOps.* to lambda;


DROP DATABASE IF EXISTS DevOps;
CREATE DATABASE DevOps;

USE DevOps;

--
-- Table structure for table `Files`
--

DROP TABLE IF EXISTS `Files`;

CREATE TABLE `Files` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(30) NOT NULL,
  `size` int unsigned NOT NULL,
  `downloads` int unsigned DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB ;


--
-- Dumping data for table `Files`
--

LOCK TABLES `Files` WRITE;
INSERT INTO `Files` VALUES 
('test1.txt', 120),
('test2.txt', 1248),
('test3.txt', 42069),
('test4.txt', 4096),
('test5.txt', 8284),
('test6.txt', 1222222),
('test7.txt', 92929292);
UNLOCK TABLES;
