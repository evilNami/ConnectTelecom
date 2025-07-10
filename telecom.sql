
--  Telecommunication Assignment SQL Script

-- ====================================
-- Part 1: Database Design
-- ====================================

-- #### Creation and selection of database

CREATE DATABASE IF NOT EXISTS ConnectTelecom ;
USE ConnectTelecom;

-- #### Stored Procedure to Drop an Index if it Exists in the current schema

DELIMITER //
CREATE PROCEDURE DropIndexIfExists(
  IN tblName VARCHAR(64),  -- Input parameter
  IN idxName VARCHAR(64)   -- Input parameter
)
BEGIN   -- Checking if the specified index exists in the schema for the database
  IF EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = tblName
      AND INDEX_NAME = idxName
  ) THEN
  -- SQL query to drop the index from the table
    SET @sql = CONCAT(' ALTER TABLE ', tblName, ' DROP INDEX ', idxName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END //
DELIMITER ;

-- #### DROP TABLES IF THEY EXIST (to ensure clean re-creation)

DROP TABLE IF EXISTS SupportTicket;
DROP TABLE IF EXISTS MaintenanceSchedule;
DROP TABLE IF EXISTS CellSite;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS InvoiceItem;
DROP TABLE IF EXISTS Invoice;
DROP TABLE IF EXISTS UsageSummary;
DROP TABLE IF EXISTS DataUsageRecord;
DROP TABLE IF EXISTS SMSRecord;
DROP TABLE IF EXISTS CallDetailRecord;
DROP TABLE IF EXISTS Subscription;
DROP TABLE IF EXISTS SIMCard;
DROP TABLE IF EXISTS Device;
DROP TABLE IF EXISTS PhoneNumber;
DROP TABLE IF EXISTS ServicePlan;
DROP TABLE IF EXISTS Accounts;
DROP TABLE IF EXISTS Address;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS NetworkElement;
DROP TABLE IF EXISTS Customer;

-- #### Tables creation

-- Customer & Account Management --

CREATE TABLE Customer(
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  date_of_birth DATE NOT NULL,
  gender ENUM('M','F','N/A') NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone_primary VARCHAR(20),
  tax_id VARCHAR(50)
) ENGINE=InnoDB ;

CREATE TABLE Address(
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  address_type ENUM('Billing','Home') NOT NULL,
  street VARCHAR(255) NOT NULL,
  house_number VARCHAR(20) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  country VARCHAR(100) NOT NULL DEFAULT 'Germany',
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE Accounts(
  account_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  account_number VARCHAR(50) NOT NULL UNIQUE,
  account_status ENUM('Active','Suspended','Closed','Dormant') NOT NULL,
  account_start_date DATE NOT NULL,
  account_end_date DATE,
  credit_limit DECIMAL(10,2) DEFAULT 0.00,
  payment_term_days INT DEFAULT 30,
  preferred_language VARCHAR(50) NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
   ON DELETE RESTRICT 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

-- Service & Subscription Management --

CREATE TABLE ServicePlan(
  plan_id INT AUTO_INCREMENT PRIMARY KEY,
  plan_name VARCHAR(100) NOT NULL UNIQUE,
  plan_type ENUM('Postpaid','Prepaid') NOT NULL,
  monthly_fee DECIMAL(9,2) NOT NULL,
  setup_fee DECIMAL(9,2) NOT NULL DEFAULT 0.00,
  data_allowance_gb INT NOT NULL,
  free_minutes INT NOT NULL,
  free_sms INT NOT NULL,
  average_call_rate DECIMAL(5,2) NOT NULL,
  average_sms_rate DECIMAL(5,2) NOT NULL,
  average_data_rate_per_gb DECIMAL(5,3) NOT NULL,
  validity_period_days INT NOT NULL,
  roaming_included BOOLEAN NOT NULL DEFAULT FALSE,
  regulatory_fee DECIMAL(6,2) DEFAULT 0.00
) ENGINE=InnoDB ;


CREATE TABLE PhoneNumber(
  phone_number_id INT AUTO_INCREMENT PRIMARY KEY,
  e164_number VARCHAR(20) NOT NULL UNIQUE,
  number_type ENUM('Mobile','VoIP','Landline','Fax') NOT NULL,
  status_number ENUM('Assigned','Reserved','Porting','Deactivated') NOT NULL,
  activation_date DATE NOT NULL,
  deactivation_date DATE,
  porting_requested BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB ;

CREATE TABLE SIMCard (
  sim_card_id INT AUTO_INCREMENT PRIMARY KEY,
  iccid VARCHAR(50) NOT NULL UNIQUE,
  imsi VARCHAR(50) NOT NULL UNIQUE,
  status_sim ENUM('Inactive','Active','Blocked') NOT NULL,
  issue_date DATE NOT NULL,
  activation_date DATE NOT NULL,
  block_date DATE,
  phone_number_id INT,
  FOREIGN KEY (phone_number_id) REFERENCES PhoneNumber(phone_number_id)
   ON DELETE SET NULL 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE Subscription(
  subscription_id INT AUTO_INCREMENT PRIMARY KEY,
  account_id INT NOT NULL,
  plan_id INT NOT NULL,
  sim_card_id INT NOT NULL,
  phone_number_id INT NOT NULL,
  subscription_status ENUM('Active','Suspended') NOT NULL,
  activation_date DATE NOT NULL,
  deactivation_date DATE,
  auto_renew BOOLEAN NOT NULL DEFAULT TRUE,
  last_billed_date DATE,
  next_billing_date DATE,
  FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
   ON DELETE RESTRICT 
   ON UPDATE CASCADE ,

  FOREIGN KEY (plan_id) REFERENCES ServicePlan(plan_id)
   ON DELETE RESTRICT 
   ON UPDATE CASCADE ,
  
  FOREIGN KEY (sim_card_id) REFERENCES SIMCard(sim_card_id)
   ON DELETE RESTRICT 
   ON UPDATE CASCADE,
  
  FOREIGN KEY (phone_number_id) REFERENCES PhoneNumber(phone_number_id)
   ON DELETE RESTRICT 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;


-- Usage & Billing --

CREATE TABLE CallDetailRecord(
  id INT AUTO_INCREMENT PRIMARY KEY,
  subscription_id INT NOT NULL,
  phone_number_called VARCHAR(20) NOT NULL,
  call_start_time DATETIME NOT NULL,
  call_end_time DATETIME NOT NULL,
  duration_seconds INT NOT NULL,
  call_type ENUM('Voice','RoamingVoice','InternationalVoice','Emergency') NOT NULL,
  call_direction ENUM('Outgoing','Incoming','Missed') NOT NULL,
  billing_cycle_month INT NOT NULL,
  total_charge DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE SMSRecord(
  sms_id INT AUTO_INCREMENT PRIMARY KEY,
  subscription_id INT NOT NULL,
  phone_number_to VARCHAR(20) NOT NULL,
  phone_number_from VARCHAR(20) NOT NULL,
  message_timestamp DATETIME NOT NULL,
  sms_type ENUM('SMS','MMS','RoamingSMS','InternationalSMS') NOT NULL,
  billing_cycle_month INT NOT NULL,
  total_charge DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE DataUsageRecord(
  data_usage_id INT AUTO_INCREMENT PRIMARY KEY,
  subscription_id INT NOT NULL,
  session_start DATETIME NOT NULL,
  session_end DATETIME NOT NULL,
  bytes_downloaded BIGINT NOT NULL,
  bytes_uploaded BIGINT NOT NULL,
  billing_cycle_month INT NOT NULL,
  total_charge DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE UsageSummary(
  usage_summary_id INT AUTO_INCREMENT PRIMARY KEY,
  subscription_id INT NOT NULL,
  billing_cycle_month INT NOT NULL,
  total_voice_minutes INT NOT NULL,
  total_sms_count INT NOT NULL,
  total_data_mb INT NOT NULL,
  total_voice_charges DECIMAL(10,2) NOT NULL,
  total_sms_charges DECIMAL(10,2) NOT NULL,
  total_data_charges DECIMAL(10,2) NOT NULL,
  generated_at DATETIME NOT NULL,
  FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE Invoice (
  invoice_id INT AUTO_INCREMENT PRIMARY KEY,
  account_id INT NOT NULL,
  billing_cycle_start DATE NOT NULL,
  billing_cycle_end DATE NOT NULL,
  invoice_date DATE NOT NULL,
  due_date DATE NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL,
  status_invoice ENUM('Pending','Paid','Overdue','Cancelled') NOT NULL,
  previous_balance DECIMAL(12,2) DEFAULT 0.00,
  payments_applied DECIMAL(12,2) DEFAULT 0.00,
  new_balance DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
   ON DELETE RESTRICT 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE InvoiceItem (
  invoice_item_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  item_type ENUM('SubscriptionFee','VoiceUsage','SMSUsage','DataUsage','Roaming','OneTimeCharge') NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,3) NOT NULL,
  total_price DECIMAL(10,3) NOT NULL,
  created_at TIMESTAMP  DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE Payment (
  payment_id INT AUTO_INCREMENT PRIMARY KEY,
  invoice_id INT NOT NULL,
  account_id INT NOT NULL,
  payment_date DATE NOT NULL,
  amount_paid DECIMAL(12,2) NOT NULL,
  payment_method ENUM('SEPA','CreditCard','PayPal','Cash','Voucher','DirectDebit') NOT NULL,
  transaction_reference VARCHAR(100),
  status_payment ENUM('Received','Cleared','Failed','Refunded') NOT NULL,
  FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE ,
  
  FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
   ON DELETE RESTRICT 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

-- Transaction --

CREATE TABLE IF NOT EXISTS AccountTransaction (
  txn_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  account_id INT NOT NULL,
  invoice_id INT NULL,
  txn_datetime DATETIME NOT NULL,
  txn_type ENUM('InvoicePost','Payment','Refund','AdjustmentCr','AdjustmentDr') NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency CHAR(10) NOT NULL DEFAULT 'EUR',
  balance_after_txn DECIMAL(12,2) NULL,
  FOREIGN KEY (account_id) REFERENCES Accounts(account_id)
    ON DELETE RESTRICT 
    ON UPDATE CASCADE,
    
  FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id)
    ON DELETE SET NULL 
    ON UPDATE CASCADE
) ENGINE=InnoDB;


-- Network & Infrastructure --

CREATE TABLE NetworkElement (
  network_element_id INT AUTO_INCREMENT PRIMARY KEY,
  element_type ENUM('MSC','SGSN','GGSN','HSS','PCRF','IMS','BTS','NodeB','eNodeB','gNodeB','OLT','CoreRouter','Aggregator') NOT NULL,
  element_name VARCHAR(100) NOT NULL UNIQUE,
  ip_address VARCHAR(45),
  location_lat DECIMAL(9,6),
  location_long DECIMAL(9,6),
  vendor VARCHAR(100),
  installation_date DATE,
  status_element ENUM('Operational','Maintenance','Planned') NOT NULL
) ENGINE=InnoDB ;

CREATE TABLE CellSite (
  id INT AUTO_INCREMENT PRIMARY KEY,
  network_element_id INT ,
  site_code VARCHAR(50) NOT NULL UNIQUE,
  location VARCHAR(50) NOT NULL,
  bandwidth ENUM('900MHz','1800MHz','2100MHz','2600MHz','3500MHz') NOT NULL,
  technology ENUM('2G','3G','4G','5G') NOT NULL,
  height DECIMAL(5,2),
  FOREIGN KEY (network_element_id) REFERENCES NetworkElement(network_element_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

-- Support & Maintenance --

CREATE TABLE Employee (
  id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  designation ENUM('SupportAgent','NetworkEngineer','BillingClerk','Manager','Technician') NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone_number VARCHAR(20),
  hired_date DATE NOT NULL,
  terminated_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  manager_id INT,
  FOREIGN KEY (manager_id) REFERENCES Employee(id)
   ON DELETE SET NULL
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE MaintenanceSchedule (
  maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
  network_element_id INT NOT NULL,
  maintenance_start DATETIME NOT NULL,
  maintenance_end DATETIME NOT NULL,
  maintenance_type ENUM('Planned','Emergency','Upgrade') NOT NULL,
  engineer_id INT,
  status_maintenance ENUM('Scheduled','InProgress','Completed','Cancelled') NOT NULL,
  FOREIGN KEY (network_element_id) REFERENCES NetworkElement(network_element_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE,
   
  FOREIGN KEY (engineer_id) REFERENCES Employee(id)
   ON DELETE SET NULL 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

CREATE TABLE SupportTicket (
  ticket_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  subscription_id INT,
  opened_date DATETIME NOT NULL,
  closed_date DATETIME,
  ticket_status ENUM('Open','Assigned','Escalated','Resolved','Reopened') NOT NULL,
  priority ENUM('Low','Medium','High') NOT NULL,
  issue_category ENUM('Billing','Network','Device','SIM','Provisioning','Software','GeneralInquiry') NOT NULL,
  assigned_to INT,
  issue_description VARCHAR(100) NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
   ON DELETE CASCADE 
   ON UPDATE CASCADE,
   
  FOREIGN KEY (subscription_id) REFERENCES Subscription(subscription_id)
    ON DELETE SET NULL 
    ON UPDATE CASCADE,
    
  FOREIGN KEY (assigned_to) REFERENCES Employee(id)
   ON DELETE SET NULL 
   ON UPDATE CASCADE
) ENGINE=InnoDB ;

-- Audit Log --

CREATE TABLE AuditLog (
  audit_id BIGINT AUTO_INCREMENT,
  table_name VARCHAR(64) NOT NULL,
  row_changed VARCHAR(128) NOT NULL,
  operation ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  changed_by INT ,
  before_state JSON NULL ,
  after_state JSON NULL,
  PRIMARY KEY (audit_id, changed_at)
) ENGINE=InnoDB
PARTITION BY RANGE (YEAR(changed_at)) (
  PARTITION p2020 VALUES LESS THAN (2021),
  PARTITION p2021 VALUES LESS THAN (2022),
  PARTITION p2022 VALUES LESS THAN (2023),
  PARTITION p2023 VALUES LESS THAN (2024),
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION pMax VALUES LESS THAN MAXVALUE
);



-- Use the stored procedure to drop indexes if they exist

-- Accounts status lookup
CALL DropIndexIfExists('Accounts', 'idx_account_status');
ALTER TABLE Accounts ADD INDEX idx_account_status (account_status);
-- Subscription status lookup
CALL DropIndexIfExists('Subscription', 'idx_subscription_status');
ALTER TABLE Subscription ADD INDEX idx_subscription_status (subscription_status);

-- Invoice & payment lookups per account and statement period
CALL DropIndexIfExists('Invoice', 'idx_invoice_acct_date');
ALTER TABLE Invoice ADD INDEX idx_invoice_acct_date (account_id, invoice_date);
CALL DropIndexIfExists('Payment', 'idx_payment_acct_date');
ALTER TABLE Payment ADD INDEX idx_payment_acct_date (account_id, payment_date);



-- ====================================
-- Part 2: Populating with Sample Data
-- ====================================

-- Customers --
INSERT INTO Customer (first_name, last_name, date_of_birth, gender, email , phone_primary, tax_id) 
VALUES
('Alice','Müller','1985-04-12','F','alice.mueller@example.com','01511230001','TAX0001'),
('Bruno','Schmidt','1978-07-05','M','bruno.schmidt@example.com','01511230002','TAX0002'),
('Carina','Fischer','1990-11-23','F','carina.fischer@example.com','01511230003','TAX0003'),
('David','Weber','1982-01-17','M','david.weber@example.com','01511230004','TAX0004'),
('Emilie','Wagner','1975-05-30','F','emilie.wagner@example.com','01511230005','TAX0005'),
('Felix','Becker','1993-09-08','M','felix.becker@example.com','01511230006','TAX0006'),
('Greta','Hoffmann','1988-03-14','F','greta.hoffmann@example.com','01511230007','TAX0007'),
('Hans','Bauer','1969-12-01','M','hans.bauer@example.com','01511230008','TAX0008'),
('Iris','Schulz','1995-06-18','F','iris.schulz@example.com','01511230009','TAX0009'),
('Jonas','Klein','1980-10-02','M','jonas.klein@example.com','01511230010','TAX0010'),
('Katharina','Richter','1977-08-21','F','katharina.richter@example.com','01511230011','TAX0011'),
('Leon','Wolf','1991-02-03','M','leon.wolf@example.com','01511230012','TAX0012'),
('Marie','Neumann','1984-04-26','F','marie.neumann@example.com','01511230013','TAX0013'),
('Niklas','Braun','1996-07-11','M','niklas.braun@example.com','01511230014','TAX0014'),
('Olivia','Krüger','1992-09-29','F','olivia.krueger@example.com','01511230015','TAX0015'),
('Paul','Lehmann','1973-11-05','M','paul.lehmann@example.com','01511230016','TAX0016'),
('Quentin','Scholz','1987-03-22','M','quentin.scholz@example.com','01511230017','TAX0017'),
('Rosa','Hartmann','1994-05-13','F','rosa.hartmann@example.com','01511230018','TAX0018'),
('Stefan','Zimmermann','1981-07-09','M','stefan.zimmermann@example.com','01511230019','TAX0019'),
('Tina','König','1998-12-27','F','tina.koenig@example.com','01511230020','TAX0020'),
('Uwe','Schmitt','1972-01-15','M','uwe.schmitt@example.com','01511230021','TAX0021'),
('Vera','Lang','1986-06-07','F','vera.lang@example.com','01511230022','TAX0022'),
('Wolfgang','Weiß','1970-02-19','M','wolfgang.weiss@example.com','01511230023','TAX0023'),
('Xenia','Hart','1997-08-30','F','xenia.hart@example.com','01511230024','TAX0024'),
('Yannik','Mayer','1999-10-16','M','yannik.mayer@example.com','01511230025','TAX0025'),
('Zoe','Lindemann','1983-12-08','F','zoe.lindemann@example.com','01511230026','TAX0026'),
('Benedikt','Herrmann','1976-05-21','M','benedikt.herrmann@example.com','01511230027','TAX0027'),
('Claudia','Busch','1990-09-14','F','claudia.busch@example.com','01511230028','TAX0028'),
('Daniel','Schäfer','1989-11-20','M','daniel.schaefer@example.com','01511230029','TAX0029'),
('Eva','König','2000-02-29','F','eva.koenig@example.com','01511230030','TAX0030');


-- Address --
INSERT INTO Address (customer_id, address_type, street, house_number, postal_code, city, state, country, is_current) 
VALUES
(1, 'Billing', 'Hauptstraße', '12A', '10115', 'Berlin', 'Berlin', 'Germany', TRUE),
(2, 'Home', 'Bahnhofstraße', '8B', '80331', 'München', 'Bayern', 'Germany', TRUE),
(3, 'Billing', 'Marktstraße', '15', '50667', 'Köln', 'NRW', 'Germany', TRUE),
(4, 'Home', 'Lindenweg', '9', '04109', 'Leipzig', 'Sachsen', 'Germany', TRUE),
(5, 'Billing', 'Kirchplatz', '3', '28195', 'Bremen', 'Bremen', 'Germany', TRUE),
(6, 'Home', 'Parkallee', '22', '70173', 'Stuttgart', 'Baden-Württemberg', 'Germany', TRUE),
(7, 'Billing', 'Hauptstraße', '12A', '10115', 'Berlin', 'Berlin', 'Germany', TRUE), 
(8, 'Home', 'Goethestraße', '11', '04109', 'Leipzig', 'Sachsen', 'Germany', TRUE),
(9, 'Billing', 'Mozartstraße', '5', '01067', 'Dresden', 'Sachsen', 'Germany', TRUE),
(10, 'Home', 'Friedrichstraße', '101', '10969', 'Berlin', 'Berlin', 'Germany', TRUE),
(11, 'Billing', 'Am Ring', '7', '47051', 'Duisburg', 'NRW', 'Germany', TRUE),
(12, 'Home', 'Berliner Allee', '31', '40212', 'Düsseldorf', 'NRW', 'Germany', TRUE),
(13, 'Billing', 'Königsallee', '1', '40212', 'Düsseldorf', 'NRW', 'Germany', TRUE),
(14, 'Home', 'Hohenzollernstraße', '45', '80796', 'München', 'Bayern', 'Germany', TRUE),
(15, 'Billing', 'Musterweg', '100', '20095', 'Hamburg', 'Hamburg', 'Germany', TRUE),
(16, 'Home', 'Seeweg', '19', '60594', 'Frankfurt', 'Hessen', 'Germany', TRUE),
(17, 'Billing', 'Schillerstraße', '66', '70173', 'Stuttgart', 'Baden-Württemberg', 'Germany', TRUE),
(18, 'Home', 'Bachstraße', '23', '01067', 'Dresden', 'Sachsen', 'Germany', TRUE),
(19, 'Billing', 'Hauptstraße', '12A', '10115', 'Berlin', 'Berlin', 'Germany', TRUE), 
(20, 'Home', 'Brunnenweg', '88', '55116', 'Mainz', 'Rheinland-Pfalz', 'Germany', TRUE),
(21, 'Billing', 'Poststraße', '55', '90402', 'Nürnberg', 'Bayern', 'Germany', TRUE),
(22, 'Home', 'Uferweg', '5', '14467', 'Potsdam', 'Brandenburg', 'Germany', TRUE),
(23, 'Billing', 'Bebelplatz', '17', '99423', 'Weimar', 'Thüringen', 'Germany', TRUE),
(24, 'Home', 'Steinstraße', '13', '48143', 'Münster', 'NRW', 'Germany', TRUE),
(25, 'Billing', 'Ringstraße', '44', '19053', 'Schwerin', 'Mecklenburg-Vorpommern', 'Germany', TRUE),
(26, 'Home', 'Blumenweg', '18', '30159', 'Hannover', 'Niedersachsen', 'Germany', TRUE),
(27, 'Billing', 'Burgstraße', '27', '99084', 'Erfurt', 'Thüringen', 'Germany', TRUE),
(28, 'Home', 'Neustraße', '3', '66111', 'Saarbrücken', 'Saarland', 'Germany', TRUE),
(29, 'Billing', 'Alte Allee', '7', '53111', 'Bonn', 'NRW', 'Germany', TRUE),
(30, 'Home', 'Waldstraße', '9', '60311', 'Frankfurt', 'Hessen', 'Germany', TRUE);


-- Accounts --
INSERT INTO Accounts (customer_id, account_number, account_status, account_start_date, account_end_date, 
               credit_limit, payment_term_days, preferred_language)
VALUES
(1,'ACC0001','Active','2020-01-30',NULL,500.00,30,'DE'),
(2,'ACC0002','Suspended','2020-01-30','2021-02-14',750.00,30,'DE'),
(3,'ACC0003','Active','2020-06-20',NULL,1000.00,30,'DE'),
(4,'ACC0004','Suspended','2020-06-20','2021-07-01',1250.00,30,'DE'),
(5,'ACC0005','Active','2021-04-04',NULL,1500.00,30,'DE'),
(6,'ACC0006','Suspended','2021-04-04','2022-04-20',1750.00,30,'DE'),
(7,'ACC0007','Active','2021-09-25',NULL,2000.00,30,'DE'),
(8,'ACC0008','Suspended','2021-09-25','2022-10-01',2250.00,30,'DE'),
(9,'ACC0009','Active','2022-02-16',NULL,2500.00,30,'DE'),
(10,'ACC0010','Suspended','2022-02-16','2023-03-01',2750.00,30,'DE'),
(11,'ACC0011','Active','2022-08-02',NULL,3000.00,30,'DE'),
(12,'ACC0012','Suspended','2022-08-02','2023-09-15',3250.00,30,'DE'),
(13,'ACC0013','Active','2023-05-07',NULL,500.00,30,'DE'),
(14,'ACC0014','Suspended','2023-05-07','2024-05-20',750.00,30,'DE'),
(15,'ACC0015','Active','2023-12-15',NULL,1000.00,30,'DE'),
(16,'ACC0016','Suspended','2023-12-15','2025-01-01',1250.00,30,'DE'),
(17,'ACC0017','Active','2024-05-24',NULL,1500.00,30,'DE'),
(18,'ACC0018','Active','2024-05-24',NULL,1750.00,30,'DE'),
(19,'ACC0019','Active','2024-12-27',NULL,2000.00,30,'DE'),
(20,'ACC0020','Active','2024-12-27',NULL,2250.00,30,'DE'),
(21,'ACC0021','Active','2025-01-23',NULL,2500.00,30,'DE'),
(22,'ACC0022','Active','2025-01-23',NULL,2750.00,30,'DE'),
(23,'ACC0023','Active','2025-04-09',NULL,3000.00,30,'DE'),
(24,'ACC0024','Active','2025-04-09',NULL,3250.00,30,'DE'),
(25,'ACC0025','Active','2025-05-16',NULL,500.00,30,'DE'),
(26,'ACC0026','Active','2025-05-16',NULL,750.00,30,'DE'),
(27,'ACC0027','Active','2025-05-31',NULL,1000.00,30,'DE'),
(28,'ACC0028','Active','2025-05-31',NULL,1250.00,30,'DE'),
(29,'ACC0029','Active','2025-06-04',NULL,1500.00,30,'DE'),
(30,'ACC0030','Active','2025-06-04',NULL,1750.00,30,'DE');



-- Service Plans --
INSERT INTO ServicePlan(plan_name, plan_type, monthly_fee, setup_fee, data_allowance_gb, free_minutes, free_sms,
                 average_call_rate, average_sms_rate, average_data_rate_per_gb, validity_period_days, roaming_included, regulatory_fee)
VALUES
  ('Basic Prepaid',  'Prepaid', 4.99, 9.90, 1, 10, 10, 0.05, 0.03, 1.99, 30, FALSE, 0.00),
  ('Standard Prepaid','Prepaid', 9.90, 9.90, 5, 50, 50, 0.05, 0.03, 1.99, 30, TRUE,  1.00),
  ('Premium Prepaid', 'Prepaid', 19.90, 0.00, 10, 100, 100, 0.05, 0.03, 1.99, 30, TRUE,  2.00),
  ('Basic Postpaid', 'Postpaid', 19.90, 0.00, 7, 100, 100, 0.03, 0.02, 1.49, 30, TRUE,  1.50),
  ('Standard Postpaid','Postpaid', 29.90, 0.00, 10, 300, 300, 0.03, 0.02, 1.49, 30, TRUE,  2.00),
  ('Premium Postpaid', 'Postpaid', 49.90, 0.00, 20, 1500, 1500, 0.03, 0.02, 1.49, 30,TRUE, 3.00),
  ('Business Postpaid','Postpaid', 99.90, 0.00, 50, 3000, 3000, 0.02, 0.01, 1.00, 30,TRUE, 5.00),
  ('Business Prepaid', 'Prepaid', 49.90, 0.00, 50, 500, 500, 0.04, 0.02, 1.00, 30, TRUE, 4.00),
  ('Unlimited Postpaid', 'Postpaid', 79.90, 0.00, 100, 1500, 1500,  0.00, 0.00, 0.00, 30, TRUE, 6.00),
  ('Family Plan', 'Postpaid', 59.90, 0.00, 50, 5000, 5000, 0.02, 0.01, 1.00, 30, TRUE, 5.00);

-- Phone Numbers --
INSERT INTO PhoneNumber (e164_number, number_type, status_number , activation_date , deactivation_date , porting_requested)
VALUES
('+491511230001','Mobile','Assigned','2020-01-30',NULL,TRUE),
('+491511230002','VoIP','Deactivated','2020-01-30','2021-02-14',FALSE),
('+491511230003','Landline','Assigned','2020-06-20',NULL,FALSE),
('+491511230004','Fax','Deactivated','2020-06-20','2021-07-01',TRUE),
('+491511230005','Mobile','Assigned','2021-04-04',NULL,FALSE),
('+491511230006','VoIP','Deactivated','2021-04-04','2022-04-20',FALSE),
('+491511230007','Landline','Assigned','2021-09-25',NULL,TRUE),
('+491511230008','Fax','Deactivated','2021-09-25','2022-10-01',FALSE),
('+491511230009','Mobile','Assigned','2022-02-16',NULL,FALSE),
('+491511230010','VoIP','Deactivated','2022-02-16','2023-03-01',TRUE),
('+491511230011','Landline','Assigned','2022-08-02',NULL,FALSE),
('+491511230012','Fax','Deactivated','2022-08-02','2023-09-15',FALSE),
('+491511230013','Mobile','Assigned','2023-05-07',NULL,TRUE),
('+491511230014','VoIP','Deactivated','2023-05-07','2024-05-20',FALSE),
('+491511230015','Landline','Assigned','2023-12-15',NULL,FALSE),
('+491511230016','Fax','Deactivated','2023-12-15','2025-01-01',TRUE),
('+491511230017','Mobile','Assigned','2024-05-24',NULL,FALSE),
('+491511230018','VoIP','Assigned','2024-05-24',NULL,TRUE),
('+491511230019','Landline','Assigned','2024-12-27',NULL,FALSE),
('+491511230020','Fax','Assigned','2024-12-27',NULL,FALSE),
('+491511230021','Mobile','Assigned','2025-01-23',NULL,TRUE),
('+491511230022','VoIP','Assigned','2025-01-23',NULL,FALSE),
('+491511230023','Landline','Assigned','2025-04-09',NULL,FALSE),
('+491511230024','Fax','Assigned','2025-04-09',NULL,TRUE),
('+491511230025','Mobile','Assigned','2025-05-16',NULL,FALSE),
('+491511230026','VoIP','Assigned','2025-05-16',NULL,FALSE),
('+491511230027','Landline','Assigned','2025-05-31',NULL,TRUE),
('+491511230028','Fax','Assigned','2025-05-31',NULL,FALSE),
('+491511230029','Mobile','Assigned','2025-06-04',NULL,FALSE),
('+491511230030','VoIP','Assigned','2025-06-04',NULL,TRUE);

-- Fake SIM Cards 
INSERT INTO SIMCard (iccid, imsi, status_sim, issue_date, activation_date, block_date, phone_number_id)
VALUES
('893120000000000001','2620150000000001','Active','2020-01-15','2020-01-30',NULL,1),
('893120000000000002','2620150000000002','Blocked','2020-01-15','2020-01-30','2021-02-14',2),
('893120000000000003','2620150000000003','Active','2020-06-05','2020-06-20',NULL,3),
('893120000000000004','2620150000000004','Blocked','2020-06-05','2020-06-20','2021-07-01',4),
('893120000000000005','2620150000000005','Active','2021-03-20','2021-04-04',NULL,5),
('893120000000000006','2620150000000006','Blocked','2021-03-20','2021-04-04','2022-04-20',6),
('893120000000000007','2620150000000007','Active','2021-09-10','2021-09-25',NULL,7),
('893120000000000008','2620150000000008','Blocked','2021-09-10','2021-09-25','2022-10-01',8),
('893120000000000009','2620150000000009','Active','2022-02-01','2022-02-16',NULL,9),
('893120000000000010','2620150000000010','Blocked','2022-02-01','2022-02-16','2023-03-01',10),
('893120000000000011','2620150000000011','Active','2022-07-18','2022-08-02',NULL,11),
('893120000000000012','2620150000000012','Blocked','2022-07-18','2022-08-02','2023-09-15',12),
('893120000000000013','2620150000000013','Active','2023-04-22','2023-05-07',NULL,13),
('893120000000000014','2620150000000014','Blocked','2023-04-22','2023-05-07','2024-05-20',14),
('893120000000000015','2620150000000015','Active','2023-11-30','2023-12-15',NULL,15),
('893120000000000016','2620150000000016','Blocked','2023-11-30','2023-12-15','2025-01-01',16),
('893120000000000017','2620150000000017','Active','2024-05-09','2024-05-24',NULL,17),
('893120000000000018','2620150000000018','Active','2024-05-09','2024-05-24',NULL,18),
('893120000000000019','2620150000000019','Active','2024-12-12','2024-12-27',NULL,19),
('893120000000000020','2620150000000020','Active','2024-12-12','2024-12-27',NULL,20),
('893120000000000021','2620150000000021','Active','2025-01-08','2025-01-23',NULL,21),
('893120000000000022','2620150000000022','Active','2025-01-08','2025-01-23',NULL,22),
('893120000000000023','2620150000000023','Active','2025-03-25','2025-04-09',NULL,23),
('893120000000000024','2620150000000024','Active','2025-03-25','2025-04-09',NULL,24),
('893120000000000025','2620150000000025','Active','2025-05-01','2025-05-16',NULL,25),
('893120000000000026','2620150000000026','Active','2025-05-01','2025-05-16',NULL,26),
('893120000000000027','2620150000000027','Active','2025-05-15','2025-05-31',NULL,27),
('893120000000000028','2620150000000028','Active','2025-05-15','2025-05-31',NULL,28),
('893120000000000029','2620150000000029','Active','2025-05-20','2025-06-04',NULL,29),
('893120000000000030','2620150000000030','Active','2025-05-20','2025-06-04',NULL,30);


-- Subscriptions
INSERT INTO Subscription (account_id, plan_id, sim_card_id, phone_number_id , subscription_status, activation_date, 
			deactivation_date, last_billed_date, next_billing_date)
VALUES
(1,1,1,1,'Active','2020-01-30',NULL,'2020-03-01','2020-03-31'),
(2,2,2,2,'Suspended','2020-01-30','2021-02-14','2021-01-31',NULL),
(3,3,3,3,'Active','2020-06-20',NULL,'2020-07-20','2020-08-19'),
(4,4,4,4,'Suspended','2020-06-20','2021-07-01','2021-06-17',NULL),
(5,5,5,5,'Active','2021-04-04',NULL,'2021-05-04','2021-06-03'),
(6,6,6,6,'Suspended','2021-04-04','2022-04-20','2022-04-06',NULL),
(7,7,7,7,'Active','2021-09-25',NULL,'2021-10-25','2021-11-24'),
(8,8,8,8,'Suspended','2021-09-25','2022-10-01','2022-09-17',NULL),
(9,9,9,9,'Active','2022-02-16',NULL,'2022-03-18','2022-04-17'),
(10,10,10,10,'Suspended','2022-02-16','2023-03-01','2023-02-15',NULL),
(11,1,11,11,'Active','2022-08-02',NULL,'2022-09-01','2022-10-01'),
(12,2,12,12,'Suspended','2022-08-02','2023-09-15','2023-09-01',NULL),
(13,3,13,13,'Active','2023-05-07',NULL,'2023-06-06','2023-07-06'),
(14,4,14,14,'Suspended','2023-05-07','2024-05-20','2024-05-06',NULL),
(15,5,15,15,'Active','2023-12-15',NULL,'2024-01-14','2024-02-13'),
(16,6,16,16,'Suspended','2023-12-15','2025-01-01','2024-12-18',NULL),
(17,7,17,17,'Active','2024-05-24',NULL,'2024-06-23','2024-07-23'),
(18,8,18,18,'Active','2024-05-24',NULL,'2024-06-23','2024-07-23'),
(19,9,19,19,'Active','2024-12-27',NULL,'2025-01-26','2025-02-25'),
(20,10,20,20,'Active','2024-12-27',NULL,'2025-01-26','2025-02-25'),
(21,1,21,21,'Active','2025-01-23',NULL,'2025-02-22','2025-03-24'),
(22,2,22,22,'Active','2025-01-23',NULL,'2025-02-22','2025-03-24'),
(23,3,23,23,'Active','2025-04-09',NULL,'2025-05-09','2025-06-08'),
(24,4,24,24,'Active','2025-04-09',NULL,'2025-05-09','2025-06-08'),
(25,5,25,25,'Active','2025-05-16',NULL,'2025-06-15','2025-07-15'),
(26,6,26,26,'Active','2025-05-16',NULL,'2025-06-15','2025-07-15'),
(27,7,27,27,'Active','2025-05-31',NULL,'2025-06-30','2025-07-30'),
(28,8,28,28,'Active','2025-05-31',NULL,'2025-06-30','2025-07-30'),
(29,9,29,29,'Active','2025-06-04',NULL,'2025-07-04','2025-08-03'),
(30,10,30,30,'Active','2025-06-04',NULL,'2025-07-04','2025-08-03');

-- CallDetailRecord
-- =============================
INSERT INTO CallDetailRecord (subscription_id, phone_number_called, call_start_time, call_end_time, 
       duration_seconds, call_type, call_direction, billing_cycle_month, total_charge) 
VALUES
(1,'+491511230001','2020-02-15 09:15:00','2020-02-15 09:25:30',630,'Voice','Outgoing',2020-02-01,1.05),
(2,'+491511230002','2020-02-20 14:00:00','2020-02-20 14:05:00',300,'Voice','Incoming',2020-02-01,0.50),
(3,'+491511230003','2020-07-01 18:30:00','2020-07-01 18:45:00',900,'InternationalVoice','Outgoing',2020-07-01,4.50),
(4,'+491511230004','2021-05-10 12:00:00','2021-05-10 12:00:30',30,'Emergency','Outgoing',2020-07-01,0.00),
(5,'+491511230005','2021-05-11 09:20:00','2021-05-11 09:50:00',1800,'Voice','Outgoing',2021-05-01,0.90),
(6,'+491511230006','2021-10-01 07:00:00','2021-10-01 07:10:00',600,'RoamingVoice','Incoming',2021-05-01,3.00),
(7,'+491511230007','2022-03-05 16:45:00','2022-03-05 17:00:00',900,'Voice','Missed',2021-10-01,0.00),
(8,'+491511230008','2022-03-06 19:00:00','2022-03-06 19:05:00',300,'InternationalVoice','Outgoing',2021-10-01,2.25),
(9,'+491511230009','2023-06-01 08:15:00','2023-06-01 08:17:00',120,'Voice','Incoming',2022-03-01,0.24),
(10,'+491511230010','2023-06-02 22:00:00','2023-06-02 22:30:00',1800,'Voice','Outgoing',2022-03-01,1.80),
(11,'+491511230011','2024-02-14 14:30:00','2024-02-14 14:45:00',900,'RoamingVoice','Outgoing',2022-09-01,4.50),
(12,'+491511230012','2024-02-15 15:00:00','2024-02-15 15:02:00',120,'Emergency','Incoming',2022-09-01,0.00),
(13,'+491511230013','2025-05-05 10:00:00','2025-05-05 10:10:00',600,'Voice','Outgoing',2023-06-01,0.60),
(14,'+491511230014','2025-05-06 11:00:00','2025-05-06 11:06:00',360,'InternationalVoice','Incoming',2023-06-01,2.16),
(15,'+491511230015','2025-06-01 12:00:00','2025-06-01 12:01:00',60,'Voice','Missed',2024-01-01,0.00);

-- SMSRecord
INSERT INTO SMSRecord (subscription_id, phone_number_to, phone_number_from, message_timestamp, sms_type, billing_cycle_month, total_charge) 
VALUES
(1,'+491521000001','+491511230001','2020-02-10 08:30:00','SMS',2020-02-01,0.09),
(2,'+491521000002','+491511230002','2020-02-15 12:45:00','InternationalSMS',2020-02-01,0.25),
(3,'+491521000003','+491511230003','2020-07-02 14:20:00','SMS',2020-07-01,0.05),
(4,'+491521000004','+491511230004','2021-05-11 09:00:00','Mms',2020-07-01,0.20),
(5,'+491521000005','+491511230005','2021-05-15 16:30:00','SMS',2021-05-01,0.08),
(6,'+491521000006','+491511230006','2021-10-02 07:15:00','RoamingSMS',2021-05-01,0.30),
(7,'+491521000007','+491511230007','2022-03-07 18:00:00','SMS',2021-10-01,0.05),
(8,'+491521000008','+491511230008','2022-03-08 19:10:00','InternationalSMS',2021-10-01,0.22),
(9,'+491521000009','+491511230009','2023-06-05 08:45:00','SMS',2022-03-01,0.07),
(10,'+491521000010','+491511230010','2023-06-06 22:15:00','Mms',2022-03-01,0.18),
(11,'+491521000011','+491511230011','2024-02-15 14:40:00','RoamingSMS',2022-09-01,0.29),
(12,'+491521000012','+491511230012','2024-02-16 15:05:00','SMS',2022-09-01,0.06),
(13,'+491521000013','+491511230013','2025-05-06 10:20:00','SMS',2023-06-01,0.09),
(14,'+491521000014','+491511230014','2025-05-07 11:15:00','InternationalSMS',2023-06-01,0.24),
(15,'+491521000015','+491511230015','2025-06-02 12:30:00','SMS',2024-01-01,0.05);

-- DataUsageRecord
-- =============================
INSERT INTO DataUsageRecord (subscription_id, session_start, session_end, bytes_downloaded, bytes_uploaded, billing_cycle_month, total_charge)
 VALUES
(1,'2020-02-10 10:00:00','2020-02-10 10:10:00',10485760,2097152,2020-02-01,0.10),
(2,'2020-02-18 14:05:00','2020-02-18 14:20:00',2048000,512000,2020-02-01,0.04),
(3,'2020-07-02 18:35:00','2020-07-02 18:55:00',52428800,10485760,2020-07-01,0.60),
(4,'2021-05-10 12:05:00','2021-05-10 12:15:00',1048576,524288,2020-07-01,0.02),
(5,'2021-05-11 09:25:00','2021-05-11 09:55:00',20971520,5242880,2021-05-01,0.36),
(6,'2021-10-01 07:05:00','2021-10-01 07:25:00',31457280,10485760,2021-05-01,0.80),
(7,'2022-03-05 16:50:00','2022-03-05 17:10:00',15728640,3145728,2021-10-01,0.30),
(8,'2022-03-06 19:02:00','2022-03-06 19:22:00',47185920,7340032,2021-10-01,1.50),
(9,'2023-06-01 08:16:00','2023-06-01 08:26:00',1048576,262144,2022-03-01,0.05),
(10,'2023-06-02 22:05:00','2023-06-02 22:25:00',31457280,5242880,2022-03-01,0.90),
(11,'2024-02-14 14:35:00','2024-02-14 14:55:00',8388608,2097152,2022-09-01,0.25),
(12,'2024-02-15 15:02:00','2024-02-15 15:12:00',4194304,1048576,2022-09-01,0.12),
(13,'2025-05-05 10:02:00','2025-05-05 10:12:00',10485760,1048576,2023-06-01,0.15),
(14,'2025-05-06 11:02:00','2025-05-06 11:22:00',20971520,2097152,2023-06-01,0.30),
(15,'2025-06-01 12:02:00','2025-06-01 12:12:00',524288,131072,2024-01-01,0.01);

-- UsageSummary
-- =============================
INSERT INTO UsageSummary (subscription_id, billing_cycle_month, total_voice_minutes, total_sms_count, total_data_mb, total_voice_charges,
       total_sms_charges, total_data_charges, generated_at) 
VALUES
(1,2020-02-01,11,1,10,1.05,0.09,0.10,'2020-03-01'),
(2,2020-02-01,5,1,2,0.50,0.25,0.04,'2020-03-01'),
(3,2020-07-01,15,1,50,4.50,0.05,0.60,'2020-08-01'),
(4,2020-07-01,0,1,1,0.00,0.20,0.02,'2021-06-01'),
(5,2021-05-01,30,1,20,0.90,0.08,0.36,'2021-06-01'),
(6,2021-05-01,10,1,30,3.00,0.30,0.80,'2021-11-01'),
(7,2021-10-01,15,1,15,0.00,0.05,0.30,'2022-04-01'),
(8,2021-10-01,5,1,45,2.25,0.22,1.50,'2022-04-01'),
(9,2022-03-01,2,1,1,0.24,0.07,0.05,'2023-07-01'),
(10,2022-03-01,30,1,30,1.80,0.18,0.90,'2023-07-01'),
(11,2022-09-01,15,1,8,4.50,0.29,0.25,'2024-03-01'),
(12,2022-09-01,2,1,4,0.00,0.06,0.12,'2024-03-01'),
(13,2023-06-01,10,1,10,0.60,0.09,0.15,'2025-06-01'),
(14,2023-06-01,6,1,20,2.16,0.24,0.30,'2025-06-01'),
(15,2024-01-01,1,1,1,0.00,0.05,0.00,'2025-07-01');
 
-- Invoices
-- =============================
INSERT INTO Invoice (account_id, billing_cycle_start, billing_cycle_end, invoice_date, due_date, total_amount, status_invoice, previous_balance,
  payments_applied, new_balance) 
VALUES
(1, '2020-02-01', '2020-02-28', '2020-03-01', '2020-03-15', 50.00, 'Paid',    0.00, 50.00, 0.00),
(2, '2020-02-01', '2020-02-28', '2020-03-01', '2020-03-15', 75.00, 'Overdue', 10.00, 65.00, 10.00),
(3, '2020-07-01', '2020-07-30', '2020-08-01', '2020-08-15', 120.50, 'Pending', 0.00, 0.00, 120.50),
(4, '2020-07-01', '2020-07-30', '2020-08-01', '2020-08-15', 95.25, 'Cancelled', 5.00, 100.25, -5.00),
(5, '2021-05-01', '2021-05-30', '2021-06-01', '2021-06-15', 150.00, 'Paid',    20.00, 170.00, 0.00),
(6, '2021-05-01', '2021-05-30', '2021-06-01', '2021-06-15', 180.75, 'Paid',    0.00, 180.75, 0.00),
(7, '2021-10-01', '2021-10-30', '2021-11-01', '2021-11-15', 200.00, 'Pending', 0.00, 0.00, 200.00),
(8, '2021-10-01', '2021-10-30', '2021-11-01', '2021-11-15', 210.30, 'Overdue', 30.00, 180.30, 30.00),
(9, '2022-03-01', '2022-03-28', '2022-04-01', '2022-04-15', 95.00, 'Paid',    0.00, 95.00, 0.00),
(10,'2022-03-01', '2022-03-28', '2022-04-01', '2022-04-15', 110.00, 'Paid',    10.00, 120.00, 0.00),
(11,'2022-09-01', '2022-09-30', '2022-10-01', '2022-10-15', 130.00, 'Pending', 0.00, 0.00, 130.00),
(12,'2022-09-01', '2022-09-30', '2022-10-01', '2022-10-15', 140.50, 'Overdue', 20.00, 120.50, 20.00),
(13,'2023-06-01', '2023-06-30', '2023-07-01', '2023-07-15', 160.00, 'Paid',    0.00, 160.00, 0.00),
(14,'2023-06-01', '2023-06-30', '2023-07-01', '2023-07-15', 170.75, 'Cancelled', 30.00, 200.75, -30.00),
(15,'2024-01-01', '2024-01-31', '2024-02-01', '2024-02-15', 180.00, 'Paid',    0.00, 180.00, 0.00),
(16,'2024-01-01', '2024-01-31', '2024-02-01', '2024-02-15', 190.25, 'Pending', 0.00, 0.00, 190.25),
(17,'2024-05-01', '2024-05-31', '2024-06-01', '2024-06-15', 200.00, 'Paid',    0.00, 200.00, 0.00),
(18,'2024-05-01', '2024-05-31', '2024-06-01', '2024-06-15', 210.60, 'Overdue', 25.00, 185.60, 25.00),
(19,'2024-12-01', '2024-12-31', '2025-01-01', '2025-01-15', 220.00, 'Pending', 0.00, 0.00, 220.00),
(20,'2024-12-01', '2024-12-31', '2025-01-01', '2025-01-15', 230.80, 'Paid',    0.00, 230.80, 0.00);

-- InvoiceItem
-- =============================
INSERT INTO InvoiceItem (invoice_id, item_type, quantity, unit_price, total_price, created_at) 
VALUES
(1,'SubscriptionFee',1,29.99,29.99,'2020-03-02'),
(2,'VoiceUsage',11,0.095,1.045,'2020-03-02'),
(3,'SubscriptionFee',1,19.99,19.99,'2020-04-02'),
(4,'SMSUsage',1,0.25,0.25,'2020-04-02'),
(5,'SubscriptionFee',1,34.99,34.99,'2020-08-05'),
(5,'DataUsage',50,0.012,0.60,'2020-08-05'),
(6,'SubscriptionFee',1,24.99,24.99,'2021-06-02'),
(7,'Roaming',1,0.20,0.20,'2021-06-02'),
(8,'SubscriptionFee',1,39.99,39.99,'2021-07-05'),
(9,'OneTimeCharge',1,10.00,10.00,'2021-07-05'),
(10,'SubscriptionFee',1,29.99,29.99,'2021-11-02'),
(11,'VoiceUsage',30,0.10,3.00,'2021-11-02'),
(12,'SubscriptionFee',1,29.99,29.99,'2022-04-03'),
(13,'SMSUsage',1,0.05,0.05,'2022-04-03'),
(14, 'SubscriptionFee',1,19.99,19.99,'2022-04-03'),
(14,'DataUsage',45,0.033,1.485,'2022-04-03'),
(15,'SubscriptionFee',1, 9.99,19.98,'2022-09-03'),
(16,'SubscriptionFee',1,24.99,24.99,'2023-07-02'),
(17,'VoiceUsage',2,0.12,0.24,'2023-07-02'),
(18,'Roaming',2,0.20,0.40,'2023-06-07'),
(19,'SubscriptionFee',1,34.99,34.99,'2023-07-02'),
(20,'DataUsage',30,0.03,0.90,'2023-07-02');

-- Payments
-- =============================
INSERT INTO Payment (invoice_id, account_id, payment_date, amount_paid, payment_method, transaction_reference, status_payment) 
VALUES
(1,  1, '2020-03-10',  50.00, 'SEPA',       'SEPA20200210-0001', 'Cleared'),
(2,  2, '2020-03-18',  65.00, 'CreditCard', 'CC20200218-0002',   'Cleared'),
(3,  3, '2020-08-10', 120.50, 'DirectDebit','DD20200710-0003',  'Failed'),
(4,  4, '2021-08-10',   5.00, 'Cash',       'CASH20210710-0004', 'Refunded'),
(5,  5, '2021-06-10', 170.00, 'Voucher',    'VCHR20210510-0005', 'Cleared'),
(6,  6, '2021-06-10', 180.75, 'CreditCard', 'CC20210510-0006',   'Received'),
(7,  7, '2021-11-05', 200.00, 'DirectDebit','DD20211005-0007',  'Failed'),
(8,  8, '2021-11-10', 180.30, 'SEPA',       'SEPA20211010-0008', 'Cleared'),
(9,  9, '2022-04-05',  95.00, 'PayPal',     'PP20220305-0009',   'Cleared'),
(10,10, '2022-04-10', 120.00, 'SEPA',       'SEPA20220310-0010', 'Cleared'),
(11,11, '2022-10-05',   0.00, 'Cash',       'CASH20220905-0011', 'Failed'),
(12,12, '2022-10-10', 120.50, 'CreditCard', 'CC20220910-0012',   'Cleared'),
(13,13, '2023-07-05', 160.00, 'SEPA',       'SEPA20230605-0013', 'Received'),
(14,14, '2023-07-10',  30.00, 'PayPal',     'PP20230610-0014',   'Refunded'),
(15,15, '2024-02-05', 180.00, 'Cash',       'CASH20240105-0015', 'Cleared'),
(16,16, '2024-02-10',   0.00, 'DirectDebit','DD20240110-0016',  'Failed'),
(17,17, '2024-06-05', 200.00, 'SEPA',       'SEPA20240605-0017', 'Received'),
(18,18, '2024-06-10', 185.60, 'Voucher',    'VCHR20240610-0018', 'Cleared'),
(19,19, '2025-01-05',   0.00, 'CreditCard', 'CC20250105-0019',   'Failed'),
(20,20, '2025-01-10', 230.80, 'PayPal',     'PP20250110-0020',   'Cleared');

-- AccountTransaction
-- =============================
INSERT INTO AccountTransaction (account_id, invoice_id, txn_datetime, txn_type, amount, currency, balance_after_txn) 
VALUES
(1, 1, '2020-03-10 08:00:00', 'InvoicePost',   50.00, 'EUR',  0.00),
(2, 2, '2020-03-18 14:00:00', 'Payment',       65.00, 'EUR',   5.00),
(5, 5, '2021-06-10 09:00:00', 'AdjustmentCr',   170.00, 'EUR',  0.00),
(6, 6, '2021-06-10 16:00:00', 'Payment',   180.75, 'EUR', 0.00),
(8, 8, '2021-11-10 10:30:00', 'InvoicePost',       180.30, 'EUR',  30.00),
(17, 17, '2024-05-22 11:00:00', 'InvoicePost',  200.00, 'EUR',  0.00),
(20, 20, '2024-12-14 08:30:00', 'Payment',  230.80, 'EUR', 0.00),
(19, 19, '2024-12-26 09:00:00', 'AdjustmentDr', 0.00, 'EUR',  134.75);


 -- NetworkElement
-- =============================
INSERT INTO NetworkElement (element_type, element_name, ip_address, location_lat, location_long, vendor, installation_date, status_element) 
VALUES
('BTS',        'BTS-Berlin-01',      '192.168.100.1', 52.5200, 13.4050, 'Ericsson', '2018-05-12', 'Operational'),
('eNodeB',     'eNodeB-Hamburg-02',  '192.168.100.2', 53.5511,  9.9937, 'Nokia',     '2019-07-24', 'Maintenance'),
('CoreRouter', 'CR-Munich-01',       '10.0.0.1',      48.1351, 11.5820, 'Cisco',     '2017-03-15', 'Operational'),
('GGSN',       'GGSN-Frankfurt-01',  '10.0.1.1',      50.1109,  8.6821, 'Huawei',    '2020-01-10', 'Operational'),
('IMS',        'IMS-Cologne-01',     '10.0.2.1',      50.9375,  6.9603, 'Oracle',    '2021-11-05', 'Planned'),
('MSC',        'MSC-Stuttgart-01',   '192.168.101.1', 48.7758,  9.1829, 'Ericsson', '2016-04-20', 'Operational'),
('SGSN',       'SGSN-Bremen-01',     '192.168.101.2', 53.0793,  8.8017, 'Ericsson', '2015-12-01', 'Operational'),
('HSS',        'HSS-Leipzig-01',     '192.168.101.3', 51.3397, 12.3731, 'Huawei',    '2018-09-15', 'Operational'),
('PCRF',       'PCRF-Dresden-01',    '192.168.101.4', 51.0504, 13.7373, 'Nokia',     '2019-02-10', 'Operational'),
('NodeB',      'NodeB-Kiel-01',      '192.168.101.5', 54.3233, 10.1228, 'Ericsson', '2017-06-30', 'Operational'),
('gNodeB',     'gNodeB-Leverkusen-01','192.168.101.6',51.0305,  6.9849, 'Nokia',     '2022-08-01', 'Maintenance'),
('OLT',        'OLT-Hanover-01',     '192.168.101.7', 52.3759,  9.7320, 'Cisco',     '2014-11-11', 'Planned'),
('Aggregator', 'Aggregator-Dortmund-01','192.168.101.8',51.5136,7.4653,'Juniper', '2013-07-07', 'Operational'),
('HSS',        'HSS-Bonn-01',        '192.168.101.9', 50.7374,  7.0982, 'Huawei',    '2019-10-20', 'Planned'),
('SGSN',       'SGSN-Wolfsburg-01',  '192.168.101.10',52.4235,10.7865,'Ericsson', '2020-05-05', 'Operational'),
('NodeB',      'NodeB-Nuremberg-01', '192.168.101.11',49.4521,11.0767,'Nokia',     '2018-01-01', 'Operational'),
('MSC',        'MSC-Kaiserslautern-01','192.168.101.12',49.4400,7.7499,'Cisco',   '2016-03-03', 'Operational'),
('IMS',        'IMS-Krefeld-01',     '192.168.101.13',51.3388,6.5853, 'Oracle',    '2021-07-07', 'Maintenance'),
('PCRF',       'PCRF-Munich-02',     '192.168.101.14',48.1351,11.5820,'Nokia',     '2023-02-14', 'Operational'),
('GGSN',       'GGSN-Augsburg-01',   '192.168.101.15',48.3665,10.8978,'Huawei',    '2022-03-22', 'Planned');


-- CellSite
INSERT INTO CellSite (network_element_id, site_code, location, bandwidth, technology, height) 
VALUES
(1,'CS-BER-1','Berlin','900MHz','4G',25.5),
(2,'CS-HAM-1','Hamburg','1800MHz','3G',30.0),
(3,'CS-MUC-1','Munich','3500MHz','5G',28.0),
(4,'CS-FRA-1','Frankfurt','900MHz','4G',27.5),
(5,'CS-COL-1','Cologne','1800MHz','4G',26.0),
(6,'CS-STU-1','Stuttgart','3500MHz','5G',29.5),
(7,'CS-BRE-1','Bremen','900MHz','2G',24.0),
(8,'CS-LEI-1','Leipzig','1800MHz','3G',22.5),
(9,'CS-DRE-1','Dresden','3500MHz','5G',23.0),
(10,'CS-KIE-1','Kiel','900MHz','4G',21.5);

-- Employee --
SET FOREIGN_KEY_CHECKS = 0;
INSERT INTO Employee (first_name, last_name, designation, email, phone_number, hired_date, terminated_date, is_active, manager_id) 
VALUES
('Anna','Schneider','Manager','anna.schneider@telecom.de','0301234001','2018-02-15',NULL,TRUE,NULL),
('Bernd','Fischer','NetworkEngineer','bernd.fischer@telecom.de','0402345002','2018-06-20',NULL,TRUE,1),
('Claudia','Meier','BillingClerk','claudia.meier@telecom.de','0893456003','2020-01-10',NULL,TRUE,1),
('Dirk','Wagner','Technician','dirk.wagner@telecom.de','0694567004','2017-09-05',NULL,TRUE,2),
('Eva','Becker','SupportAgent','eva.becker@telecom.de','0223456005','2016-11-30','2022-12-31',FALSE,NULL),
('Fabian','Hoffmann','NetworkEngineer','fabian.hoffmann@telecom.de','0305678006','2021-04-18',NULL,TRUE,1),
('Gisela','Schulz','SupportAgent','gisela.schulz@telecom.de','0406789007','2022-08-02',NULL,TRUE,3),
('Heiko','Klein','Technician','heiko.klein@telecom.de','0897890018','2019-12-12',NULL,TRUE,4),
('Ines','Wolf','BillingClerk','ines.wolf@telecom.de','0698900129','2020-07-07',NULL,TRUE,1),
('Joachim','Neumann','Manager','joachim.neumann@telecom.de','0229012345','2015-03-25','2021-05-15',FALSE,NULL),
('Klara','Richter','SupportAgent','klara.richter@telecom.de','0300123456','2023-01-20',NULL,TRUE,7),
('Lars','Schmidt','Technician','lars.schmidt@telecom.de','0401234567','2022-03-14',NULL,TRUE,4),
('Monika','Lorenz','BillingClerk','monika.lorenz@telecom.de','0892345678','2018-10-01',NULL,TRUE,3),
('Nils','Köhler','NetworkEngineer','nils.koehler@telecom.de','0693456789','2017-01-11',NULL,TRUE,19),
('Olga','Friedrich','SupportAgent','olga.friedrich@telecom.de','0224567890','2021-09-09',NULL,TRUE,1),
('Patrick','Hartmann','Technician','patrick.hartmann@telecom.de','0305678901','2019-05-27',NULL,TRUE,4),
('Quirin','Mayer','NetworkEngineer','quirin.mayer@telecom.de','0406789012','2020-11-17',NULL,TRUE,2),
('Ruth','Fuchs','BillingClerk','ruth.fuchs@telecom.de','0897890123','2016-08-23',NULL,TRUE,19),
('Stefan','Krause','Manager','stefan.krause@telecom.de','0698901234','2014-02-18',NULL,TRUE,NULL),
('Tanja','Beck','SupportAgent','tanja.beck@telecom.de','0229012346','2023-06-01',NULL,TRUE,7);
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO MaintenanceSchedule (network_element_id, maintenance_start, maintenance_end, maintenance_type, engineer_id, status_maintenance) 
VALUES
(1,'2023-06-01 00:00:00','2023-06-01 04:00:00','Planned',2,'Completed'),
(2,'2023-07-05 12:00:00','2023-07-05 16:00:00','Emergency',4,'Completed'),
(3,'2023-08-10 22:00:00','2023-08-11 06:00:00','Upgrade',8,'InProgress'),
(4,'2023-09-15 01:00:00','2023-09-15 05:00:00','Planned',14,'Scheduled'),
(5,'2023-10-20 02:00:00','2023-10-20 06:00:00','Emergency',16,'Completed'),
(6,'2023-11-25 03:00:00','2023-11-25 07:00:00','Upgrade',6,'Scheduled'),
(7,'2024-01-10 22:30:00','2024-01-11 02:30:00','Planned',17,'Scheduled'),
(8,'2024-02-14 23:00:00','2024-02-15 03:00:00','Upgrade',8,'InProgress'),
(9,'2024-03-18 00:00:00','2024-03-18 04:00:00','Emergency',12,'Completed'),
(10,'2024-04-22 04:00:00','2024-04-22 08:00:00','Planned',2,'Scheduled'),
(11,'2024-05-30 01:00:00','2024-05-30 05:00:00','Upgrade',12,'Completed'),
(12,'2024-06-15 02:00:00','2024-06-15 06:00:00','Emergency',14,'Completed'),
(13,'2024-07-20 03:00:00','2024-07-20 07:00:00','Planned',4,'Scheduled'),
(14,'2024-08-25 00:30:00','2024-08-25 04:30:00','Upgrade',16,'InProgress'),
(15,'2024-09-30 01:00:00','2024-09-30 05:00:00','Emergency',12,'Completed'),
(16,'2024-10-05 02:30:00','2024-10-05 06:30:00','Planned',17,'Scheduled'),
(17,'2024-11-10 03:00:00','2024-11-10 07:00:00','Upgrade',16,'Completed'),
(18,'2024-12-15 04:00:00','2024-12-15 08:00:00','Emergency',2,'InProgress'),
(19,'2025-01-20 05:00:00','2025-01-20 09:00:00','Planned',6,'Scheduled'),
(20,'2025-02-25 06:00:00','2025-02-25 10:00:00','Upgrade',4,'Scheduled');


-- SupportTicket
INSERT INTO SupportTicket (customer_id, subscription_id, opened_date, closed_date, ticket_status, priority, issue_category, issue_description, assigned_to) VALUES
(1,1,'2023-06-05 09:15:00',NULL,'Open','High','Network','Intermittent signal loss in area',15),
(2,2,'2023-06-07 14:30:00','2023-06-08 10:00:00','Resolved','High','Billing','Incorrect invoice amount',7),
(3,3,'2023-07-01 08:00:00',NULL,'Assigned','Medium','Provisioning','New SIM activation issue',11),
(4,4,'2023-07-02 12:45:00','2023-07-03 09:10:00','Reopened','High','Device','Device network settings not applied',15),
(5,5,'2023-08-10 16:20:00',NULL,'Escalated','High','Software','My app crashes frequently',20),
(6,6,'2023-08-15 11:00:00','2023-08-16 17:30:00','Resolved','Medium','SIM','SIM card not recognized',7),
(7,7,'2023-09-01 13:50:00',NULL,'Open','Low','GeneralInquiry','How to change plan?',7),
(8,8,'2023-09-05 10:25:00','2023-09-06 15:00:00','Resolved','Low','Billing','Request copy of old bill',11),
(9,9,'2023-10-12 09:40:00',NULL,'Assigned','High','Network','Frequent call drops',15),
(10,10,'2023-10-20 17:00:00',NULL,'Open','Medium','Device','Cannot connect to 5G network',20),
(11,11,'2023-11-03 14:00:00','2023-11-04 11:45:00','Resolved','Low','Software','Feature request for mobile app',20),
(12,12,'2023-11-10 15:30:00',NULL,'Escalated','High','Billing','Overcharged for data roaming',7),
(13,13,'2023-12-01 08:00:00','2023-12-02 12:00:00','Resolved','Medium','SIM','Lost SIM replacement',11),
(14,14,'2024-01-15 09:10:00',NULL,'Open','Medium','Network','No service after network upgrade',15),
(15,15,'2024-02-20 10:00:00','2024-02-21 14:20:00','Resolved','Medium','Provisioning','Change of SIM profile',20),
(16,16,'2024-03-25 11:30:00',NULL,'Assigned','High','Device','Phone purchase payment not applied',11),
(17,17,'2024-04-05 13:00:00','2024-04-06 16:00:00','Reopened','Medium','Software','Account login issues',7),
(18,18,'2024-05-10 10:15:00',NULL,'Open','High','GeneralInquiry','Question about international roaming',11),
(19,19,'2024-06-01 09:45:00','2024-06-02 09:00:00','Resolved','Low','Billing','VAT rate query',15),
(20,20,'2024-07-07 08:20:00',NULL,'Assigned','Medium','Network','Slow internet speed',20);


-- ==============================================
-- Accounts Triggers to be registered in AuditLog
-- ==============================================
DELIMITER //
-- on insert --
CREATE TRIGGER accounts_insert AFTER INSERT ON Accounts
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, after_state)
VALUES('Accounts', CONCAT('account_id=', NEW.account_id), 'INSERT',
  JSON_OBJECT(
    'customer_id', NEW.customer_id,
    'account_number', NEW.account_number,
    'account_start_date', NEW.account_start_date,
    'credit_limit', NEW.credit_limit,
    'payment_term_days', NEW.payment_term_days )
);
END //
DELIMITER ;

DELIMITER //
-- on update --
CREATE TRIGGER accounts_update BEFORE UPDATE ON Accounts
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state, after_state)
VALUES('Accounts', CONCAT('account_id=', OLD.account_id), 'UPDATE',
  JSON_OBJECT(
    'account_status', OLD.account_status,
    'credit_limit', OLD.credit_limit,
    'payment_term_days', OLD.payment_term_days),
  JSON_OBJECT(
    'account_status', NEW.account_status,
    'credit_limit', NEW.credit_limit,
    'payment_term_days', NEW.payment_term_days)
);
END //
DELIMITER ;

DELIMITER //
-- on delete --
CREATE TRIGGER accounts_delete BEFORE DELETE ON Accounts
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state)
VALUES('Accounts', CONCAT('account_id=', OLD.account_id),'DELETE',
  JSON_OBJECT(
    'customer_id', OLD.customer_id,
    'account_number', OLD.account_number)
);
END //
DELIMITER ;

-- =============================================
-- Invoice Triggers to be registered in AuditLog
-- =============================================

DELIMITER //
-- on insert --
CREATE TRIGGER invoice_insert AFTER INSERT ON Invoice
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, after_state)
VALUES('Invoice', CONCAT('invoice_id=', NEW.invoice_id), 'INSERT',
JSON_OBJECT(
   'account_id', NEW.account_id,
   'total_amount', NEW.total_amount,
   'status_invoice', NEW.status_invoice )
);
END //
DELIMITER ;


DELIMITER //
-- on update --
CREATE TRIGGER invoice_update BEFORE UPDATE ON Invoice
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state, after_state)
VALUES('Invoice', CONCAT('invoice_id=', OLD.invoice_id), 'UPDATE',
JSON_OBJECT(
   'status_invoice', OLD.status_invoice,
   'new_balance', OLD.new_balance),
JSON_OBJECT(
   'status_invoice', NEW.status_invoice,
   'new_balance', NEW.new_balance)
);
END //
DELIMITER ;

DELIMITER //
-- on delete --
CREATE TRIGGER invoice_delete BEFORE DELETE ON Invoice
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state)
VALUES('Invoice', CONCAT('invoice_id=', OLD.invoice_id), 'DELETE',
JSON_OBJECT(
   'account_id', OLD.account_id,
   'total_amount', OLD.total_amount)
);
END //
DELIMITER ;


-- =============================================
-- Payment Triggers to be registered in AuditLog
-- =============================================

DELIMITER //
-- on insert --
CREATE TRIGGER payment_insert AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, after_state)
VALUES('Payment', CONCAT('payment_id=', NEW.payment_id), 'INSERT',
JSON_OBJECT(
   'invoice_id', NEW.invoice_id,
   'amount_paid', NEW.amount_paid,
   'status_payment', NEW.status_payment)
);
END //
DELIMITER ;

DELIMITER //
-- on update --
CREATE TRIGGER payment_update BEFORE UPDATE ON Payment
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state, after_state)
VALUES('Payment', CONCAT('payment_id=', OLD.payment_id), 'UPDATE',
JSON_OBJECT('status_payment', OLD.status_payment),
JSON_OBJECT('status_payment', NEW.status_payment)
);
END //
DELIMITER ;

DELIMITER //
-- on delete --
CREATE TRIGGER payment_delete BEFORE DELETE ON Payment
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state)
VALUES('Payment', CONCAT('payment_id=', OLD.payment_id), 'DELETE',
JSON_OBJECT(
    'invoice_id', OLD.invoice_id,
    'amount_paid', OLD.amount_paid)
);
END //
DELIMITER ;


-- ========================================================
-- AccountTransaction Triggers to be registered in AuditLog
-- ========================================================
DELIMITER //
-- on insert --
CREATE TRIGGER accountTransaction_insert AFTER INSERT ON AccountTransaction
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, after_state)
VALUES('AccountTransaction', CONCAT('txn_id=', NEW.txn_id), 'INSERT',
JSON_OBJECT(
   'account_id', NEW.account_id,
   'amount', NEW.amount,
   'txn_type', NEW.txn_type)
);
END //
DELIMITER ;

DELIMITER //
-- on delete --
CREATE TRIGGER accountTransaction_delete BEFORE DELETE ON AccountTransaction
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state)
VALUES('AccountTransaction', CONCAT('txn_id=', OLD.txn_id), 'DELETE',
 JSON_OBJECT(
    'account_id', OLD.account_id,
    'amount', OLD.amount)
);
END //
DELIMITER ;


-- ==========================================================
-- MaintenanceSchedule Triggers to be registered in AuditLog
-- ===========================================================

DELIMITER //
-- on insert --
CREATE TRIGGER maintenanceSchedule_insert AFTER INSERT ON MaintenanceSchedule
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, after_state)
VALUES('MaintenanceSchedule', CONCAT('maintenance_id=', NEW.maintenance_id), 'INSERT',
 JSON_OBJECT(
    'network_element_id', NEW.network_element_id,
    'maintenance_type', NEW.maintenance_type)
);
END //
DELIMITER ;

DELIMITER //
-- on update --
CREATE TRIGGER maintenanceSchedule_update BEFORE UPDATE ON MaintenanceSchedule
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state, after_state)
VALUES('MaintenanceSchedule', CONCAT('maintenance_id=', OLD.maintenance_id), 'UPDATE',
 JSON_OBJECT('status_maintenance', OLD.status_maintenance),
 JSON_OBJECT('status_maintenance', NEW.status_maintenance)
);
END //
DELIMITER ;

DELIMITER //
-- on delete --
CREATE TRIGGER maintenanceSchedule_delete BEFORE DELETE ON MaintenanceSchedule
FOR EACH ROW
BEGIN
INSERT INTO AuditLog(table_name, row_changed, operation, before_state)
VALUES('MaintenanceSchedule', CONCAT('maintenance_id=', OLD.maintenance_id), 'DELETE',
 JSON_OBJECT(
	'network_element_id', OLD.network_element_id,
    'maintenance_type', OLD.maintenance_type)
);
END //
DELIMITER ;



-- ========================================
-- Part 3: Sample Queries for Business Insights
-- ========================================
-- Q1: List all active customers
-- Insight: Identify current customer base and contact points
SELECT customer_id, first_name, last_name, email
  FROM Customer
  WHERE customer_id IN (
    SELECT DISTINCT customer_id
      FROM Accounts
      WHERE account_status = 'Active'
  );
  
 -- Q2: Show the billing & home addresses for customer #8
 -- Insight: Exact billing / home address for a customer, to Confirm legitimate billing location before shipping
 SELECT * FROM Address 
 WHERE customer_id = 8 
 ORDER BY address_type;
 
-- Q3: Count subscriptions per service plan
-- Insight: Measure plan popularity
SELECT sp.plan_name, COUNT(*) AS subscription_count
FROM Subscription s
JOIN ServicePlan sp ON s.plan_id = sp.plan_id
GROUP BY sp.plan_name;

-- Q4: Retrieve Top 5 subscriber with highest total call, sms and data charge combined
-- Insight: Identifying Customers with high extra usage outside subscription, to put forward suitable plans (marketing strategy)
SELECT subscription_id, (total_voice_charges + total_sms_charges + total_data_charges) AS total_combined_charge
FROM usagesummary
ORDER BY total_combined_charge DESC
LIMIT 5 ;

-- Q5: List payments received in last 30 days
-- Insight: Monitor recent cash flow
SELECT payment_id, account_id, amount_paid, payment_date
  FROM Payment
  WHERE payment_date >= CURDATE() - INTERVAL 30 DAY;
  
-- Q6: Payments received in June 2024
-- Insight: Validate revenue recognition; reconcile with bank deposits
SELECT payment_id, amount_paid, payment_method 
FROM Payment 
WHERE payment_date BETWEEN '2024-06-01' AND '2024-06-30';

-- Q7: Open support tickets ordered by priority
-- Insight: Allocate support resources; escalate high-priority issues to reduce churn risk
SELECT ticket_id, issue_category, priority 
FROM SupportTicket 
WHERE ticket_status = 'Open' 
ORDER BY priority DESC;

-- Q8: Detailed monthly bill for a given account (2024-05)
-- Insight: Resolve billing disputes; design clearer bill layouts; cross-sell add-ons
SELECT inv.invoice_id, it.item_type, it.quantity, it.total_price 
FROM Invoice AS inv 
JOIN InvoiceItem AS it ON it.invoice_id = inv.invoice_id 
WHERE inv.account_id = 17 AND inv.billing_cycle_start = '2024-05-01';

-- Q9: Identify high-value customers (average monthly spend > €100)
-- Insight: Target loyalty programs
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS name,
  AVG(inv.total_amount) AS avg_monthly_spend
FROM Invoice inv
JOIN Accounts a ON inv.account_id = a.account_id
JOIN Customer c ON a.customer_id = c.customer_id
GROUP BY c.customer_id
HAVING AVG(inv.total_amount) > 100;

-- Q10: Analyze peak call hours (hour with most calls in last month)
-- Insight: Network capacity planning
SELECT HOUR(call_start_time) AS hour_of_day, COUNT(*) AS call_count
FROM CallDetailRecord
WHERE call_start_time >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
GROUP BY hour_of_day
ORDER BY call_count DESC
LIMIT 1;

-- Q11: Rank network elements by number of maintenance events in past year
-- Insight: Identify unreliable hardware
SELECT ne.element_name, COUNT(ms.maintenance_id) AS events_count
FROM MaintenanceSchedule ms
JOIN NetworkElement ne ON ms.network_element_id = ne.network_element_id
WHERE ms.maintenance_start >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY ne.element_name
ORDER BY events_count DESC;

-- Q12: Highest Average ticket-resolution time per issue category
-- Insight: Identify training gaps; refine trainings for slow categories
SELECT issue_category, AVG((COALESCE(closed_date) - opened_date) ) AS avg_hours
FROM SupportTicket
GROUP BY issue_category
ORDER BY avg_hours desc
LIMIT 3 ;

-- Q13: Accounts at churn risk: suspended subs and overdue invoices
-- Insight: Launch customer retention campaigns; enforce stricter credit checks.
SELECT DISTINCT a.account_id 
FROM Accounts a 
JOIN Subscription s ON s.account_id = a.account_id 
JOIN Invoice i ON i.account_id = a.account_id 
WHERE s.subscription_status='Suspended' AND i.status_invoice='Overdue';

-- Q14: Find the manager who has the most direct reports
-- Insight: Identify employees with more responsibility
SELECT m.first_name, m.last_name, COUNT(e.id) AS num_reports
FROM  Employee m
JOIN Employee AS e ON e.manager_id = m.id
GROUP BY m.id, m.first_name, m.last_name
ORDER BY num_reports DESC
LIMIT 1;






-- ====================================================================
-- ACCOUNTS  ─ fires: accounts_insert, accounts_update, accounts_delete
-- =====================================================================
START TRANSACTION;
  -- INSERT → AFTER INSERT trigger
INSERT INTO Accounts
        (customer_id, account_number, account_status,
         account_start_date, credit_limit, payment_term_days, preferred_language)
VALUES (1,'ACC_TEST','Active',CURDATE(),250.00,30,'DE');

  -- UPDATE → BEFORE UPDATE trigger
UPDATE Accounts
SET account_status = 'Suspended', credit_limit   = 300.00
WHERE account_number = 'ACC_TEST';

SAVEPOINT sp_before_accounts;

  -- DELETE → BEFORE DELETE trigger
DELETE FROM Accounts
WHERE account_number = 'ACC_TEST';

ROLLBACK TO sp_before_accounts;   -- Undo changes but triggers will already be logged to AuditLog
COMMIT;

-- =========================================================
-- INVOICE  ─ fires: invoice_insert, invoice_update, invoice_delete
-- =========================================================
START TRANSACTION;
  -- INSERT
INSERT INTO Invoice(
              account_id, billing_cycle_start, billing_cycle_end,
              invoice_date, due_date, total_amount, status_invoice,
               previous_balance, payments_applied, new_balance
               )
VALUES (1,'2025-05-01','2025-05-31',CURDATE(),DATE_ADD(CURDATE(),INTERVAL 14 DAY),
          99.90,'Pending',0,0,99.90);

  SET @new_inv := LAST_INSERT_ID();   -- remembering invoice_id just created

  -- UPDATE
UPDATE Invoice
SET status_invoice = 'Paid', payments_applied = total_amount,
	new_balance = 0
WHERE invoice_id = @new_inv;
SAVEPOINT sp_before_invoice;

  -- DELETE
DELETE FROM Invoice 
WHERE invoice_id = @new_inv;

ROLLBACK TO sp_before_invoice;  
COMMIT;


-- ==================================================================
--  PAYMENT  ─ fires: payment_insert, payment_update, payment_delete
-- ==================================================================
START TRANSACTION;
  
  INSERT INTO Invoice
        (account_id, billing_cycle_start, billing_cycle_end,
         invoice_date, due_date, total_amount, status_invoice,
         previous_balance, payments_applied, new_balance)
  VALUES (1,'2025-06-01','2025-06-30',CURDATE(),DATE_ADD(CURDATE(),INTERVAL 14 DAY),
          120.00,'Pending',0,0,120.00);

  SET @perm_inv := LAST_INSERT_ID();

  -- INSERT
  INSERT INTO Payment
        (invoice_id, account_id, payment_date, amount_paid,
         payment_method, transaction_reference, status_payment)
  VALUES (@perm_inv,1,CURDATE(),120.00,'SEPA','TESTSEPA001','Received');

  SET @pay_id := LAST_INSERT_ID();

  -- UPDATE
  UPDATE Payment
     SET status_payment = 'Cleared'
   WHERE payment_id = @pay_id;
   
SAVEPOINT sp_before_payment;
  -- DELETE
DELETE FROM Payment 
WHERE payment_id = @pay_id;

ROLLBACK TO sp_before_payment;  
COMMIT;

-- =========================================================
-- ACCOUNTTRANSACTION  ─ fires: accountTransaction_insert, accountTransaction_delete
-- ========================================================= 
START TRANSACTION;

INSERT INTO Invoice
(account_id, billing_cycle_start, billing_cycle_end,
 invoice_date, due_date, total_amount, status_invoice,
 previous_balance, payments_applied, new_balance)
VALUES
(1, '2025-06-01', '2025-06-30', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY),
 120.00, 'Pending', 0.00, 0.00, 120.00);

-- Captures the invoice_id generated
SET @new_invoice_id = LAST_INSERT_ID();

INSERT INTO AccountTransaction
(account_id, invoice_id, txn_datetime,
 txn_type, amount, currency, balance_after_txn)
VALUES
(1, @new_invoice_id, NOW(), 'AdjustmentCr', 10.00, 'EUR', 110.00);

SET @txn_id := LAST_INSERT_ID();

SAVEPOINT sp_before_delete;

DELETE FROM AccountTransaction 
WHERE txn_id = @txn_id;

ROLLBACK TO sp_before_delete; 
COMMIT;


-- =========================================================
-- MAINTENANCE SCHEDULE ─ fires: maintenanceSchedule_insert, _update, _delete
-- ========================================================= 
START TRANSACTION;
  INSERT INTO MaintenanceSchedule
        (network_element_id, maintenance_start, maintenance_end,
         maintenance_type, engineer_id, status_maintenance)
  VALUES (1, NOW(), DATE_ADD(NOW(), INTERVAL 2 HOUR),
          'Planned', 2, 'Scheduled');

  SET @m_id := LAST_INSERT_ID();

  UPDATE MaintenanceSchedule
  SET status_maintenance = 'Completed'
   WHERE maintenance_id = @m_id;
SAVEPOINT sp_before_maintenance;

DELETE FROM MaintenanceSchedule 
WHERE maintenance_id = @m_id;

ROLLBACK TO sp_before_maintenance;  
COMMIT;

-- ==============================================
--   QUICK CHECK  –  to see the changes logged
-- ==============================================
SELECT audit_id, table_name, operation, row_changed, changed_at
FROM AuditLog
ORDER BY audit_id DESC -- most recent change first
LIMIT 20;