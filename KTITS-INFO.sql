
SET NAMES utf8mb4;
SET time_zone = '+03:00';
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `ktits_info`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `ktits_info`;

DROP TABLE IF EXISTS `activity_log`, `lessons`, `groups`, `bell_schedules`,
  `news`, `events`, `staff`, `route_edges`, `route_nodes`, `rooms`, `floors`, `users`, `settings`;

CREATE TABLE `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `full_name` VARCHAR(150) NOT NULL,
  `login` VARCHAR(50) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `role` ENUM('admin','schedule','content') NOT NULL DEFAULT 'content',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `last_login_at` DATETIME NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), UNIQUE KEY `uq_users_login` (`login`)
) ENGINE=InnoDB;

CREATE TABLE `groups` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL,
  `course` TINYINT UNSIGNED NOT NULL,
  `curator` VARCHAR(120) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`), UNIQUE KEY `uq_groups_code` (`code`), KEY `ix_groups_course` (`course`)
) ENGINE=InnoDB;

CREATE TABLE `lessons` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` SMALLINT UNSIGNED NOT NULL,
  `day_of_week` TINYINT UNSIGNED NOT NULL COMMENT '1=Пн … 6=Сб',
  `pair_number` TINYINT UNSIGNED NOT NULL,
  `subject` VARCHAR(500) NOT NULL,
  `teacher` VARCHAR(500) NOT NULL DEFAULT '',
  `room` VARCHAR(500) NOT NULL DEFAULT '',
  `is_cancelled` TINYINT(1) NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_lesson_slot` (`group_id`,`day_of_week`,`pair_number`),
  KEY `ix_lessons_teacher` (`teacher`(80)),
  CONSTRAINT `fk_lessons_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `bell_schedules` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `day_type` ENUM('week','sat') NOT NULL,
  `is_short` TINYINT(1) NOT NULL DEFAULT 0,
  `pair_number` TINYINT UNSIGNED NOT NULL,
  `start_time` TIME NOT NULL,
  `end_time` TIME NOT NULL,
  `break_text` VARCHAR(30) NOT NULL DEFAULT '',
  `is_active` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`), UNIQUE KEY `uq_bell_profile_pair` (`day_type`,`is_short`,`pair_number`)
) ENGINE=InnoDB;

CREATE TABLE `staff` (
  `id` MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` ENUM('teachers','management','departments','itcube') NOT NULL,
  `full_name` VARCHAR(250) NOT NULL,
  `position` TEXT NOT NULL,
  `qualification` VARCHAR(120) NOT NULL DEFAULT '',
  `room` VARCHAR(60) NOT NULL DEFAULT '',
  `department_head` VARCHAR(180) NOT NULL DEFAULT '',
  `description` VARCHAR(500) NOT NULL DEFAULT '',
  `photo_path` VARCHAR(255) NOT NULL DEFAULT '',
  `is_head` TINYINT(1) NOT NULL DEFAULT 0,
  `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `ix_staff_category` (`category`,`is_active`,`sort_order`)
) ENGINE=InnoDB;

CREATE TABLE `news` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(100) NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `summary` TEXT NOT NULL,
  `content` TEXT NULL,
  `published_at` DATE NOT NULL,
  `image_path` VARCHAR(255) NOT NULL DEFAULT '',
  `status` ENUM('draft','published') NOT NULL DEFAULT 'draft',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `ix_news_public` (`status`,`published_at`)
) ENGINE=InnoDB;

CREATE TABLE `events` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NULL,
  `event_date` DATE NOT NULL,
  `event_time` TIME NULL,
  `place` VARCHAR(255) NOT NULL DEFAULT '',
  `image_path` VARCHAR(255) NOT NULL DEFAULT '',
  `room_key` VARCHAR(100) NOT NULL DEFAULT '',
  `status` ENUM('draft','published') NOT NULL DEFAULT 'draft',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `ix_events_public` (`status`,`event_date`)
) ENGINE=InnoDB;

CREATE TABLE `floors` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `floor_key` VARCHAR(30) NOT NULL,
  `button_label` VARCHAR(30) NOT NULL,
  `short_title` VARCHAR(100) NOT NULL,
  `title` VARCHAR(180) NOT NULL,
  `underlay_path` VARCHAR(255) NOT NULL DEFAULT '',
  `underlay_opacity` DECIMAL(3,2) NOT NULL DEFAULT 0.35,
  `underlay_scale` DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`), UNIQUE KEY `uq_floors_key` (`floor_key`)
) ENGINE=InnoDB;

CREATE TABLE `rooms` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `floor_id` SMALLINT UNSIGNED NOT NULL,
  `room_key` VARCHAR(100) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `type` ENUM('aud','service','stairs') NOT NULL DEFAULT 'aud',
  `row_index` TINYINT UNSIGNED NULL,
  `row_y` SMALLINT NULL,
  `row_height` SMALLINT NULL,
  `weight` DECIMAL(5,2) NULL,
  `x` SMALLINT NULL, `y` SMALLINT NULL, `w` SMALLINT NULL, `h` SMALLINT NULL,
  `sort_order` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`), UNIQUE KEY `uq_rooms_floor_key` (`floor_id`,`room_key`),
  CONSTRAINT `fk_rooms_floor` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `route_nodes` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `floor_id` SMALLINT UNSIGNED NOT NULL,
  `x` SMALLINT UNSIGNED NOT NULL,
  `y` SMALLINT UNSIGNED NOT NULL,
  `kind` ENUM('corridor','entrance','stairs','passage') NOT NULL DEFAULT 'corridor',
  `room_key` VARCHAR(100) NULL,
  PRIMARY KEY (`id`), KEY `ix_route_nodes_floor` (`floor_id`),
  KEY `ix_route_nodes_connection` (`kind`,`room_key`),
  CONSTRAINT `fk_route_nodes_floor` FOREIGN KEY (`floor_id`) REFERENCES `floors` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `route_edges` (
  `node_a` INT UNSIGNED NOT NULL,
  `node_b` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`node_a`,`node_b`), KEY `ix_route_edges_node_b` (`node_b`),
  CONSTRAINT `fk_route_edges_a` FOREIGN KEY (`node_a`) REFERENCES `route_nodes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_route_edges_b` FOREIGN KEY (`node_b`) REFERENCES `route_nodes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `settings` (
  `setting_key` VARCHAR(80) NOT NULL,
  `setting_value` TEXT NOT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB;

CREATE TABLE `activity_log` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NULL,
  `action` VARCHAR(80) NOT NULL,
  `entity` VARCHAR(80) NOT NULL DEFAULT '',
  `entity_id` VARCHAR(80) NOT NULL DEFAULT '',
  `details` JSON NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`), KEY `ix_activity_user` (`user_id`,`created_at`),
  CONSTRAINT `fk_activity_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT INTO `users` (`full_name`, `login`, `password_hash`, `role`) VALUES ('Администратор системы', 'admin', 'SET_ON_INSTALL', 'admin');
INSERT INTO `users` (`full_name`, `login`, `password_hash`, `role`) VALUES ('Редактор расписания', 'schedule', 'SET_ON_INSTALL', 'schedule');
INSERT INTO `users` (`full_name`, `login`, `password_hash`, `role`) VALUES ('Редактор контента', 'content', 'SET_ON_INSTALL', 'content');
INSERT INTO `settings` (`setting_key`, `setting_value`) VALUES ('schedule_semester', '1 семестр 2026–2027 учебного года');
INSERT INTO `settings` (`setting_key`, `setting_value`) VALUES ('schedule_valid_from', 'с 01.09.2026');
INSERT INTO `settings` (`setting_key`, `setting_value`) VALUES ('news_updated_at', '31.10.2026');
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 1, 1, 'Литература', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 1, 1, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 1, 1, 'Физическая культура', 'Шакурова Л.А.\nКосолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 1, 2, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 1, 2, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 1, 2, 'Литература', 'Аббазова Ф.Ф.', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 1, 2, 'Физическая культура', 'Шакурова Л.А.\nКосолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 1, 2, 'КОД БУДУЩЕГО', 'Белкова Е.А.', '1122', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 1, 2, 'Литература', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 1, 3, 'Обществознание', 'Каримова Э.М.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 1, 3, 'Физическая культура', 'Шакурова Л.А.\nКосолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 1, 3, 'КОД БУДУЩЕГО', 'Белкова Е.А.', '1122', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 1, 3, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 1, 3, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 1, 3, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 1, 4, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 1, 4, 'Физическая культура', 'Шакурова Л.А.\nКосолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 1, 4, 'Литература', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 1, 4, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 1, 4, 'Информатика', 'Агзамова Г.Д.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 1, 5, 'Физическая культура', 'Шакурова Л.А.\nКосолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 1, 5, 'Обществознание', 'Каримова Э.М.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 2, 1, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 2, 1, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 2, 1, 'Физика', 'Харитонова С.А.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 2, 1, 'КОД БУДУЩЕГО', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 2, 2, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 2, 2, 'Физика', 'Харитонова С.А.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 2, 2, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 2, 2, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 2, 3, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 2, 3, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 2, 3, 'Обществознание', 'Каримова Э.М.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 2, 3, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 2, 4, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 2, 4, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 2, 5, 'Обществознание', 'Каримова Э.М.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 2, 5, 'Русский язык', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 3, 1, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 3, 1, 'Математика', 'Ягуфаров Б.М.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 3, 2, 'Иностранный язык', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 3, 2, 'Математика', 'Ягуфаров Б.М.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 3, 2, 'История', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 3, 2, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 3, 2, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 3, 3, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 3, 3, 'Русский язык', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 3, 3, 'Математика', 'Митрофанов М.Ю.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 3, 3, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 3, 3, 'Обществознание', 'Каримова Э.М.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 3, 3, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 3, 4, 'Математика', 'Митрофанов М.Ю.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 3, 4, 'Русский язык', 'Аббазова Ф.Ф.', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 3, 4, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 3, 4, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 3, 5, 'История', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 3, 5, 'Обществознание', 'Каримова Э.М.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 4, 1, 'Русский язык', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 4, 1, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 4, 2, 'Иностранный язык', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 4, 2, 'Иностранный язык', 'Вильданова Г.Р\nАширова Н.Т.', '407\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 4, 2, 'Русский язык', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 4, 3, 'Литература', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 4, 3, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 4, 3, 'Информатика', 'Фархуллин И.А.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 4, 3, 'Информатика\nИндивидуальный проект', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 4, 3, 'Информатика', 'Агзамова Г.Д.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 4, 3, 'Физика', 'Харитонова С.А.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 4, 4, 'Математика', 'Митрофанов М.Ю.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 4, 4, 'Информатика', 'Фархуллин И.А.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 4, 4, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 4, 4, 'Математика', 'Ягуфаров Б.М.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 4, 4, 'Литература', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 4, 5, 'Математика', 'Ягуфаров Б.М.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 4, 5, 'Математика', 'Митрофанов М.Ю.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 4, 5, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 5, 1, 'Информатика\nИндивидуальный проект', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 5, 1, 'КОД БУДУЩЕГО', 'Бикмуллина С.Х.', '1122', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 5, 1, 'История', 'Васильев Е.П.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 5, 2, 'КОД БУДУЩЕГО', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 5, 2, 'Информатика\nИндивидуальный проект', 'Фархуллин И.А.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 5, 2, 'Математика', 'Ягуфаров Б.М.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 5, 2, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 5, 2, 'Информатика\nИндивидуальный проект', 'Агзамова Г.Д.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 5, 3, 'Русский язык', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 5, 3, 'Математика', 'Ягуфаров Б.М.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 5, 3, 'Математика', 'Митрофанов М.Ю.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 5, 3, 'Обществознание\nЛитература', 'Каримова Э.М.\nМатвеева Е.Ю.', '310\n202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 5, 3, 'Информатика\nИндивидуальный проект', 'Агзамова Г.Д.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 5, 3, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 5, 4, 'Математика', 'Митрофанов М.Ю.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 5, 4, 'Информатика\nИндивидуальный проект', 'Фархуллин И.А.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 5, 4, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 5, 4, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 5, 4, 'Обществознание\nЛитература', 'Каримова Э.М.\nМатвеева Е.Ю.', '310\n202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 5, 5, 'Обществознание\nЛитература', 'Каримова Э.М.\nМатвеева Е.Ю.', '310\n202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 5, 5, 'Физическая культура', 'Вдовин С.В.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 6, 1, 'Обществознание\nЛитература', 'Каримова Э.М.\nБирюкова Ю.В.', '414\n426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 6, 1, 'Литература', 'Аббазова Ф.Ф.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 6, 1, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 6, 1, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 6, 2, 'Математика', 'Митрофанов М.Ю.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 6, 2, 'История', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 6, 2, 'География', 'Сергеева Е.А.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 6, 2, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (5, 6, 2, 'Обществознание\nЛитература', 'Каримова Э.М.\nБирюкова Ю.В.', '414\n426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (6, 6, 2, 'Иностранный язык', 'Вильданова Г.Р\nАширова Н.Т.', '407\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (1, 6, 3, 'История', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 6, 3, 'Иностранный язык', 'Моисеева А.А.\nГимадеева К.С', '411\n406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 6, 3, 'Математика', 'Митрофанов М.Ю.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (3, 6, 3, 'Математика', 'Ягуфаров Б.М.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (4, 6, 4, 'Математика', 'Ягуфаров Б.М.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 6, 4, 'Иностранный язык', 'Моисеева А.А.\nГимадеева К.С', '411\n406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (2, 6, 5, 'Обществознание', 'Каримова Э.М.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 1, 1, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 1, 1, 'Иностранный язык', 'Моисеева А.А.\nГимадеева К.С', '411\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 1, 1, 'Литература', 'Аббазова Ф.Ф.', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 1, 2, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 1, 2, 'КОД БУДУЩЕГО', 'Ясавеев Р.А.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 1, 2, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 1, 2, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 1, 3, 'Литература', 'Аббазова Ф.Ф.', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 1, 3, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 1, 3, 'Литература', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 1, 4, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 1, 4, 'Физика', 'Харитонова С.А.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 1, 5, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 2, 1, 'Обществознание\nЛитература', 'Гришина Д.Р.\nАббазова Ф.Ф.', '414\n414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 2, 1, 'Математика', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 2, 1, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 2, 2, 'Физическая культура', 'Петрова А.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 2, 2, 'Обществознание\nЛитература', 'Гришина Д.Р.\nАббазова Ф.Ф.', '414\n414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 2, 2, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 2, 2, 'КОД БУДУЩЕГО', 'Мурсалимов Д.Р.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 2, 3, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 2, 3, 'Физическая культура', 'Петрова А.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 2, 3, 'Обществознание\nЛитература', 'Гришина Д.Р.\nАббазова Ф.Ф.', '414\n414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 2, 3, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 2, 3, 'Математика', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 2, 4, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 2, 4, 'Физическая культура', 'Петрова А.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 2, 4, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 2, 4, 'Обществознание\nЛитература', 'Гришина Д.Р.\nАббазова Ф.Ф.', '414\n414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 2, 5, 'Физическая культура', 'Петрова А.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 2, 5, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 3, 1, 'Иностранный язык', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 3, 1, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 3, 2, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 3, 2, 'Литература', 'Аббазова Ф.Ф.', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 3, 2, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 3, 2, 'Русский язык', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 3, 3, 'Иностранный язык', 'Моисеева А.А.\nГимадеева К.С', '411\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 3, 3, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 3, 3, 'Литература', 'Аббазова Ф.Ф.', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 3, 3, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 3, 4, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 3, 4, 'История', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 3, 4, 'Иностранный язык', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 3, 5, 'Математика', 'Калинина Л.Р.', '1315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 3, 5, 'Русский язык', 'Аббазова Ф.Ф.', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 4, 1, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 4, 1, 'Математика', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 4, 2, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 4, 2, 'Информатика\nИндивидуальный проект', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 4, 2, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 4, 2, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 4, 3, 'Математика', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 4, 3, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 4, 3, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 4, 3, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 4, 4, 'Информатика\nИндивидуальный проект', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 4, 4, 'Обществознание\nЛитература', 'Гришина Д.Р.\nМатвеева Е.Ю.', '414\n202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 4, 5, 'Математика', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 4, 5, 'КОД БУДУЩЕГО', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 4, 6, 'КОД БУДУЩЕГО', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 5, 1, 'Математика', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 5, 1, 'КОД БУДУЩЕГО', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 5, 1, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 5, 1, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 5, 1, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 5, 2, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 5, 2, 'Математика', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 5, 2, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 5, 2, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 5, 2, 'Физическая культура', 'Юсупов Р.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 5, 3, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 5, 3, 'Информатика\nИндивидуальный проект', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 5, 3, 'Иностранный язык', 'Вильданова Г.Р\nАширова Н.Т.', '407\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 5, 3, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 5, 3, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 5, 4, 'История', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 5, 4, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 5, 4, 'Физика', 'Харитонова С.А.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 5, 4, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 5, 4, 'Математика', 'Долгова И.И.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 6, 1, 'Математика', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 6, 1, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (7, 6, 2, 'Русский язык', 'Аббазова Ф.Ф.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 6, 2, 'Математика', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 6, 2, 'История', 'Васильев Е.П.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 6, 2, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 6, 2, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (8, 6, 3, 'Русский язык', 'Аббазова Ф.Ф.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 6, 3, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 6, 3, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 6, 3, 'Математика', 'Долгова И.И.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (9, 6, 4, 'Русский язык', 'Аббазова Ф.Ф.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (10, 6, 4, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (11, 6, 4, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 1, 1, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 1, 1, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 1, 1, 'КОД БУДУЩЕГО', 'Ясавеев Р.А.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 1, 2, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 1, 2, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 1, 2, 'КОД БУДУЩЕГО', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 1, 2, 'Иностранный язык', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 1, 3, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 1, 3, 'Математика', 'Зарипова Л.Ш.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 1, 3, 'Обществознание', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 1, 3, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 1, 3, 'История', 'Васильев Е.П.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 1, 4, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 1, 4, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 1, 4, 'КОД БУДУЩЕГО', 'Зифарова А.В.', '1122', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 1, 4, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 1, 5, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 2, 1, 'Русский язык', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 2, 1, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 2, 1, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 2, 2, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 2, 2, 'Русский язык', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 2, 2, 'Основы безопасности и защиты Родины', 'Хуснутдинова Л.Г.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 2, 2, 'Информатика', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 2, 3, 'Математика', 'Зарипова Л.Ш.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 2, 3, 'Русский язык', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 2, 3, 'Физика', 'Харитонова С.А.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 2, 4, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 2, 4, 'Русский язык', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 2, 5, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 3, 1, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 3, 2, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 3, 2, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 3, 2, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 3, 3, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 3, 3, 'КОД БУДУЩЕГО', 'Мурсалимов Д.Р.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 3, 3, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 3, 3, 'История', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 3, 3, 'Физическая культура', 'Шакурова Л.А.\nВдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 3, 4, 'Физическая культура', 'Шакурова Л.А.\nВдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 3, 4, 'Математика', 'Зарипова Л.Ш.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 3, 4, 'Русский язык', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 3, 4, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 3, 4, 'Математика', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 3, 5, 'История', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 3, 5, 'Литература', 'Матвеева Е.Ю.', '202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 3, 5, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 4, 1, 'Информатика\nИндивидуальный проект', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 4, 1, 'Обществознание\nЛитература', 'Гришина Д.Р.\nБирюкова Ю.В.', '414\n426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 4, 1, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 4, 2, 'Обществознание\nЛитература', 'Гришина Д.Р.\nБирюкова Ю.В.', '414\n426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 4, 2, 'Математика', 'Зарипова Л.Ш.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 4, 2, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 4, 2, 'Информатика\nИндивидуальный проект', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 4, 2, 'Математика', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 4, 3, 'Иностранный язык', 'Вильданова Г.Р\nАширова Н.Т.', '407\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 4, 3, 'Обществознание\nЛитература', 'Гришина Д.Р.\nМатвеева Е.Ю.', '414\n202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 4, 3, 'Обществознание', 'Каримова Э.М.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 4, 3, 'Информатика\nИндивидуальный проект', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 4, 4, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 4, 4, 'Математика', 'Садыкова Н.А.', '310', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 4, 4, 'Обществознание', 'Каримова Э.М.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 4, 5, 'Литература', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 5, 1, 'Литература', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 5, 1, 'Информатика\nИндивидуальный проект', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 5, 1, 'Физическая культура', 'Юсупов Р.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 5, 1, 'Физика', 'Харитонова С.А.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 5, 1, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 5, 2, 'География', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 5, 2, 'Литература', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 5, 2, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 5, 2, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 5, 2, 'Математика', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 5, 3, 'КОД БУДУЩЕГО', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 5, 3, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 5, 3, 'Информатика\nИндивидуальный проект', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 5, 3, 'Физическая культура', 'Юсупов Р.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 5, 3, 'Родной язык', 'Хуснуллина З.М.\nШириева Г.М', '322\n313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 5, 4, 'Математика', 'Тиндина Г.М.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 5, 4, 'Физическая культура', 'Юсупов Р.Р.\nСамитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 5, 4, 'Иностранный язык', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 5, 4, 'Литература', 'Бирюкова Ю.В', '426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 6, 1, 'Иностранный язык', 'Вильданова Г.Р\nАширова Н.Т.', '407\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 6, 1, 'География', 'Сергеева Е.А.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 6, 2, 'Основы безопасности и защиты Родины', 'Журавлева Л.Н.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 6, 2, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 6, 2, 'Иностранный язык', 'Моисеева А.А.\nГимадеева К.С', '411\n406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 6, 3, 'Биология', 'Шкиндерова И.Н.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (13, 6, 3, 'История', 'Васильев Е.П.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (15, 6, 3, 'Обществознание\nЛитература', 'Каримова Э.М.\nБирюкова Ю.В.', '414\n426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 6, 3, 'Математика', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (12, 6, 4, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 6, 4, 'История', 'Васильев Е.П.', '425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (16, 6, 4, 'Обществознание\nЛитература', 'Каримова Э.М.\nБирюкова Ю.В.', '414\n426', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (14, 6, 5, 'Физика', 'Бабченко Т.Н', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 1, 2, 'История России', 'Васильев Е.П.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 1, 3, 'Электрорадиоизмерения', 'Хайруллина Э.И.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 1, 3, 'МДК. 01.01 Технология организации и выполнения работ по приему, обработке и вручению почтовых отправлений и денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 1, 3, 'Операционные системы и среды', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 1, 3, 'Основы алгоритмизации и программирования', 'Барышев Э.Е.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 1, 4, 'История России', 'Васильев Е.П.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 1, 4, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С\nМоисеева А.А.', '407\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 1, 4, 'МДК.01.01 Цифровая схемотехника', 'Сабиров Р.Б.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 1, 4, 'Основы алгоритмизации и программирования', 'Барышев Э.Е.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 1, 4, 'Операционные системы и среды', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 1, 5, 'Физика', 'Бабченко Т.Н.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 1, 5, 'Операционные системы и среды', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 2, 1, 'Основы электротехники и электронной техники', 'Хафизова С.Д.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 2, 1, 'История России\nОперационные системы и среды', 'Гайфутдинова Е.И.\nАлександров Е.С.', '419\n423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 2, 2, 'Основы бережливого производства', 'Сафина Э.Н.', '324\n419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 2, 2, 'История России\nОперационные системы и среды', 'Гайфутдинова Е.И.\nАлександров Е.С.', '419\n423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 2, 2, 'Основы электротехники и электронной техники', 'Хафизова С.Д.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 2, 3, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С\nМоисеева А.А.', '406\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 2, 3, 'Информационно-телекоммуникационные технологии в профессиональной деятельности', 'Сафина Э.Н.', '324\n419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 2, 3, 'Основы электротехники и электронной техники', 'Хафизова С.Д.\nИскакова В.В.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 2, 3, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 2, 3, 'Элементы высшей математики', 'Байгузин М.Р.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 2, 4, 'Теория электрических цепей', 'Хафизова С.Д.\nИскакова В.В.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 2, 4, 'Информационно-телекоммуникационные технологии в профессиональной деятельности', 'Сафина Э.Н.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 2, 4, 'Основы компьютерных сетей', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 2, 4, 'Элементы высшей математики', 'Байгузин М.Р.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 2, 5, 'Электрорадиоизмерения', 'Хайруллина Э.И.\nХафизова С.Д.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 2, 5, 'Дискретная математика Элементы высшей математики', 'Байгузин М.Р.\nИльина Н.А.', '308\n302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 2, 6, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 3, 1, 'Информационные технологии', 'Фархуллин И.А.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 3, 2, 'Основы электротехники и электронной техники', 'Хафизова С.Д.\nИскакова В.В.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 3, 3, 'Основы электронной и вычислительной техники', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 3, 3, 'Математические методы решения типовых прикладных задач', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 3, 3, 'Основы компьютерных сетей', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 3, 3, 'Основы алгоритмизации и программирования', 'Барышев Э.Е.', '35', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 3, 3, 'Основы электротехники и электронной техники', 'Хафизова С.Д.\nИскакова В.В.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 3, 4, 'Физика', 'Бабченко Т.Н.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 3, 4, 'МДК. 01.01 Технология организации и выполнения работ по приему, обработке и вручению почтовых отправлений и денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 3, 4, 'Основы электротехники и электронной техники', 'Хафизова С.Д.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 3, 4, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 3, 4, 'Основы алгоритмизации и программирования', 'Барышев Э.Е.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 3, 5, 'Электрорадиоизмерения\nТеория электрических цепей', 'Хайруллина Э.И.\nХафизова С.Д.\nХафизова С.Д.', '410\n413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 3, 5, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 3, 5, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 3, 6, 'Основы электротехники и электронной техники', 'Хафизова С.Д.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 4, 1, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 4, 1, 'История России', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 4, 2, 'Теория электросвязи', 'Петрова А.З.\nХафизова С.Д', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 4, 2, 'МДК. 01.03. Технология осуществления кассовых операций', 'Сафина Э.Н.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 4, 2, 'Дискретная математика', 'Байгузин М.Р.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 4, 3, 'Основы электронной и вычислительной техники', 'Петрова А.З.\nИскакова В.В.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 4, 3, 'Информационно-телекоммуникационные технологии в профессиональной деятельности', 'Сафина Э.Н.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 4, 3, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 4, 3, 'Основы электротехники и электронной техники', 'Хафизова С.Д.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 4, 3, 'Элементы высшей математики', 'Байгузин М.Р.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 4, 4, 'Теория электрических цепей', 'Хафизова С.Д.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 4, 4, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 4, 4, 'Элементы высшей математики', 'Байгузин М.Р.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 4, 4, 'Основы алгоритмизации и программирования', 'Барышев Э.Е.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 4, 5, 'Основы алгоритмизации и программирования', 'Барышев Э.Е.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 4, 5, 'Основы электротехники и электронной техники', 'Хафизова С.Д.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 5, 1, 'История России', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 5, 2, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.\nАширова Н.Т.', '405\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 5, 3, 'Математические методы решения типовых прикладных задач', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 5, 3, 'История России', 'Васильев Е.П.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 5, 3, 'Операционные системы и среды', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 5, 3, 'Информационные технологии', 'Фархуллин И.А.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 5, 4, 'МДК.01.02 Монтаж и эксплуатация компьютерных сетей', 'Васильева Е.С.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 5, 4, 'Экономика организации', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 5, 4, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 5, 4, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.\nАширова Н.Т.', '405\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 5, 4, 'Операционные системы и среды', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 5, 5, 'История\nОсновы электронной и вычислительной техники', 'Васильев Е.П.\nПетрова А.З.\nИскакова В.В.', '321\n413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 5, 5, 'МДК.01.02 Технология организации и осуществления продаж', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 5, 5, 'Операционные системы и среды', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 5, 6, 'Математические методы решения типовых прикладных задач', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 5, 6, 'Информационные технологии', 'Фархуллин И.А.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 6, 1, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 6, 1, 'Математические методы решения типовых прикладных задач', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 6, 1, 'История России', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 6, 2, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Тимохина В.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 6, 2, 'МДК. 01.03. Технология осуществления кассовых операций', 'Сафина Э.Н.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 6, 2, 'МДК.01.01 Цифровая схемотехника', 'Сабиров Р.Б.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 6, 2, 'Информационные технологии', 'Фархуллин И.А.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 6, 2, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (17, 6, 3, 'Математические методы решения типовых прикладных задач', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 6, 3, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Сафина Э.Н.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (18, 6, 3, 'МДК.01.01 Цифровая схемотехника', 'Сабиров Р.Б.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (20, 6, 3, 'История России', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 6, 3, 'Информационные технологии', 'Фархуллин И.А.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (19, 6, 4, 'Основы бережливого производства', 'Сафина Э.Н.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (21, 6, 4, 'Информационные технологии', 'Фархуллин И.А.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 1, 1, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 1, 1, 'История', 'Васильев Е.П.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 1, 2, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 1, 2, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 1, 2, 'Психология общения\nВведение в конфигурирование и программирование в системе 1 С', 'Галеева А.Р.\nАверьянова В.А.', '417\n1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 1, 3, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 1, 3, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 1, 3, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С\nМоисеева А.А.', '407\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 1, 3, 'Основы алгоритмизации и программирования', 'Кумышбаева С.А. Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 1, 3, 'Психология общения\nВведение в конфигурирование и программирование в системе 1 С', 'Галеева А.Р.\nАверьянова В.А.', '417\n1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 1, 4, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 1, 4, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 1, 4, 'Психология общения\nВведение в конфигурирование и программирование в системе 1 С', 'Галеева А.Р.\nАверьянова В.А.', '417\n1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 1, 4, 'Основы алгоритмизации и программирования', 'Кумышбаева С.А. Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 1, 5, 'Информационные технологии', 'Гимадеева К.С', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 1, 5, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 1, 5, 'Основы алгоритмизации и программирования', 'Кумышбаева С.А. Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 1, 6, 'Элементы высшей математики', 'Набиуллина Д.И.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 1, 6, 'Информационные технологии', 'Гимадеева К.С', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 2, 1, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 2, 2, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 2, 3, 'История\nЭлементы высшей математики', 'Гайфутдинова Е.И.\nНабиуллина Д.И.', '419\n301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 2, 3, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 2, 3, 'История\nЭлементы высшей математики', 'Васильев Е.П\nИльина Н.А.', '302\n302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 2, 3, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Андриянова А.Е.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 2, 4, 'История\nЭлементы высшей математики', 'Гайфутдинова Е.И.\nНабиуллина Д.И.', '419\n301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 2, 4, 'Основы алгоритмизации и программирования\nИнформационные технологии', 'Дунаева О.Н.\nНикулина В.С.', '1312\n324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 2, 4, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Андриянова А.Е.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 2, 4, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 2, 4, 'История\nЭлементы высшей математики', 'Васильев Е.П\nИльина Н.А.', '302\n302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 2, 5, 'Основы алгоритмизации и программирования\nИнформационные технологии', 'Дунаева О.Н.\nГимадеева К.С', '1312\n309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 2, 5, 'История\nЭлементы высшей математики', 'Гайфутдинова Е.И.\nНабиуллина Д.И.', '419\n301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 2, 5, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 2, 5, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Андриянова А.Е.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 2, 6, 'Основы алгоритмизации и программирования\nИнформационные технологии', 'Дунаева О.Н.\nГимадеева К.С', '1312\n309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 3, 1, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 3, 1, 'Основы алгоритмизации и программирования\nИнформационные технологии', 'Кумышбаева С.А.\nШирокова А.Н.', '304\n305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 3, 2, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 3, 2, 'Основы алгоритмизации и программирования\nИнформационные технологии', 'Кумышбаева С.А.\nШирокова А.Н.', '304\n305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 3, 2, 'Информационные технологии', 'Фархуллин И.А.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 3, 2, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С\nМоисеева А.А.', '407\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 3, 3, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 3, 3, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 3, 3, 'История\nЭлементы высшей математики', 'Васильев Е.П.\nНабиуллина Д.И.', '425\n301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 3, 3, 'Основы алгоритмизации и программирования\nИнформационные технологии', 'Кумышбаева С.А.\nФархуллин И.А.', '304\n311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 3, 3, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 3, 4, 'Основы алгоритмизации и программирования', 'Дунаева О.Н. Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 3, 4, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 3, 4, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С\nМоисеева А.А.', '407\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 3, 4, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 3, 4, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 3, 4, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 3, 5, 'Основы алгоритмизации и программирования', 'Дунаева О.Н. Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 3, 5, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 3, 5, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 3, 6, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 3, 6, 'Основы алгоритмизации и программирования', 'Дунаева О.Н. Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 4, 1, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 4, 1, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.\nАширова Н.Т.', '406\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 4, 1, 'Информационные технологии', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 4, 2, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 4, 2, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 4, 2, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 4, 2, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 4, 2, 'История', 'Васильев Е.П.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 4, 3, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 4, 3, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Андриянова А.Е.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 4, 3, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 4, 3, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 4, 3, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 4, 4, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Андриянова А.Е.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 4, 4, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 4, 4, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 4, 4, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 4, 5, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Андриянова А.Е.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 4, 5, 'Информационные технологии', 'Широкова А.Н.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 4, 6, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 5, 1, 'Основы алгоритмизации и программирования', 'Дунаева О.Н. Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 5, 2, 'Психология общения\nВведение в конфигурирование и программирование в системе 1 С', 'Галеева А.Р.\nРодионова А.А.', '417\n1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 5, 2, 'Основы алгоритмизации и программирования', 'Дунаева О.Н. Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 5, 3, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 5, 3, 'Психология общения\nВведение в конфигурирование и программирование в системе 1 С', 'Галеева А.Р.\nРодионова А.А.', '417\n1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 5, 3, 'Основы алгоритмизации и программирования', 'Дунаева О.Н. Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 5, 4, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 5, 4, 'Психология общения\nВведение в конфигурирование и программирование в системе 1 С', 'Галеева А.Р.\nРодионова А.А.', '417\n1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 5, 4, 'История', 'Васильев Е.П.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 5, 4, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 5, 4, 'Информационные технологии', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 5, 5, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 5, 5, 'Информационные технологии', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 5, 5, 'Информационные технологии', 'Фархуллин И.А.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 5, 5, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 6, 1, 'Информационные технологии', 'Гимадеева К.С', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 6, 1, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 6, 1, 'Основы алгоритмизации и программирования', 'Кумышбаева С.А. Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (22, 6, 2, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 6, 2, 'Основы алгоритмизации и программирования', 'Кумышбаева С.А. Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (26, 6, 2, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 6, 3, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 6, 3, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 6, 3, 'Основы алгоритмизации и программирования', 'Кумышбаева С.А. Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 6, 4, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 6, 4, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (25, 6, 4, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 6, 4, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (23, 6, 5, 'Введение в конфигурирование и программирование в системе 1 С', 'Родионова А.А.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (24, 6, 5, 'Информационные технологии', 'Гимадеева К.С', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (27, 6, 5, 'Введение в конфигурирование и программирование в системе 1 С', 'Аверьянова В.А.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 1, 1, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 1, 2, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 1, 3, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 1, 3, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 1, 3, 'Основы информационной безопасности', 'Сергеева Е.А.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 1, 3, 'Основы алгоритмизации и программирования', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 1, 4, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 1, 4, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 1, 4, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 1, 4, 'Основы алгоритмизации и программирования', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 1, 5, 'История', 'Васильев Е.П.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 1, 5, 'Элементы высшей математики', 'Набиуллина Д.И.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 1, 5, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 1, 5, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 1, 6, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 1, 6, 'Основы информационной безопасности', 'Сергеева Е.А.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 2, 1, 'Психология общения\nИнформационные технологии', 'Галеева А.Р.\nНикулина В.С.', '417\n324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 2, 1, 'Электроника и схемотехника', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 2, 2, 'Основы алгоритмизации и программирования', 'Долгова И.И', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 2, 2, 'Психология общения\nИнформационные технологии', 'Галеева А.Р.\nНикулина В.С.', '417\n324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 2, 2, 'Электроника и схемотехника', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 2, 3, 'МДК.08.02 Графический дизайн и мультимедиа', 'Хабибуллина Л.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 2, 3, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.\nАширова Н.Т.', '405\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 2, 3, 'Психология общения\nИнформационные технологии', 'Галеева А.Р.\nНикулина В.С.', '417\n324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 2, 3, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Сергеева Е.А.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 2, 3, 'Электроника и схемотехника', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 2, 4, 'МДК.08.02 Графический дизайн и мультимедиа', 'Хабибуллина Л.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 2, 4, 'Основы алгоритмизации и программирования', 'Долгова И.И', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 2, 4, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.\nАширова Н.Т.', '405\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 2, 4, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С\nМоисеева А.А.', '406\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 2, 5, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 2, 5, 'Архитектура аппаратных средств', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 2, 6, 'История\nИнформационные технологии', 'Гайфутдинова Е.И.\nШирокова А.Н.', '419\n305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 3, 1, 'Основы электротехники', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 3, 2, 'Математика', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 3, 2, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 3, 3, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 3, 3, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Сергеева Е.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 3, 3, 'Архитектура аппаратных средств', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 3, 4, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 3, 4, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 3, 4, 'История\nЭлементы высшей математики', 'Васильев Е.П.\nНабиуллина Д.И.', '425\n301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 3, 4, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 3, 4, 'Электроника и схемотехника', 'Петрова А.З.\nИскакова В.В.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 3, 5, 'История\nЭлементы высшей математики', 'Васильев Е.П.\nНабиуллина Д.И.', '425\n308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 3, 5, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 3, 5, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 3, 5, 'Электроника и схемотехника', 'Петрова А.З.\nИскакова В.В.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 3, 5, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 3, 6, 'История\nЭлементы высшей математики', 'Васильев Е.П.\nНабиуллина Д.И.', '425\n308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 3, 6, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 3, 6, 'Математика', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 4, 1, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 4, 2, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 4, 2, 'Основы алгоритмизации и программирования', 'Долгова И.И', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 4, 2, 'Основы алгоритмизации и программирования', 'Фархуллин И.А.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 4, 2, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 4, 3, 'История', 'Васильев Е.П.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 4, 3, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 4, 3, 'Основы информационной безопасности', 'Сергеева Е.А.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 4, 3, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.\nСадыкова А.Ш.', '406\n411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 4, 4, 'Основы алгоритмизации и программирования', 'Долгова И.И', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 4, 4, 'Психология общения', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 4, 4, 'Электроника и схемотехника', 'Петрова А.З.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 4, 4, 'История России', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 4, 5, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 4, 5, 'Основы алгоритмизации и программирования', 'Фархуллин И.А.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 4, 5, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 4, 5, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 4, 5, 'Основы электротехники', 'Петрова А.З.\nИскакова В.В.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 4, 6, 'Основы информационной безопасности', 'Сергеева Е.А.', '315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 4, 6, 'Информатика', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 5, 1, 'Математика', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 5, 2, 'Элементы высшей математики', 'Набиуллина Д.И.', '301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 5, 2, 'История', 'Васильев Е.П.', '304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 5, 2, 'Математика', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 5, 2, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 5, 2, 'Информационные технологии', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 5, 3, 'Основы алгоритмизации и программирования', 'Долгова И.И', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 5, 3, 'МДК.08.02 Графический дизайн и мультимедиа', 'Зифарова А.В.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 5, 3, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 5, 3, 'Электроника и схемотехника', 'Петрова А.З.\nИскакова В.В.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 5, 3, 'МДК.01.01 Компьютерные сети', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 5, 4, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 5, 4, 'МДК.08.02 Графический дизайн и мультимедиа', 'Зифарова А.В.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 5, 4, 'Электроника и схемотехника', 'Петрова А.З.\nИскакова В.В.', '401', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 5, 4, 'Основы алгоритмизации и программирования', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 5, 5, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.\nАширова Н.Т.', '405\n407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 5, 5, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 5, 5, 'МДК.01.01 Компьютерные сети', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 5, 6, 'Информационные технологии', 'Никулина В.С.', '324', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 6, 1, 'Основы алгоритмизации и программирования', 'Долгова И.И', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 6, 1, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 6, 1, 'Основы алгоритмизации и программирования', 'Фархуллин И.А.', '311', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (28, 6, 2, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 6, 2, 'МДК.08.02 Графический дизайн и мультимедиа', 'Зифарова А.В.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 6, 2, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 6, 2, 'Математика', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 6, 3, 'МДК.08.02 Графический дизайн и мультимедиа', 'Зифарова А.В.', '309', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (30, 6, 3, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 6, 3, 'Основы информационной безопасности', 'Сергеева Е.А.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 6, 3, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (29, 6, 4, 'Основы применения искусственного интеллекта и нейронных сетей в профессиональной деятельности', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 6, 4, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 6, 4, 'Основы информационной безопасности', 'Сергеева Е.А.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 6, 4, 'Элементы высшей математики', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (31, 6, 5, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 6, 5, 'Математика', 'Ильина Н.А.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (33, 6, 5, 'Информационные технологии', 'Широкова А.Н.', '305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (32, 6, 6, 'История', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 1, 1, 'МДК.03.02 Разработка приложений управления интегрированными системами', 'Артюхин Д.А.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 1, 1, 'Компьютерные сети', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 1, 1, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 1, 2, 'МДК.02.02. Формирование отчетной документации', 'Сафина Э.Н.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 1, 2, 'МДК.03.02 Разработка приложений управления интегрированными системами', 'Артюхин Д.А.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 1, 2, 'Компьютерные сети', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 1, 2, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 1, 3, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 1, 3, 'МДК.02.02. Формирование отчетной документации', 'Сафина Э.Н.', '308', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 1, 3, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 1, 3, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 1, 4, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 1, 4, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 1, 4, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 1, 5, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 1, 6, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 2, 1, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 2, 1, 'МДК.01.01. Технология организации и выполнения работ по приему, обработке и вручению почтовых отправлений и денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 2, 1, 'Компьютерные сети', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 2, 2, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 2, 2, 'Иностранный язык в профессиональной деятельности', 'Моисеева А.А.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 2, 2, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С', '406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 2, 2, 'Компьютерные сети', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 2, 3, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 2, 3, 'Основы менеджмента', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 2, 3, 'МДК.03.01 Сетевые и облачные технологии', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 2, 3, 'Инженерная компьютерная графика', 'Гайнанова А.С.\nГайнуллина Ч.И.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 2, 3, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 2, 4, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 2, 4, 'Основы менеджмента', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 2, 4, 'МДК.03.02 Разработка приложений управления интегрированными системами', 'Артюхин Д.А.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 2, 4, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 2, 4, 'Инженерная компьютерная графика', 'Гайнанова А.С.\nГайнуллина Ч.И.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 2, 5, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 2, 5, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 3, 1, 'Основы менеджмента', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 3, 1, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С', '407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 3, 1, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 3, 2, 'МДК.01.04. Обработка обращений клиентов', 'Сафина Э.Н.', '301\n425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 3, 2, 'МДК.03.02 Разработка приложений управления интегрированными системами', 'Артюхин Д.А.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 3, 2, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 3, 2, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 3, 3, 'Иностранный язык в профессиональной деятельности', 'Садыкова А.Ш.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 3, 3, 'Деловое общение', 'Сафина Э.Н.', '301\n425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 3, 3, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 3, 3, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 3, 4, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 3, 4, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 3, 5, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 3, 6, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 4, 1, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 4, 1, 'МДК.02.01.Технология обеспечения сохранности и своевременного движения почтовых отправлений, материальных ценностей, денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 4, 1, 'Безопасность жизнедеятельности\nМДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Гумеров Р.К.\nВалиев Р.Р.', '205\n1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 4, 2, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 4, 2, 'МДК.02.01.Технология обеспечения сохранности и своевременного движения почтовых отправлений, материальных ценностей, денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 4, 2, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 4, 2, 'Инженерная компьютерная графика', 'Гайнанова А.С.\nГайнуллина Ч.И.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 4, 2, 'Безопасность жизнедеятельности\nМДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Гумеров Р.К.\nВалиев Р.Р.', '205\n1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 4, 3, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 4, 3, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 4, 3, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 4, 3, 'Конструкция и компановка персонального компьютера', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 4, 3, 'Инженерная компьютерная графика', 'Гайнанова А.С.\nГайнуллина Ч.И.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 4, 4, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 4, 4, 'МДК.01.01 Монтаж и эксплуатация направляющих систем', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 4, 4, 'МДК.02.02 Техническое сопровождение интегрированных систем', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 4, 4, 'Конструкция и компановка персонального компьютера', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 4, 5, 'МДК.01.01 Монтаж и эксплуатация направляющих систем', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 4, 5, 'МДК.02.02 Техническое сопровождение интегрированных систем', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 4, 6, 'МДК.01.01 Монтаж и эксплуатация направляющих систем', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 5, 1, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 5, 1, 'МДК.01.01 Монтаж и эксплуатация направляющих систем', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 5, 1, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 5, 1, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 5, 1, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 5, 2, 'МДК.01.03 Монтаж и эксплуатация мультисервисных сетей абонентского доступа', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 5, 2, 'МДК.01.01 Монтаж и эксплуатация направляющих систем', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 5, 2, 'МДК.01.04. Обработка обращений клиентов', 'Сафина Э.Н.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 5, 2, 'МДК.02.02 Техническое сопровождение интегрированных систем', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 5, 2, 'МДК.03.02 Настройка и обеспечение функционирования программных средств компьютерных систем и комплексов', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 5, 2, 'Инженерная компьютерная графика', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 5, 3, 'МДК.01.01 Монтаж и эксплуатация направляющих систем', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 5, 3, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 5, 3, 'Деловое общение', 'Сафина Э.Н.', '413', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 5, 3, 'МДК.02.02 Техническое сопровождение интегрированных систем', 'Антонова Т.С.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 5, 3, 'Инженерная компьютерная графика', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 5, 3, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 5, 4, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 5, 4, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 5, 4, 'МДК.03.01 Сетевые и облачные технологии', 'Крохина С.В.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 6, 1, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Крохина С.В.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 6, 1, 'МДК.02.01.Технология обеспечения сохранности и своевременного движения почтовых отправлений, материальных ценностей, денежных средств\nМДК.02.02. Формирование отчетной документации', 'Багаутдинова Э.З.\nСафина Э.Н.', '314\n314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 6, 1, 'Конструкция и компановка персонального компьютера', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 6, 2, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Крохина С.В.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 6, 2, 'МДК.01.01. Технология организации и выполнения работ по приему, обработке и вручению почтовых отправлений и денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 6, 2, 'МДК.02.02 Техническое сопровождение интегрированных систем', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 6, 2, 'Конструкция и компановка персонального компьютера', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 6, 3, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (35, 6, 3, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Крохина С.В.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 6, 3, 'МДК.01.01. Технология организации и выполнения работ по приему, обработке и вручению почтовых отправлений и денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 6, 3, 'МДК.02.02 Техническое сопровождение интегрированных систем', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 6, 3, 'Конструкция и компановка персонального компьютера', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (39, 6, 3, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 6, 4, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Крохина С.В.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (37, 6, 4, 'МДК.01.01. Технология организации и выполнения работ по приему, обработке и вручению почтовых отправлений и денежных средств', 'Багаутдинова Э.З.', '314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (36, 6, 4, 'МДК.02.02 Техническое сопровождение интегрированных систем', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (38, 6, 4, 'Конструкция и компановка персонального компьютера', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 6, 5, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Крохина С.В.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (34, 6, 6, 'МДК.01.04 Монтаж и эксплуатация систем видеонаблюдения и систем безопасности', 'Крохина С.В.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 1, 1, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 1, 1, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.\nАндриянова А.Е.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 1, 1, 'МДК.05.01 Проектирование и дизайн информационных систем\nМДК.02.01 Технология разработки программного обеспечения', 'Аверьянова В.А.\nХузиев Э.А.\nКумышбаева С.А.', '1305\n1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 1, 2, 'Иностранный язык в профессиональной деятельности', 'Моисеева А.А.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 1, 2, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.\nАндриянова А.Е.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 1, 2, 'МДК.05.01 Проектирование и дизайн информационных систем\nМДК.02.01 Технология разработки программного обеспечения', 'Аверьянова В.А.\nХузиев Э.А.\nКумышбаева С.А.', '1305\n1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 1, 2, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С', '407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 1, 3, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.\nАртюхин Д.А.', '1210', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 1, 3, 'МДК. 05.02 Разработка кода информационных систем', 'Хузиев Э.А.', '1305\n1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 1, 3, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 1, 4, 'МДК. 05.02 Разработка кода информационных систем', 'Хузиев Э.А.', '1305\n1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 1, 4, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 1, 4, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 1, 5, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 1, 5, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 1, 6, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 1, 6, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 2, 1, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.\nАртюхин Д.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 2, 1, 'Экономика отрасли (1-5 неделя)\nМенеджмент в профессиональной деятельности (6-10 неделя)\nЧисленные методы (11-13 неделя)', 'Мавзиева Г.Р.\nМаннапова Д.Ф.\nКалинина Л.Р.', '416\n408\n1315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 2, 1, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 2, 1, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 2, 2, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.\nАртюхин Д.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 2, 2, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 2, 2, 'МДК. 05.02 Разработка кода информационных систем', 'Хузиев Э.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 2, 2, 'Экономика отрасли (1-5 неделя)\nМенеджмент в профессиональной деятельности (6-10 неделя)\nЧисленные методы (11-13 неделя)', 'Мавзиева Г.Р.\nМаннапова Д.Ф.\nКалинина Л.Р.', '416\n408\n1315', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 2, 2, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 2, 2, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 2, 3, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 2, 3, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 2, 3, 'МДК. 05.02 Разработка кода информационных систем', 'Хузиев Э.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 2, 3, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 2, 3, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 2, 4, 'МДК.05.01 Проектирование и дизайн информационных систем', 'Аверьянова В.А.\nХузиев Э.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 2, 4, 'Безопасность жизнедеятельности\nЧисленные методы', 'Хуснутдинова Л.Г.\nКалинина Л.Р.', '404\n1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 3, 1, 'Численные методы\nМДК.11.01 Технология разработки и защиты баз данных', 'Калинина Л.Р.\nХрущева Л.Г., Артемьев Е.А.', '1305\n1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 3, 1, 'МДК.05.01 Проектирование и дизайн информационных систем', 'Аверьянова В.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 3, 1, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 3, 2, 'Численные методы\nМДК.11.01 Технология разработки и защиты баз данных', 'Калинина Л.Р.\nХрущева Л.Г., Артемьев Е.А.', '1305\n1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 3, 2, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 3, 2, 'МДК.05.01 Проектирование и дизайн информационных систем', 'Аверьянова В.А.\nХузиев Э.А.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 3, 2, 'МДК.02.03 Математическое моделирование', 'Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 3, 2, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 3, 3, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 3, 3, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.', '406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 3, 3, 'МДК.02.03 Математическое моделирование', 'Дунаева О.Н.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 3, 3, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 3, 3, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 3, 3, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 3, 4, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 3, 4, 'МДК. 05.02 Разработка кода информационных систем', 'Хузиев Э.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 3, 4, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 3, 5, 'МДК. 05.02 Разработка кода информационных систем', 'Хузиев Э.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 3, 5, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 3, 6, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 4, 1, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 4, 1, 'МДК.05.01 Проектирование и дизайн информационных систем', 'Аверьянова В.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 4, 2, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 4, 2, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 4, 2, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 4, 2, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 4, 3, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 4, 3, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 4, 3, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 4, 3, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Доносий И.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 4, 3, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 4, 3, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 4, 4, 'МДК.01.01 Разработка программных модулей', 'Газизов К.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 4, 4, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 4, 4, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Доносий И.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 4, 4, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 4, 4, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 4, 5, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 4, 5, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Доносий И.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 4, 5, 'Физическая культура\nИностранный язык в профессиональной деятельности', 'Косолап А.Н.\nВильданова Г.Р.', 'с/з\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 4, 5, 'Иностранный язык в профессиональной деятельности', 'Садыкова А.Ш.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 4, 6, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Доносий И.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 4, 6, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 5, 1, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 5, 1, 'Иностранный язык в профессиональной деятельности', 'Садыкова А.Ш.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 5, 2, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.\nАртемьев Е.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 5, 2, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 5, 2, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 5, 2, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 5, 3, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.\nАртемьев Е.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 5, 3, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 5, 3, 'Иностранный язык в профессиональной деятельности', 'Садыкова А.Ш.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 5, 3, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 5, 4, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.\nАртемьев Е.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 5, 4, 'МДК.02.03 Математическое моделирование (1-5 неделя)\nЧисленные методы (6-13 неделя)', 'Дунаева О.Н.\nКалинина Л.Р.', '1312\n1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 5, 4, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 5, 4, 'Безопасность жизнедеятельности', 'Гумеров Р.К.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 5, 5, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.\nАртемьев Е.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 5, 5, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 5, 5, 'МДК.02.03 Математическое моделирование (1-5 неделя)\nЧисленные методы (6-13 неделя)', 'Дунаева О.Н.\nКалинина Л.Р.', '1312\n1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 5, 5, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 5, 6, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 6, 1, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 6, 1, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 6, 1, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 6, 2, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (41, 6, 2, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.\nАртемьев Е.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (45, 6, 2, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 6, 3, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.\nАртемьев Е.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (40, 6, 4, 'МДК.11.01 Технология разработки и защиты баз данных', 'Хрущева Л.Г.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 6, 4, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 6, 4, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (42, 6, 5, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (43, 6, 5, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 6, 5, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (44, 6, 6, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 1, 1, 'МДК.01.02 Базы данных', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 1, 1, 'МДК.01.01 Операционные системы', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 1, 1, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 1, 2, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 1, 2, 'МДК.01.01 Операционные системы', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 1, 2, 'МДК.01.02 Базы данных', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 1, 2, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 1, 3, 'Численные методы', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 1, 3, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 1, 3, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 1, 4, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 1, 4, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 1, 4, 'МДК.02.01 Администрирование сетевых операционных систем', 'Петров Д.С.\nПетрова А.З.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 1, 4, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 1, 5, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 1, 5, 'МДК.02.01 Администрирование сетевых операционных систем', 'Петров Д.С.\nПетрова А.З.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 2, 1, 'Физическая культура', 'Самитов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 2, 2, 'МДК.02.01 Программные и программно-аппаратные средства защиты информации', 'Гаврилова А.А.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 2, 2, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 2, 3, 'МДК.02.01 Программные и программно-аппаратные средства защиты информации', 'Гаврилова А.А.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 2, 3, 'МДК.01.01 Операционные системы', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 2, 3, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 2, 4, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 2, 4, 'МДК.01.01 Операционные системы', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 2, 4, 'МДК.01.03 Сети и системы передачи информации', 'Хайруллина Э.И.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 2, 4, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 2, 4, 'МДК.02.01 Администрирование сетевых операционных систем', 'Петров Д.С.\nПетрова А.З.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 2, 5, 'Безопасность жизнедеятельности\nЧисленные методы', 'Хуснутдинова Л.Г.\nКалинина Л.Р.', '205\n1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 2, 5, 'Иностранный язык в профессиональной деятельности', 'Моисеева А.А.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 2, 5, 'МДК.02.01 Администрирование сетевых операционных систем', 'Петров Д.С.\nПетрова А.З.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 3, 1, 'МДК.01.01 Операционные системы', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 3, 1, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 3, 2, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 3, 2, 'МДК.01.01 Операционные системы', 'Александров Е.С.', '423', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 3, 2, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 3, 3, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '404', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 3, 3, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 3, 3, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 3, 4, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 3, 4, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении\nМДК.01.03 Сети и системы передачи информации', 'Айтыкина Л.Ф.\nХайруллина Э.И.', '1314\n410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 3, 4, 'МДК.02.01 Администрирование сетевых операционных систем', 'Петров Д.С.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 3, 4, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 3, 5, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 3, 5, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 3, 5, 'МДК.02.01 Администрирование сетевых операционных систем', 'Петров Д.С.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 3, 5, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 4, 1, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении\nМДК.01.03 Сети и системы передачи информации', 'Айтыкина Л.Ф.\nХайруллина Э.И.', '1314\n410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 4, 2, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 4, 2, 'МДК.01.03 Сети и системы передачи информации', 'Хайруллина Э.И.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 4, 2, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 4, 2, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 4, 3, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 4, 3, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 4, 3, 'МДК.02.01 Администрирование сетевых операционных систем\nМДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Петров Д.С.\nВалиуллина А.Р.', '1303\n1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 4, 4, 'Физическая культура\nИностранный язык в профессиональной деятельности', 'Вдовин С.В. Вильданова Г.Р.', 'с/з\n405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 4, 4, 'МДК.01.04 Эксплуатация автоматизированных (информационных) систем в защищенном исполнении', 'Айтыкина Л.Ф.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 4, 4, 'МДК.02.01 Администрирование сетевых операционных систем\nМДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Петров Д.С.\nВалиуллина А.Р.', '1303\n1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 4, 4, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 4, 5, 'Менеджмент в профессиональной деятельности', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 4, 5, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 5, 1, 'МДК.01.03 Сети и системы передачи информации', 'Хайруллина Э.И.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 5, 2, 'МДК.02.01 Программные и программно-аппаратные средства защиты информации', 'Гаврилова А.А.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 5, 2, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.', '406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 5, 2, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 5, 3, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 5, 3, 'МДК.01.02 Базы данных', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 5, 3, 'МДК.02.01 Программные и программно-аппаратные средства защиты информации', 'Гаврилова А.А.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 5, 3, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 5, 3, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.', '406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 5, 4, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 5, 4, 'МДК.01.03 Сети и системы передачи информации', 'Хайруллина Э.И.', '410', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 5, 4, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 5, 4, 'МДК.01.02 Организация, принципы построения и функционирования компьютерных сетей', 'Валиуллина А.Р.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 5, 5, 'Безопасность жизнедеятельности', 'Хуснутдинова Л.Г.', '205', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 5, 5, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 5, 5, 'Иностранный язык в профессиональной деятельности', 'Садыкова А.Ш.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 6, 1, 'МДК.02.01 Программные и программно-аппаратные средства защиты информации', 'Гаврилова А.А.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 6, 1, 'МДК.01.02 Базы данных', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 6, 1, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (47, 6, 2, 'МДК.01.02 Базы данных', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 6, 2, 'МДК.02.01 Программные и программно-аппаратные средства защиты информации', 'Гаврилова А.А.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 6, 2, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (48, 6, 3, 'МДК.01.02 Базы данных', 'Мавлекаев Д.Р.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (50, 6, 3, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 6, 4, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 6, 4, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (46, 6, 5, 'МДК.08.01 Проектирование и разработка интерфейсов пользователя', 'Хайруллин Д.И.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 6, 5, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (49, 6, 6, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Вальшина М.А.', '1202', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 1, 1, 'МДК.02.03 Системы управления базами данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 1, 2, 'МДК.04.01 Планирование и организация работы структурного подразделения', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 1, 2, 'МДК.02.03 Системы управления базами данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 1, 3, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 1, 3, 'МДК.02.03 Системы управления базами данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 1, 3, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 1, 3, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А.', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 1, 3, 'МДК.02.03 Организация администрирования компьютерных систем', 'Фархутдинов А.М.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 1, 4, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 1, 4, 'МДК.02.04 Разработка прикладных приложений', 'Артюхин А.А.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 1, 4, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 1, 4, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 1, 4, 'МДК.02.03 Организация администрирования компьютерных систем', 'Фархутдинов А.М.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 1, 5, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 1, 5, 'Иностранный язык в профессиональной деятельности', 'Моисеева А.А.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 1, 5, 'МДК.02.04 Разработка прикладных приложений', 'Артюхин А.А.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 1, 5, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 1, 5, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 1, 5, 'Правовое обеспечение профессиональной деятельности', 'Васильева Г.Р.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 1, 6, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 1, 6, 'МДК.02.03 Системы управления базами данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 1, 6, 'Иностранный язык в профессиональной деятельности', 'Садыкова А.Ш.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 1, 6, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.', '406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 2, 1, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 2, 2, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 2, 2, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 2, 3, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 2, 3, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 2, 3, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 2, 3, 'МДК.02.04 Разработка прикладных приложений', 'Артюхин А.А.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 2, 3, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 2, 3, 'МДК.03.01 Эксплуатация объектов сетевой инфраструктуры', 'Фархутдинов А.М.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 2, 4, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 2, 4, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 2, 4, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 2, 4, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 2, 4, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 2, 4, 'МДК.03.01 Эксплуатация объектов сетевой инфраструктуры', 'Фархутдинов А.М.', '1318', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 2, 5, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 2, 5, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 2, 5, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 2, 5, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 2, 6, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 2, 6, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 2, 6, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 2, 7, 'Основы философии', 'Гайфутдинова Е.И', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 3, 3, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 3, 3, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 3, 3, 'МДК.02.04 Разработка прикладных приложений', 'Артюхин А.А.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 3, 3, 'МДК.02.03 Системы управления базами данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 3, 3, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 3, 3, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 3, 3, 'МДК.02.03 Организация администрирования компьютерных систем', 'Фархутдинов А.М.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 3, 4, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 3, 4, 'МДК.04.01 Планирование и организация работы структурного подразделения', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 3, 4, 'МДК.02.04 Разработка прикладных приложений', 'Артюхин А.А.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 3, 4, 'МДК.02.03 Системы управления базами данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 3, 4, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 3, 4, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 3, 4, 'МДК.02.03 Организация администрирования компьютерных систем', 'Фархутдинов А.М.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 3, 5, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 3, 5, 'МДК.02.04 Разработка прикладных приложений', 'Артюхин А.А.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 3, 5, 'МДК.02.02 Криптографические средства защиты информации', 'Загидуллина А.Б.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 3, 5, 'Основы философии', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 3, 6, 'Основы философии', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 4, 2, 'МДК.04.01 Планирование и организация работы структурного подразделения', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 4, 3, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 4, 3, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 4, 3, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 4, 3, 'МДК.03.01 Эксплуатация объектов сетевой инфраструктуры', 'Фархутдинов А.М.', '1217\n1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 4, 4, 'МДК.04.01 Планирование и организация работы структурного подразделения', 'Маннапова Д.Ф.', '408', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 4, 4, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 4, 4, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 4, 4, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 4, 4, 'МДК.03.01 Эксплуатация объектов сетевой инфраструктуры', 'Фархутдинов А.М.', '1217\n1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 4, 5, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 4, 5, 'Физическая культура', 'Шакурова Л.А.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 4, 5, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 4, 5, 'Иностранный язык в профессиональной деятельности', 'Бочкова О.Е.', '406', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 4, 5, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 4, 5, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 4, 6, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 4, 6, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 4, 6, 'Основы философии', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 4, 6, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 4, 7, 'Основы философии', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 5, 2, 'МДК.05.01. Теоретические основы конвергенции логических, интеллектуальных сетей и инфокоммуникационных технологий в информационно-коммуникационных сетях связи', 'Васильева Е.С.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 5, 2, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 5, 2, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 5, 3, 'МДК.06.01 Технология выполнения работ', 'Тимохина В.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 5, 3, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 5, 3, 'Правовое обеспечение профессиональной деятельности\nМДК.02.03 Организация администрирования компьютерных систем', 'Васильева Г.Р. Фархутдинов А.М.', '410\n1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 5, 4, 'МДК.06.01 Технология выполнения работ', 'Тимохина В.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 5, 4, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 5, 4, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 5, 4, 'Основы философии', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 5, 4, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 5, 4, 'МДК.02.03 Организация администрирования компьютерных систем', 'Фархутдинов А.М.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 5, 5, 'МДК.06.01 Технология выполнения работ', 'Тимохина В.А.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 5, 5, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.', '1307', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 5, 5, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Валиев Р.Р.', '1316', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 5, 5, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 5, 5, 'Основы философии', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 5, 6, 'МДК.06.01 Технология выполнения работ', 'Тимохина В.А.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 5, 6, 'Иностранный язык в профессиональной деятельности', 'Вильданова Г.Р.', '405', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 5, 6, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 6, 1, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (54, 6, 2, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 6, 3, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 6, 3, 'МДК.03.01 Защита информации в инфокоммуникационных системах и сетях связи', 'Тимохина В.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 6, 3, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 6, 3, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 6, 3, 'МДК.03.01 Эксплуатация объектов сетевой инфраструктуры', 'Фархутдинов А.М.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 6, 4, 'Экономика отрасли', 'Мавзиева Г.Р.', '416', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 6, 4, 'МДК.03.01 Защита информации в инфокоммуникационных системах и сетях связи', 'Тимохина В.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 6, 4, 'МДК.02.02 Программирование микроконтроллеров', 'Царев К.В.\nБарышев Э.Е.', '1303', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 6, 4, 'Основы философии', 'Гайфутдинова Е.И.', '419', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (62, 6, 4, 'МДК.02.02 Криптографические средства защиты информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 6, 4, 'МДК.03.01 Эксплуатация объектов сетевой инфраструктуры', 'Фархутдинов А.М.', '1217', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 6, 5, 'МДК.03.01 Защита информации в инфокоммуникационных системах и сетях связи', 'Тимохина В.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (52, 6, 5, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 6, 5, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 6, 5, 'МДК.03.01 Техническая защита информации', 'Гаврилова А.А', '1313', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 6, 5, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (51, 6, 6, 'МДК.03.01 Защита информации в инфокоммуникационных системах и сетях связи', 'Тимохина В.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (53, 6, 6, 'МДК.04.01 Выполнение работ по одной или нескольким профессиям рабочих, должностям служащих', 'Антонова Т.С.', '1317', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (61, 6, 6, 'Физическая культура', 'Юсупов Р.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (63, 6, 6, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 1, 1, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 1, 2, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 1, 3, 'Правовое обеспечение профессиональной деятельности', 'Васильева Г.Р.', '302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 1, 3, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 1, 4, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 1, 4, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1302', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 1, 5, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 1, 5, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 1, 6, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 1, 6, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 1, 6, 'МДК.06.04 Интеллектуальные системы и технологии', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 1, 6, 'МДК.06.01 Внедрение информационных систем', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 1, 7, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 1, 7, 'МДК.06.04 Интеллектуальные системы и технологии', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 1, 7, 'МДК.07.01 Управление и автоматизация баз данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 2, 1, 'МДК.02.01 Технология разработки программного обеспечения(7-9 неделя)', 'Кумышбаева С.А.', '1312', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 2, 1, 'МДК.06.03 Устройство и функционирование информационной системы', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 2, 1, 'МДК.06.04 Интеллектуальные системы и технологии', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 2, 1, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 2, 2, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 2, 2, 'МДК.06.01 Внедрение информационных систем', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 2, 2, 'МДК.06.04 Интеллектуальные системы и технологии', 'Калинина Л.Р.', '1305', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 2, 2, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 2, 3, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 2, 3, 'МДК.06.01 Внедрение информационных систем', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 2, 3, 'МДК.06.04 Интеллектуальные системы и технологии\nМДК.07.01 Управление и автоматизация баз данных', 'Калинина Л.Р.\nАртемьев Е.А.', '1305\n1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 2, 3, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 2, 3, 'Физическая культура', 'Вдовин С.В.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 2, 4, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 2, 4, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 2, 4, 'МДК.06.04 Интеллектуальные системы и технологии\nМДК.07.01 Управление и автоматизация баз данных', 'Калинина Л.Р.\nАртемьев Е.А.', '1305\n1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 2, 4, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 2, 5, 'Основы философии (1-6 неделя)', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 2, 5, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 2, 5, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 2, 6, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 2, 6, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 2, 7, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 3, 1, 'Иностранный язык в профессиональной деятельности', 'Моисеева А.А.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 3, 2, 'Основы философии', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 3, 3, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 3, 3, 'МДК.06.03 Устройство и функционирование информационной системы', 'ВАКАНСИЯ', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 3, 3, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 3, 4, 'Правовое обеспечение профессиональной деятельности', 'Васильева Г.Р.', '301\n425', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 3, 4, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 3, 4, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 3, 5, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С', '407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 3, 5, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 3, 5, 'Иностранный язык в профессиональной деятельности', 'Моисеева А.А.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 3, 5, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 3, 5, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 3, 6, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 3, 6, 'Основы философии', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 3, 6, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 3, 6, 'Иностранный язык в профессиональной деятельности', 'Гимадеева К.С', '407', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 3, 7, 'МДК.07.01 Управление и автоматизация баз данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 4, 1, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 4, 1, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 4, 1, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 4, 2, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 4, 2, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 4, 2, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 4, 3, 'Физическая культура', 'Косолап А.Н.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 4, 3, 'МДК.07.01 Управление и автоматизация баз данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 4, 3, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 4, 3, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 4, 4, 'Правовое обеспечение профессиональной деятельности', 'Васильева Г.Р.', '321', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 4, 4, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 4, 4, 'МДК.07.01 Управление и автоматизация баз данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 4, 4, 'МДК.05.02 Разработка кода информационных систем', 'Гатауллин Н.Р.', '1301', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 4, 4, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 4, 5, 'Правовое обеспечение профессиональной деятельности', 'Васильева Г.Р.', '', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 4, 5, 'МДК.07.01 Управление и автоматизация баз данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 4, 5, 'Основы философии', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 4, 6, 'МДК.02.02 Инструментальные средства разработки программного обеспечения', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 4, 6, 'Основы философии', 'Гришина Д.Р.', '414', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 4, 6, 'Физическая культура', 'Петрова А.Р.', 'с/з', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 5, 2, 'Основы философии\nМДК.06.01 Внедрение информационных систем', 'Гришина Д.Р.\nРодионова А.А.', '414\n1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 5, 2, 'Иностранный язык в профессиональной деятельности', 'Садыкова А.Ш.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 5, 3, 'МДК.06.03 Устройство и функционирование информационной системы', 'Родионова А.А.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 5, 3, 'МДК.06.03 Устройство и функционирование информационной системы', 'ВАКАНСИЯ', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 5, 3, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 5, 4, 'МДК.06.03 Устройство и функционирование информационной системы', 'Родионова А.А.', '1203', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 5, 4, 'МДК.06.03 Устройство и функционирование информационной системы', 'ВАКАНСИЯ', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 5, 4, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 5, 5, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 5, 5, 'Основы философии\nМДК.06.01 Внедрение информационных систем', 'Гришина Д.Р.\nРодионова А.А.', '414\n1314', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 5, 5, 'МДК.06.01 Внедрение информационных систем', 'Родионова А.А.', '1215', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 5, 5, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 5, 5, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 5, 6, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 5, 6, 'Основы философии', 'Галеева А.Р.', '417', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 5, 6, 'МДК.07.01 Управление и автоматизация баз данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 5, 6, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 5, 7, 'МДК.02.01 Технология разработки программного обеспечения', 'Кумышбаева С.А.', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 6, 1, 'МДК.07.01 Управление и автоматизация баз данных', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 6, 1, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 6, 2, 'МДК.06.03 Устройство и функционирование информационной системы', 'ВАКАНСИЯ', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (59, 6, 2, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 6, 3, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (58, 6, 3, 'МДК.06.03 Устройство и функционирование информационной системы', 'ВАКАНСИЯ', 'Точка кипения', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 6, 3, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 6, 4, 'Стандартизация, сертификация и техническое документоведение', 'Гайнанова А.С.', '402', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 6, 4, 'МДК.02.03 Математическое моделирование', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 6, 4, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 6, 5, 'МДК.02.03 Математическое моделирование', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (56, 6, 5, 'Иностранный язык в профессиональной деятельности', 'Моисеева А.А.', '411', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (60, 6, 5, 'МДК.09.01 Проектирование и разработка веб-приложений', 'Халиуллина А.Р.\nЗарипов Р.Р.', '1304', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (55, 6, 6, 'МДК.02.03 Математическое моделирование', 'Артемьев Е.А.', '1220', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 6, 6, 'МДК.06.01 Внедрение информационных систем', 'Родионова А.А.', '1201', 0);
INSERT INTO `lessons` (`group_id`, `day_of_week`, `pair_number`, `subject`, `teacher`, `room`, `is_cancelled`) VALUES (57, 6, 7, 'МДК.06.01 Внедрение информационных систем', 'Родионова А.А.', '1201', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 0, 1, '08:00:00', '09:30:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 0, 2, '09:40:00', '11:10:00', '40 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 0, 3, '11:50:00', '13:20:00', '20 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 0, 4, '13:40:00', '15:10:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 0, 5, '15:20:00', '16:50:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 0, 6, '17:00:00', '18:30:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 0, 7, '18:40:00', '20:10:00', '', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 1, 1, '08:00:00', '08:30:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 1, 2, '08:35:00', '09:05:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 1, 3, '09:10:00', '09:40:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 1, 4, '09:45:00', '10:15:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 1, 5, '10:20:00', '10:50:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 1, 6, '10:55:00', '11:25:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('week', 1, 7, '11:30:00', '12:00:00', '', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 0, 1, '08:00:00', '09:30:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 0, 2, '09:40:00', '11:10:00', '20 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 0, 3, '11:30:00', '13:00:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 0, 4, '13:10:00', '14:40:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 0, 5, '14:50:00', '16:20:00', '10 мин', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 0, 6, '16:30:00', '18:00:00', '', 1);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 1, 1, '08:00:00', '08:30:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 1, 2, '08:35:00', '09:05:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 1, 3, '09:10:00', '09:40:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 1, 4, '09:45:00', '10:15:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 1, 5, '10:20:00', '10:50:00', '5 мин', 0);
INSERT INTO `bell_schedules` (`day_type`, `is_short`, `pair_number`, `start_time`, `end_time`, `break_text`, `is_active`) VALUES ('sat', 1, 6, '10:55:00', '11:25:00', '', 0);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Аббазова Ф.Ф.', 'Русский язык; Литература', '', '', '', '', '', 0, 1, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Аверьянова В.А.', 'Введение в конфигурирование и программирование в системе 1С; Проектирование и дизайн информационных систем', '', '', '', '', '', 0, 2, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Агзамова Г.Д.', 'Информатика; Компьютерные технологии', 'высшая', '', '', '', '', 0, 3, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Айтыкина Л.Ф.', 'Организационно-правовое обеспечение информационной безопасности; Эксплуатация автоматизированных систем в защищенном исполнении', '', '', '', '', '', 0, 4, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Александров Е.С.', 'Операционные системы и среды; Архитектура аппаратных средств', '1', '', '', '', '', 0, 5, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Андреев В.Д.', 'Эксплуатация объектов сетевой инфраструктуры; Технология выполнения работ; Учебная практика', '1', '', '', '', '', 0, 6, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Андриянова А.Е.', 'Учебная практика; Управление и автоматизация баз данных', '', '', '', '', '', 0, 7, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Антонова Т.С.', 'Электроника и схемотехника; Разработка и прототипирование цифровых систем', '1', '', '', '', '', 0, 8, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Артемьев Е.А.', 'Основы проектирования баз данных; Технология разработки и защиты баз данных; СУБД', '', '', '', '', '', 0, 9, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Аширова Н.Т.', 'Иностранный язык', 'СЗД', '', '', '', '', 0, 10, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Бабченко Т.Н.', 'Физика', 'высшая', '', '', '', '', 0, 11, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Багаутдинова Э.З.', 'Механизация процессов на объектах почтовой связи; Автоматизация почтово-кассовых операций', 'высшая', '', '', '', '', 0, 12, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Барышев Э.Е.', 'Основы алгоритмизации и программирования; Разработка программных модулей', '', '', '', '', '', 0, 13, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Бирюкова Ю.В.', 'Русский язык; Литература', 'высшая', '', '', '', '', 0, 14, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Бочкова О.Е.', 'Иностранный язык', 'СЗД', '', '', '', '', 0, 15, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Валиев Р.Р.', 'Конструкции и компоновка ПК; Установка и конфигурирование периферийного оборудования', '1', '', '', '', '', 0, 16, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Валиуллина А.Р.', 'Компьютерные сети', 'высшая', '', '', '', '', 0, 17, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Вальшина М.А.', 'Монтаж и эксплуатация направляющих систем; Введение в специальность', '1', '', '', '', '', 0, 18, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Васильев Е.П.', 'История; Основы философии', 'к.соц.н.', '', '', '', '', 0, 19, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Васильева Е.С.', 'Монтаж и эксплуатация компьютерных сетей; Компьютерные сети', 'высшая, к.пед.н.', '', '', '', '', 0, 20, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Васильева Г.Р.', 'Правовое обеспечение профессиональной деятельности', '1', '', '', '', '', 0, 21, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Вафина Н.А.', 'Математика', '1', '', '', '', '', 0, 22, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Вахитова Л.З.', 'География', '', '', '', '', '', 0, 23, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Вдовин С.В.', 'Физическая культура', 'высшая', '', '', '', '', 0, 24, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Вильданова Г.Р.', 'Иностранный язык', '1', '', '', '', '', 0, 25, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Волчкова К.С.', 'Иностранный язык; История', '1', '', '', '', '', 0, 26, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гаврилова А.А.', 'Защита информации в инфокоммуникационных системах; Техническая защита информации', '', '', '', '', '', 0, 27, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Газизов К.А.', 'Разработка прикладных приложений; Учебная практика', '', '', '', '', '', 0, 28, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гайнанова А.С.', 'Инженерная компьютерная графика; Метрология, стандартизация и сертификация', '1', '', '', '', '', 0, 29, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гайнуллина Ч.И.', 'Инженерная компьютерная графика', '', '', '', '', '', 0, 30, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гайфутдинова Е.И.', 'История; Основы философии', '1', '', '', '', '', 0, 31, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Галеева А.Р.', 'История; Основы философии; Психология общения; Обществознание', 'высшая', '', '', '', '', 0, 32, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гатауллин Н.Р.', 'Оптимизация веб-приложений; Проектирование и разработка веб-приложений', '', '', '', '', '', 0, 33, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гимадиев Н.Р.', 'Основы алгоритмизации и программирования', '', '', '', '', '', 0, 34, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гришина Д.Р.', 'История; Правовое обеспечение профессиональной деятельности; Обществознание', 'высшая', '', '', '', '', 0, 35, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Гумеров Р.К.', 'Безопасность жизнедеятельности', '1', '', '', '', '', 0, 36, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Данилкина Р.С.', 'Графический дизайн и мультимедиа; Веб-дизайн', '', '', '', '', '', 0, 37, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Долгова И.И.', 'Основы программирования и алгоритмизации; Поддержка и тестирование программных модулей; Математика', 'высшая', '', '', '', '', 0, 38, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Доносий И.А.', 'Инструментальные средства разработки ПО; Разработка кода информационных систем', '', '', '', '', '', 0, 39, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Дунаева О.Н.', 'Основы алгоритмизации и программирования; Математическое моделирование', 'СЗД', '', '', '', '', 0, 40, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Журавлёва Л.Н.', 'Основы безопасности и защиты Родины', 'высшая', '', '', '', '', 0, 41, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Загидуллина А.Б.', 'Криптографические средства защиты информации; Учебная практика', '1', '', '', '', '', 0, 42, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Зарипов Р.Р.', 'Разработка кода информационных систем; Проектирование и разработка веб-приложений', 'высшая', '', '', '', '', 0, 43, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Зифарова А.В.', 'Тестирование информационных систем; Проектирование и разработка интерфейсов пользователя', '', '', '', '', '', 0, 44, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Ибрагимова Р.Ф.', 'Элементы высшей математики; Дискретная математика; Теория вероятностей', 'высшая', '', '', '', '', 0, 45, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Ильина Н.А.', 'Математика; Элементы высшей математики', '', '', '', '', '', 0, 46, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Искакова В.В.', 'Электронная техника; Теория электрических цепей', 'СЗД', '', '', '', '', 0, 47, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Калинина Л.Р.', 'Основы программирования и алгоритмизации; Численные методы; Математика', 'высшая', '', '', '', '', 0, 48, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Косолап А.Н.', 'Физическая культура', '', '', '', '', '', 0, 49, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Крохина С.В.', 'Монтаж и эксплуатация компьютерных сетей; Компьютерные сети', '1', '', '', '', '', 0, 50, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Кумышбаева С.А.', 'Введение в специальность; Разработка программных модулей', '', '', '', '', '', 0, 51, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Лапаев М.Д.', 'Обеспечение безопасности веб-приложений; Учебная практика', '', '', '', '', '', 0, 52, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Мавзиева Г.Р.', 'Экономика организации; Основы финансовой грамотности', '1', '', '', '', '', 0, 53, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Мавлекаев Д.Р.', 'Основы проектирования баз данных; Разработка мобильных приложений', 'СЗД', '', '', '', '', 0, 54, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Макеев И.Н.', 'Учебная и производственная практика', 'СЗД', '', '', '', '', 0, 55, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Маннапова Д.Ф.', 'Менеджмент; Маркетинг; Экономика отрасли', 'высшая', '', '', '', '', 0, 56, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Матвеева Е.Ю.', 'Русский язык; Литература', '', '', '', '', '', 0, 57, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Моисеева А.А.', 'Иностранный язык', '1', '', '', '', '', 0, 58, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Набиуллина Д.И.', 'Математика; Дискретная математика', 'высшая', '', '', '', '', 0, 59, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Никулина В.С.', 'Информационные технологии; Информатика', '1', '', '', '', '', 0, 60, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Петров С.Д.', 'Администрирование сетевых операционных систем', 'СЗД', '', '', '', '', 0, 61, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Петрова А.З.', 'Администрирование сетевых операционных систем; Теория электрической связи', 'высшая', '', '', '', '', 0, 62, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Петрова А.Р.', 'Физическая культура', 'СЗД, 1', '', '', '', '', 0, 63, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Раджабов Р.В.', 'Физическая культура', '', '', '', '', '', 0, 64, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Родионова А.А.', 'Введение в конфигурирование и программирование в системе 1С', '1', '', '', '', '', 0, 65, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Сабиров Р.Б.', 'Архитектура аппаратных средств', '', '', '', '', '', 0, 66, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Сабурская В.К.', 'Техническая защита информации', 'СЗД', '', '', '', '', 0, 67, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Садыкова А.Ш.', 'Иностранный язык', '1', '', '', '', '', 0, 68, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Садыкова Н.А.', 'Математика', 'высшая', '', '', '', '', 0, 69, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Самитов Р.Р.', 'Физическая культура', 'СЗД', '', '', '', '', 0, 70, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Сафина Э.Н.', 'Логистика в почтовой связи; Культура делового общения', '', '', '', '', '', 0, 71, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Сергеева Е.А.', 'География; Основы информационной безопасности', '', '', '', '', '', 0, 72, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Тиндина Г.М.', 'Математика', '', '', '', '', '', 0, 73, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Фазлиева Л.Р.', 'Проектирование и дизайн информационных систем; Разработка кода информационных систем', '', '', '', '', '', 0, 74, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Фархуллин И.А.', 'Основы алгоритмизации и программирования; Учебная практика', '', '', '', '', '', 0, 75, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Фархутдинов А.М.', 'Организация администрирования компьютерных систем; Учебная практика', '1', '', '', '', '', 0, 76, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Фролов А.В.', 'Разработка программных модулей; Системное программирование', '', '', '', '', '', 0, 77, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хазиева А.Н.', 'Психология общения', '1', '', '', '', '', 0, 78, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хайруллин Д.И.', 'Проектирование интерфейсов; Графический дизайн и мультимедиа; Веб-приложения', '1', '', '', '', '', 0, 79, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хайруллина Э.И.', 'Основы телекоммуникаций; Электрорадиоизмерения', 'высшая, к.пед.н.', '', '', '', '', 0, 80, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Халиуллина А.Р.', 'Проектирование и разработка веб-приложений', '', '', '', '', '', 0, 81, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Харитонова С.А.', 'Физика', '', '', '', '', '', 0, 82, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хасанова Н.И.', 'Основы радиосвязи; Учебная и производственная практика', 'высшая', '', '', '', '', 0, 83, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хафизова С.Д.', 'Теория электрических цепей; Основы электротехники', 'высшая', '', '', '', '', 0, 84, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хрущева Л.Г.', 'Основы проектирования баз данных; Технология разработки и защиты баз данных', 'высшая', '', '', '', '', 0, 85, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хуснуллина З.М.', 'Родной (татарский) язык', 'высшая, к.пед.н.', '', '', '', '', 0, 86, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Хуснутдинова Л.Г.', 'Основы безопасности и защиты Родины; БЖД', '1', '', '', '', '', 0, 87, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Шакурова Л.А.', 'Физическая культура', '1', '', '', '', '', 0, 88, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Шириева Г.М.', 'Родной язык', 'высшая', '', '', '', '', 0, 89, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Широкова А.Н.', 'Информатика; Информационные технологии', '', '', '', '', '', 0, 90, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Шкиндерова И.Н.', 'Химия; Биология', 'высшая', '', '', '', '', 0, 91, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Юсупов Р.Р.', 'Физическая культура', 'высшая', '', '', '', '', 0, 92, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('teachers', 'Ясавеев Р.А.', 'Программирование микроконтроллеров; Учебная и производственная практика', '', '', '', '', '', 0, 93, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('management', 'Багров Юрий Николаевич', 'Директор', '', '214', '', '', 'assets/photos/bagrov.jpg', 0, 94, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('management', 'Тимофеева Оксана Сергеевна', 'Зам. директора по учебно-методической работе', '', '211', '', '', 'assets/photos/timofeeva.jpg', 0, 95, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('management', 'Рамазанова Дамира Акмаловна', 'Зам. директора по НПиД, руководитель Учебного центра', '', '207', '', '', 'assets/photos/ramazanova.jpg', 0, 96, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('management', 'Румянцев Александр Викторович', 'Зам. директора по общим вопросам', '', '204', '', '', 'assets/photos/rumyantsev.jpg', 0, 97, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('management', 'Халикова Арина Айратовна', 'Зам. директора по учебно-воспитательной работе', '', '208', '', '', 'assets/photos/khalikova.jpg', 0, 98, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('management', 'Аюпов Альберт Рашидович', 'Зам. директора по безопасности', '', '203', '', '', 'assets/photos/ayupov.jpg', 0, 99, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('management', 'Маннапова Лейсан Гумеровна', 'Главный бухгалтер', '', '223', '', '', 'assets/photos/mannapova.jpg', 0, 100, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('departments', 'Отделение «Базовая профессиональная подготовка»', '1 курс, все специальности', '', '422', 'Зарипова Лилия Шамилевна', '', 'assets/photos/departments/zaripova.png', 0, 101, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('departments', 'Отделение «Информационные технологии»', '09.02.07', '', '1311', 'Зубкова Алина Сергеевна', '', 'assets/photos/departments/zubkova.jpg', 0, 102, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('departments', 'Отделение «Сетевые технологии»', '09.02.01 / 09.02.06 / 09.02.08', '', '409', 'Агзамова Гульназ Дамировна', '', 'assets/photos/departments/agzamova.jpg', 0, 103, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('departments', 'Отделение «Информационная безопасность и связь»', '10.02.05 / 11.02.12 / 11.02.15', '', '1315', 'Каримова Эльмира Михайловна', '', 'assets/photos/departments/karimova.jpg', 0, 104, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('itcube', 'Носова Алина Фаниловна', 'Руководитель IT-CUBE', '', '307', '', '', '', 1, 105, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('itcube', 'Бархатов Николай Максимович', 'Программирование роботов', '', '', '', '', '', 0, 106, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('itcube', 'Мотыгуллин Имиль Шавкатович', 'Разработка VR/AR приложений', '', '', '', '', '', 0, 107, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('itcube', 'Мурсалимов Динар Ринатович', 'Кибергигиена и большие данные; Системное администрирование', '', '', '', '', '', 0, 108, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('itcube', 'Садриев Вячеслав Эдуардович', 'Программирование на Python', '', '', '', '', '', 0, 109, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('itcube', 'Сазонов Александр Валерьевич', 'Мобильная разработка', '', '', '', '', '', 0, 110, 1);
INSERT INTO `staff` (`category`, `full_name`, `position`, `qualification`, `room`, `department_head`, `description`, `photo_path`, `is_head`, `sort_order`, `is_active`) VALUES ('itcube', 'Ясавеев Руслан Алексеевич', 'Программирование роботов; Программирование на Java', '', '', '', '', '', 0, 111, 1);
INSERT INTO `news` (`category`, `title`, `summary`, `content`, `published_at`, `image_path`, `status`) VALUES ('Достижения', 'Победа в Республиканском турнире по робототехнике!', 'Студент Камиль Ризаев под руководством педагога IT-КУБ Динара Мурсалимова занял 1 место в турнире «Робо-триал».', 'Участники собирали приводную платформу на базе LEGO MINDSTORMS EV3, программировали движение робота, тестировали и отлаживали механизм. Организаторы — Министерство образования и науки РТ и Набережночелнинский политехнический колледж.', '2026-10-30', 'assets/news/robotics.webp', 'published');
INSERT INTO `news` (`category`, `title`, `summary`, `content`, `published_at`, `image_path`, `status`) VALUES ('События', 'МЦК-КТИТС на Kazan Digital Week — 2026', 'Студенты и преподаватели посетили международный форум Kazan Digital Week — 2026.', 'В программе были выступления и обсуждения по темам искусственного интеллекта, цифрового развития и внедрения ИИ в экономику. Участники также побывали на мастер-классах и ярмарке вакансий IT-компаний.', '2026-10-29', 'assets/news/digital-week.jpg', 'published');
INSERT INTO `news` (`category`, `title`, `summary`, `content`, `published_at`, `image_path`, `status`) VALUES ('Поступление', 'Конкурс на 2 вакантных бюджетных места на 2 курсе', 'Открыт конкурс на специальность 09.02.07 «Информационные системы и программирование». Заявления принимаются до 2 ноября включительно.', 'Для подачи заявления необходимо обратиться к заведующей отделением «Информационные технологии» Зубковой Алине Сергеевне. Кабинет 1311, телефон 8 (843) 203-55-55, доб. 332, электронная почта Alina.ZubkovaSer@tatar.ru.', '2026-10-29', '', 'published');
INSERT INTO `news` (`category`, `title`, `summary`, `content`, `published_at`, `image_path`, `status`) VALUES ('Абитуриентам', 'День открытых дверей в МЦК-КТИТС', 'Анонс Дня открытых дверей: знакомство со специальностями, экскурсия по техникуму и музею истории связи РТ, консультации приёмной комиссии.', 'Мероприятие было назначено на 24 октября в 14:00 по адресу: г. Казань, ул. Бари Галеева, д. 3а. В анонсе также представлены правила приёма, важные даты и инструкция по онлайн-подаче документов.', '2026-10-22', 'assets/news/open-day.png', 'published');

-- Фиксируем прежнюю строчную раскладку uk3, uk4 и lk3 в абсолютных координатах.
UPDATE `rooms` AS `r`
JOIN (
  SELECT `id`, `row_y`, `row_height`, `weight`, `previous_weight`, `position`, `room_count`, `total_weight`
  FROM (
    SELECT
      `id`, `row_y`, `row_height`, COALESCE(`weight`, 1) AS `weight`,
      ROW_NUMBER() OVER (PARTITION BY `floor_id`, `row_index` ORDER BY `sort_order`, `id`) AS `position`,
      COUNT(*) OVER (PARTITION BY `floor_id`, `row_index`) AS `room_count`,
      SUM(COALESCE(`weight`, 1)) OVER (PARTITION BY `floor_id`, `row_index`) AS `total_weight`,
      COALESCE(SUM(COALESCE(`weight`, 1)) OVER (
        PARTITION BY `floor_id`, `row_index` ORDER BY `sort_order`, `id`
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
      ), 0) AS `previous_weight`
    FROM `rooms` WHERE `row_index` IS NOT NULL
  ) AS `ranked`
) AS `c` ON `c`.`id` = `r`.`id`
SET
  `r`.`x` = ROUND(40 + `c`.`previous_weight` * ((1160 - 12 * (`c`.`room_count` - 1)) / `c`.`total_weight`) + 12 * (`c`.`position` - 1)),
  `r`.`y` = `c`.`row_y`,
  `r`.`w` = ROUND(`c`.`weight` * ((1160 - 12 * (`c`.`room_count` - 1)) / `c`.`total_weight`)),
  `r`.`h` = `c`.`row_height`,
  `r`.`row_index` = NULL, `r`.`row_y` = NULL, `r`.`row_height` = NULL, `r`.`weight` = NULL;


WHERE `floor_key` <> 'uk1';






INSERT INTO `groups` VALUES (1,'101ИССС',1,'Мулекова Е.Э'),(2,'105ИИС',1,'Шкиндерова И.Н'),(3,'106РИИ',1,'Гаффарова Д.Л'),(4,'111ПЧ',1,'Багаутдинова Э.З'),(5,'115КСК',1,'Харитонова С.А'),(6,'116КСК',1,'Галеева А.Р'),(7,'120РУПО-С',1,'Калинина Л.Р'),(8,'121РУПО-С',1,'Долгова И.И'),(9,'122РУПО-С',1,'Шайхутдинова Э.С'),(10,'123РУПО-1С',1,'Шириева Г.М'),(11,'124РУПО-1С',1,'Лапаев М.Д'),(12,'125ВР',1,'Хайруллин Д.И'),(13,'126ВР',1,'Садыкова А.Ш'),(14,'127ВР',1,'Никулина В.С'),(15,'130ОИБ',1,'Гимадеева К.С'),(16,'135ССА',1,'Кудрявцева О.В'),(17,'201ИССС',2,'Тимохина В.А'),(18,'205ИИС',2,'Гарипова К.И'),(19,'211ПЧ',2,'Сафина Э.Н'),(20,'215КСК',2,'Тиндина Г.М'),(21,'216КСК',2,'Шакурова Л.А'),(22,'220П',2,'Широкова А.Н'),(23,'221П',2,'Садыкова Н.А'),(24,'222П',2,'Гимадеева К.С'),(25,'223СИС',2,'Набиуллина Д.И'),(26,'224СИС',2,'Газизов К.А'),(27,'225СИС',2,'Зиннатуллина З.Р'),(28,'226ВЕБ',2,'Никулина В.С'),(29,'227ВЕБ',2,'Сабенникова М.С'),(30,'228ВЕБ',2,'Зифарова А.В'),(31,'230ОИБ',2,'Бирюкова Ю.В'),(32,'231ОИБ',2,'Каримова Э.М'),(33,'235ССА',2,'Александров Е.С'),(34,'301ИССС',3,'Крохина С.В'),(35,'302ИССС',3,'Васильева Е.С'),(36,'305ИИС',3,'Хазиева А.Н.'),(37,'311ПЧ',3,'Багаутдинова Э.З'),(38,'315КСК',3,'Валиев Р.Р'),(39,'316КСК',3,'Касимова Л.З'),(40,'320П',3,'Садыкова Н.А.'),(41,'321П',3,'Бочкова О.Е'),(42,'323СИС',3,'Кумышбаева С.А.'),(43,'324СИС',3,'Васильева Г.Р'),(44,'325ВЕБ',3,'Фархуллин И.А'),(45,'326ВЕБ',3,'Хайруллин Д.И'),(46,'327ВЕБ',3,'Фазлиева Л.Р.'),(47,'330ОИБ',3,'Моисеева А.А'),(48,'331ОИБ',3,'Сергеева Е.А'),(49,'335ССА',3,'Петрова А.З'),(50,'336ССА',3,'Михайлова Л.И'),(51,'401ИССС',4,'Вильданова Г.Р.'),(52,'402ИССС',4,'Филатова Д.В.'),(53,'415КСК',4,'Агзамова Г.Д.'),(54,'416КСК',4,'Агзамова Г.Д'),(55,'420П',4,'Медведева О.А'),(56,'421П',4,'Зубкова А.С'),(57,'423СИС',4,'Мавлекаев Д.Р'),(58,'424СИС',4,'Гайнуллина Ч.И.'),(59,'425ВЕБ',4,'Зарипов Р.Р.'),(60,'426ВЕБ',4,'Зарипова Л.Ш'),(61,'430ОИБ',4,'Вальшина М.А'),(62,'431ОИБ',4,'Хайруллина Э.И.'),(63,'435ССА',4,'Васильева Е.С.');



















INSERT INTO `floors` VALUES (1,'uk1','1 этаж','Учебный корпус, 1 этаж','1 этаж · Учебный корпус','',0.30,1.00,1),(2,'uk2','2 этаж','Учебный корпус, 2 этаж','2 этаж · Учебный корпус','',0.30,1.00,2),(3,'uk3','3 этаж','Учебный корпус, 3 этаж','3 этаж · Учебный корпус','',0.30,1.00,3),(4,'uk4','4 этаж','Учебный корпус, 4 этаж','4 этаж · Учебный корпус','',0.30,1.00,4),(5,'lk1s','Спортзал','Учебный корпус, спортзал','1 этаж · Спортзал','',0.30,1.00,5),(6,'lk1','1 этаж','Лабораторный корпус, 1 этаж','1 этаж · Лабораторный корпус','',0.30,1.00,6),(7,'lk2','2 этаж','Лабораторный корпус, 2 этаж','2 этаж · Лабораторный корпус','',0.30,1.00,7),(8,'lk3','3 этаж','Лабораторный корпус, 3 этаж','3 этаж · Лабораторный корпус','',0.30,1.00,8);
INSERT INTO `rooms` VALUES (138,8,'1317','1317','aud',NULL,NULL,NULL,NULL,40,210,160,100,2),(139,8,'1315','1315','service',NULL,NULL,NULL,NULL,208,210,60,100,3),(140,8,'1313','1313','aud',NULL,NULL,NULL,NULL,276,210,160,100,4),(142,8,'1311','1311','service',NULL,NULL,NULL,NULL,445,210,60,100,6),(143,8,'1305','1305','aud',NULL,NULL,NULL,NULL,661,210,160,100,7),(144,8,'stairs-e','/','stairs',NULL,NULL,NULL,NULL,830,210,48,100,8),(145,8,'1303','1303','aud',NULL,NULL,NULL,NULL,886,210,166,100,9),(146,8,'1301','1301','aud',NULL,NULL,NULL,NULL,1060,210,140,100,10),(147,8,'stairs-w','/','stairs',NULL,NULL,NULL,NULL,40,410,46,100,11),(148,8,'1318','1318','aud',NULL,NULL,NULL,NULL,98,410,152,100,12),(149,8,'1316','1316','aud',NULL,NULL,NULL,NULL,262,410,152,100,13),(150,8,'1314','1314','aud',NULL,NULL,NULL,NULL,426,410,114,100,14),(151,8,'1312','1312','aud',NULL,NULL,NULL,NULL,552,410,116,100,15),(152,8,'teachers','1310','aud',NULL,NULL,NULL,NULL,680,410,73,100,16),(153,8,'wc-m','.','service',NULL,NULL,NULL,NULL,765,410,57,100,17),(154,8,'wc-f','.','service',NULL,NULL,NULL,NULL,834,410,57,100,18),(155,8,'1304','1304','aud',NULL,NULL,NULL,NULL,903,410,133,100,19),(156,8,'1302','1302','aud',NULL,NULL,NULL,NULL,1048,410,152,100,20),(157,8,'1307','1307','aud',NULL,NULL,NULL,NULL,513,210,140,100,21),(158,7,'1201','Аудитория 1201','aud',NULL,NULL,NULL,NULL,1076,210,124,100,1),(159,7,'1203','Аудитория 1203','aud',NULL,NULL,NULL,NULL,938,210,124,100,2),(160,7,'stairs-e','Лестница','stairs',NULL,NULL,NULL,NULL,854,210,70,100,3),(161,7,'1207-1209','Аудитории 1207–1209 (объединены)','aud',NULL,NULL,NULL,NULL,664,210,176,100,4),(162,7,'1211','ЦИТиП','service',NULL,NULL,NULL,NULL,526,210,124,100,5),(163,7,'1213','Начальник ЦИТиП','service',NULL,NULL,NULL,NULL,388,210,124,100,6),(164,7,'1215','Аудитория 1215','aud',NULL,NULL,NULL,NULL,250,210,124,100,7),(165,7,'1217','Аудитория 1217','aud',NULL,NULL,NULL,NULL,112,210,124,100,8),(166,7,'1219','Аудитория 1219','aud',NULL,NULL,NULL,NULL,40,210,58,100,9),(167,7,'1202','Аудитория 1202','aud',NULL,NULL,NULL,NULL,1094,410,106,100,1),(168,7,'1204','Учебный центр','service',NULL,NULL,NULL,NULL,974,410,106,100,2),(169,7,'wc-m','Мужской туалет','service',NULL,NULL,NULL,NULL,905,410,55,100,3),(170,7,'wc-f','Женский туалет','service',NULL,NULL,NULL,NULL,838,410,55,100,4),(171,7,'1210','Аудитория 1210','aud',NULL,NULL,NULL,NULL,718,410,106,100,5),(172,7,'1212','Зав. учебной практикой · Центр карьеры','service',NULL,NULL,NULL,NULL,598,410,106,100,6),(173,7,'1214','Руководитель учебного центра','service',NULL,NULL,NULL,NULL,478,410,106,100,7),(174,7,'1216','Преподавательская','service',NULL,NULL,NULL,NULL,358,410,106,100,8),(175,7,'1218','Аудитория 1218','aud',NULL,NULL,NULL,NULL,238,410,106,100,9),(176,7,'1220','Аудитория 1220','aud',NULL,NULL,NULL,NULL,118,410,106,100,10),(177,7,'stairs-w','Лестница','stairs',NULL,NULL,NULL,NULL,40,410,66,100,11),(225,3,'324','Аудитория 324','aud',NULL,NULL,NULL,NULL,40,210,122,100,1),(226,3,'322','Аудитория 322','aud',NULL,NULL,NULL,NULL,174,210,122,100,2),(227,3,'wc-m','Мужской туалет','service',NULL,NULL,NULL,NULL,308,210,45,100,3),(228,3,'wc-f','Женский туалет','service',NULL,NULL,NULL,NULL,365,210,45,100,4),(229,3,'stairs-w','Лестница','stairs',NULL,NULL,NULL,NULL,422,210,50,100,5),(230,3,'314','Аудитория 314','aud',NULL,NULL,NULL,NULL,484,210,122,100,6),(231,3,'310','Аудитория 310','aud',NULL,NULL,NULL,NULL,618,210,122,100,7),(232,3,'308','Аудитория 308','aud',NULL,NULL,NULL,NULL,752,210,122,100,8),(233,3,'304','Аудитория 304','aud',NULL,NULL,NULL,NULL,886,210,122,100,9),(234,3,'302','Аудитория 302','aud',NULL,NULL,NULL,NULL,1020,210,122,100,10),(235,3,'stairs-e','Лестница','stairs',NULL,NULL,NULL,NULL,1154,210,50,100,11),(236,3,'321','Аудитория 321','aud',NULL,NULL,NULL,NULL,40,410,118,100,1),(237,3,'319','Преподавательская','service',NULL,NULL,NULL,NULL,170,410,118,100,2),(238,3,'315','Аудитория 315','aud',NULL,NULL,NULL,NULL,300,410,118,100,3),(239,3,'313','Аудитория 313','aud',NULL,NULL,NULL,NULL,430,410,118,100,4),(240,3,'311','Аудитория 311','aud',NULL,NULL,NULL,NULL,560,410,118,100,5),(241,3,'309','Аудитория 309','aud',NULL,NULL,NULL,NULL,690,410,118,100,6),(242,3,'307','Администрация IT-CUBE','service',NULL,NULL,NULL,NULL,820,410,118,100,7),(243,3,'305','Аудитория 305','aud',NULL,NULL,NULL,NULL,950,410,118,100,8),(244,3,'301','Аудитория 301','aud',NULL,NULL,NULL,NULL,1080,410,118,100,9),(245,4,'426','Аудитория 426','aud',NULL,NULL,NULL,NULL,40,210,87,100,1),(246,4,'424','Преподавательская','service',NULL,NULL,NULL,NULL,139,210,87,100,2),(247,4,'422','Зав. отделением','service',NULL,NULL,NULL,NULL,238,210,87,100,3),(248,4,'wc-m','Мужской туалет','service',NULL,NULL,NULL,NULL,337,210,32,100,4),(249,4,'wc-f','Женский туалет','service',NULL,NULL,NULL,NULL,381,210,32,100,5),(250,4,'stairs-w','Лестница','stairs',NULL,NULL,NULL,NULL,425,210,35,100,6),(251,4,'416','Аудитория 416','aud',NULL,NULL,NULL,NULL,472,210,87,100,7),(252,4,'414','Аудитория 414','aud',NULL,NULL,NULL,NULL,571,210,87,100,8),(253,4,'410','Аудитория 410','aud',NULL,NULL,NULL,NULL,670,210,87,100,9),(254,4,'408','Аудитория 408','aud',NULL,NULL,NULL,NULL,769,210,87,100,10),(255,4,'406','Аудитория 406','aud',NULL,NULL,NULL,NULL,868,210,87,100,11),(256,4,'404','Аудитория 404','aud',NULL,NULL,NULL,NULL,967,210,87,100,12),(257,4,'402','Аудитория 402','aud',NULL,NULL,NULL,NULL,1066,210,87,100,13),(258,4,'stairs-e','Лестница','stairs',NULL,NULL,NULL,NULL,1165,210,35,100,14),(259,4,'425','Аудитория 425','aud',NULL,NULL,NULL,NULL,40,410,92,100,1),(260,4,'423','Аудитория 423','aud',NULL,NULL,NULL,NULL,144,410,92,100,2),(261,4,'419','Аудитория 419','aud',NULL,NULL,NULL,NULL,248,410,92,100,3),(262,4,'417','Аудитория 417','aud',NULL,NULL,NULL,NULL,352,410,92,100,4),(263,4,'413','Аудитория 413','aud',NULL,NULL,NULL,NULL,456,410,92,100,5),(264,4,'411','Аудитория 411','aud',NULL,NULL,NULL,NULL,560,410,92,100,6),(265,4,'409','Зав. отделением','service',NULL,NULL,NULL,NULL,664,410,92,100,7),(266,4,'407','Аудитория 407','aud',NULL,NULL,NULL,NULL,768,410,92,100,8),(267,4,'405','Аудитория 405','aud',NULL,NULL,NULL,NULL,872,410,92,100,9),(268,4,'403','Зав. заочной формой обучения','service',NULL,NULL,NULL,NULL,976,410,116,100,10),(269,4,'401','Аудитория 401','aud',NULL,NULL,NULL,NULL,1104,410,92,100,11),(284,6,'pass-uk','Переход в учебный корпус','service',NULL,NULL,NULL,NULL,40,410,79,230,1),(285,6,'stairs-w','Лестница','stairs',NULL,NULL,NULL,NULL,131,410,73,100,2),(286,6,'1117','Малая переговорная','service',NULL,NULL,NULL,NULL,216,410,178,100,3),(287,6,'1119','Аудитория 1119','aud',NULL,NULL,NULL,NULL,406,410,178,100,4),(288,6,'1121','Аудитория 1121','aud',NULL,NULL,NULL,NULL,596,410,178,100,5),(289,6,'1125-1127','Аудитории 1125–1127 (объединены)','aud',NULL,NULL,NULL,NULL,786,410,224,100,6),(290,6,'1129','Аудитория 1129','aud',NULL,NULL,NULL,NULL,1022,410,178,100,7),(291,6,'wc-m','Мужской туалет','service',NULL,NULL,NULL,NULL,216,210,54,100,1),(292,6,'wc-f','Женский туалет','service',NULL,NULL,NULL,NULL,282,210,54,100,2),(293,6,'med-procedure','Процедурный кабинет','service',NULL,NULL,NULL,NULL,348,210,146,100,3),(294,6,'1120','Аудитория 1120','aud',NULL,NULL,NULL,NULL,506,210,146,100,4),(295,6,'1122','Аудитория 1122','aud',NULL,NULL,NULL,NULL,664,210,146,100,5),(296,6,'1124','Аудитория 1124','aud',NULL,NULL,NULL,NULL,822,210,146,100,6),(297,6,'1126','Аудитория 1126','aud',NULL,NULL,NULL,NULL,980,210,146,100,7),(298,6,'stairs-e','Лестница','stairs',NULL,NULL,NULL,NULL,1138,210,60,100,8),(299,5,'pass-uk','Переход в учебный корпус','service',NULL,NULL,NULL,NULL,44,44,80,267,1),(300,5,'trainers','Комната тренажеров','service',NULL,NULL,NULL,NULL,135,180,279,130,2),(301,5,'vent','Венткамера','service',NULL,NULL,NULL,NULL,431,180,151,130,3),(302,5,'inventory','Кладовая спортинвентаря','service',NULL,NULL,NULL,NULL,599,180,220,130,4),(303,5,'sport','Спортивный зал','service',NULL,NULL,NULL,NULL,820,179,380,401,5),(304,5,'pe-head','Кабинет руководителя физической культуры','service',NULL,NULL,NULL,NULL,110,430,180,150,6),(305,5,'pe-staff','Преподавательская физкультуры','service',NULL,NULL,NULL,NULL,302,430,180,150,7),(306,5,'changing-m','Раздевалка мужская','service',NULL,NULL,NULL,NULL,494,430,150,150,8),(307,5,'changing-f','Раздевалка женская','service',NULL,NULL,NULL,NULL,656,430,150,150,9),(308,2,'232','Советник директора по воспитанию; специалист по охране труда','service',NULL,NULL,NULL,NULL,40,210,60,100,1),(309,2,'231','Психолог','service',NULL,NULL,NULL,NULL,112,210,60,100,2),(310,2,'230','Комендант техникума','service',NULL,NULL,NULL,NULL,185,210,60,100,3),(311,2,'222','Отдел кадров','service',NULL,NULL,NULL,NULL,257,210,60,100,4),(312,2,'wc-m','Мужской туалет','service',NULL,NULL,NULL,NULL,329,210,60,100,5),(313,2,'wc-f','Женский туалет','service',NULL,NULL,NULL,NULL,402,210,60,100,6),(314,2,'stairs-w','Лестница','stairs',NULL,NULL,NULL,NULL,474,210,60,100,7),(315,2,'214','Приёмная директора','service',NULL,NULL,NULL,NULL,546,210,60,100,8),(316,2,'212','Зав. учебной части','service',NULL,NULL,NULL,NULL,618,210,60,100,9),(317,2,'208','Зам. директора по воспитательной работе','service',NULL,NULL,NULL,NULL,691,210,60,100,10),(318,2,'206','Приёмная №3','service',NULL,NULL,NULL,NULL,763,210,60,100,11),(319,2,'204','Зам. директора по общим вопросам','service',NULL,NULL,NULL,NULL,835,210,60,100,12),(320,2,'202','Кабинет русского языка и литературы','aud',NULL,NULL,NULL,NULL,908,210,60,100,13),(321,2,'227','Отдел закупок','service',NULL,NULL,NULL,NULL,40,410,73,100,1),(322,2,'225','Юрист-консультант','service',NULL,NULL,NULL,NULL,125,410,73,100,2),(323,2,'223','Главный бухгалтер','service',NULL,NULL,NULL,NULL,211,410,73,100,3),(324,2,'221','Бухгалтерия','service',NULL,NULL,NULL,NULL,296,410,73,100,4),(325,2,'215','Учебная часть','service',NULL,NULL,NULL,NULL,382,410,73,100,5),(326,2,'213','Методисты','service',NULL,NULL,NULL,NULL,467,410,73,100,6),(327,2,'211','Зам. директора по учебной работе','service',NULL,NULL,NULL,NULL,553,410,73,100,7),(328,2,'209','Приёмная (вход в 207 и 211)','service',NULL,NULL,NULL,NULL,638,410,73,100,8),(329,2,'207','Зам. директора по НПиД','service',NULL,NULL,NULL,NULL,724,410,73,100,9),(330,2,'205','Кабинет БЖД','service',NULL,NULL,NULL,NULL,809,410,73,100,10),(331,2,'203','Зам. директора по безопасности','service',NULL,NULL,NULL,NULL,895,410,73,100,11),(332,2,'museum','Музей связи','service',NULL,NULL,NULL,NULL,980,210,220,300,99),(333,1,'conf','Конференц-зал','service',NULL,NULL,NULL,NULL,40,280,240,360,1),(334,1,'stolovaya','Столовая','service',NULL,NULL,NULL,NULL,297,176,221,130,2),(335,1,'stairs-w','Главная лестница','stairs',NULL,NULL,NULL,NULL,527,176,77,130,3),(336,1,'pass-lk','Переход в лабораторный корпус','service',NULL,NULL,NULL,NULL,767,39,67,136,4),(338,1,'garderob','Гардероб','service',NULL,NULL,NULL,NULL,692,415,100,120,6),(339,1,'white','Зал совещаний','service',NULL,NULL,NULL,NULL,800,414,130,120,7),(340,1,'lib','Библиотека','service',NULL,NULL,NULL,NULL,937,180,245,356,8),(341,1,'entrance','Главный вход','service',NULL,NULL,NULL,NULL,594,445,90,90,9);
INSERT INTO `route_nodes` VALUES (495,1,340,360,'corridor',NULL),(496,1,480,360,'corridor',NULL),(497,1,620,360,'corridor',NULL),(498,1,740,360,'corridor',NULL),(499,1,860,360,'corridor',NULL),(500,1,980,360,'corridor',NULL),(501,1,1100,360,'corridor',NULL),(502,1,680,192,'entrance','entrance'),(503,1,567,250,'stairs','stairs-w'),(504,1,785,180,'passage','pass-lk'),(505,1,655,360,'corridor','kiosk'),(506,2,76,362,'corridor','227'),(507,2,70,362,'corridor','232'),(508,2,142,362,'corridor','231'),(509,2,161,362,'corridor','225'),(510,2,215,362,'corridor','230'),(511,2,247,362,'corridor','223'),(512,2,287,362,'corridor','222'),(513,2,332,362,'corridor','221'),(514,2,359,362,'corridor','wc-m'),(515,2,418,362,'corridor','215'),(516,2,432,362,'corridor','wc-f'),(517,2,503,362,'corridor','213'),(518,2,504,362,'stairs','stairs-w'),(519,2,576,362,'corridor','214'),(520,2,589,362,'corridor','211'),(521,2,648,362,'corridor','212'),(522,2,674,362,'corridor','209'),(523,2,721,362,'corridor','208'),(524,2,760,362,'corridor','207'),(525,2,793,362,'corridor','206'),(526,2,845,362,'corridor','205'),(527,2,865,362,'corridor','204'),(528,2,931,362,'corridor','203'),(529,2,938,362,'corridor','202'),(530,2,1090,362,'corridor','museum'),(531,3,99,362,'corridor','321'),(532,3,101,362,'corridor','324'),(533,3,229,362,'corridor','319'),(534,3,235,362,'corridor','322'),(535,3,359,362,'corridor','315'),(536,3,330,362,'corridor','wc-m'),(537,3,387,362,'corridor','wc-f'),(538,3,447,362,'stairs','stairs-w'),(539,3,489,362,'corridor','313'),(540,3,545,362,'corridor','314'),(541,3,619,362,'corridor','311'),(542,3,679,362,'corridor','310'),(543,3,749,362,'corridor','309'),(544,3,813,362,'corridor','308'),(545,3,879,362,'corridor','307'),(546,3,947,362,'corridor','304'),(547,3,1009,362,'corridor','305'),(548,3,1081,362,'corridor','302'),(549,3,1139,362,'corridor','301'),(550,3,1179,362,'stairs','stairs-e'),(551,4,86,362,'corridor','425'),(552,4,83,362,'corridor','426'),(553,4,182,362,'corridor','424'),(554,4,190,362,'corridor','423'),(555,4,281,362,'corridor','422'),(556,4,294,362,'corridor','419'),(557,4,353,362,'corridor','wc-m'),(558,4,398,362,'corridor','417'),(559,4,397,362,'corridor','wc-f'),(560,4,442,362,'stairs','stairs-w'),(561,4,502,362,'corridor','413'),(562,4,515,362,'corridor','416'),(563,4,606,362,'corridor','411'),(564,4,614,362,'corridor','414'),(565,4,710,362,'corridor','409'),(566,4,713,362,'corridor','410'),(567,4,814,362,'corridor','407'),(568,4,812,362,'corridor','408'),(569,4,911,362,'corridor','406'),(570,4,918,362,'corridor','405'),(571,4,1010,362,'corridor','404'),(572,4,1034,362,'corridor','403'),(573,4,1109,362,'corridor','402'),(574,4,1150,362,'corridor','401'),(575,4,1182,362,'stairs','stairs-e'),(576,5,84,362,'passage','pass-uk'),(577,5,200,362,'corridor','pe-head'),(578,5,274,362,'corridor','trainers'),(579,5,392,362,'corridor','pe-staff'),(580,5,506,362,'corridor','vent'),(581,5,569,362,'corridor','changing-m'),(582,5,709,362,'corridor','inventory'),(583,5,731,362,'corridor','changing-f'),(584,5,1010,362,'corridor','sport'),(585,6,79,362,'passage','pass-uk'),(586,6,167,362,'stairs','stairs-w'),(587,6,305,362,'corridor','1117'),(588,6,243,362,'corridor','wc-m'),(589,6,309,362,'corridor','wc-f'),(590,6,421,362,'corridor','med-procedure'),(591,6,495,362,'corridor','1119'),(592,6,579,362,'corridor','1120'),(593,6,685,362,'corridor','1121'),(594,6,737,362,'corridor','1122'),(595,6,898,362,'corridor','1125-1127'),(596,6,895,362,'corridor','1124'),(597,6,1053,362,'corridor','1126'),(598,6,1111,362,'corridor','1129'),(599,6,1168,362,'stairs','stairs-e'),(600,7,69,362,'corridor','1219'),(601,7,73,362,'stairs','stairs-w'),(602,7,174,362,'corridor','1217'),(603,7,171,362,'corridor','1220'),(604,7,291,362,'corridor','1218'),(605,7,312,362,'corridor','1215'),(606,7,411,362,'corridor','1216'),(607,7,450,362,'corridor','1213'),(608,7,531,362,'corridor','1214'),(609,7,588,362,'corridor','1211'),(610,7,651,362,'corridor','1212'),(611,7,752,362,'corridor','1207-1209'),(612,7,771,362,'corridor','1210'),(613,7,865,362,'corridor','wc-f'),(614,7,889,362,'stairs','stairs-e'),(615,7,932,362,'corridor','wc-m'),(616,7,1000,362,'corridor','1203'),(617,7,1027,362,'corridor','1204'),(618,7,1138,362,'corridor','1201'),(619,7,1147,362,'corridor','1202'),(620,8,120,362,'corridor','1317'),(621,8,63,362,'stairs','stairs-w'),(622,8,174,362,'corridor','1318'),(623,8,238,362,'corridor','1315'),(624,8,338,362,'corridor','1316'),(625,8,356,362,'corridor','1313'),(626,8,483,362,'corridor','1314'),(627,8,475,362,'corridor','1311'),(628,8,583,362,'corridor','1307'),(629,8,610,362,'corridor','1312'),(630,8,741,362,'corridor','1305'),(631,8,716,362,'corridor','teachers'),(632,8,793,362,'corridor','wc-m'),(633,8,854,362,'stairs','stairs-e'),(634,8,862,362,'corridor','wc-f'),(635,8,969,362,'corridor','1303'),(636,8,969,362,'corridor','1304'),(637,8,1124,362,'corridor','1302'),(638,8,1130,362,'corridor','1301');
INSERT INTO `route_edges` VALUES (495,496),(503,496),(496,497),(502,497),(504,498),(505,498),(498,499),(499,500),(500,501),(497,505),(506,507),(507,508),(508,509),(509,510),(510,511),(511,512),(512,513),(513,514),(514,515),(515,516),(516,517),(517,518),(518,519),(519,520),(520,521),(521,522),(522,523),(523,524),(524,525),(525,526),(526,527),(527,528),(528,529),(529,530),(531,532),(532,533),(533,534),(534,535),(535,536),(536,537),(537,538),(538,539),(539,540),(540,541),(541,542),(542,543),(543,544),(544,545),(545,546),(546,547),(547,548),(548,549),(549,550),(551,552),(552,553),(553,554),(554,555),(555,556),(556,557),(557,558),(558,559),(559,560),(560,561),(561,562),(562,563),(563,564),(564,565),(565,566),(566,567),(567,568),(568,569),(569,570),(570,571),(571,572),(572,573),(573,574),(574,575),(576,577),(577,578),(578,579),(579,580),(580,581),(581,582),(582,583),(583,584),(585,586),(586,587),(587,588),(588,589),(589,590),(590,591),(591,592),(592,593),(593,594),(594,595),(595,596),(596,597),(597,598),(598,599),(600,601),(601,602),(602,603),(603,604),(604,605),(605,606),(606,607),(607,608),(608,609),(609,610),(610,611),(611,612),(612,613),(613,614),(614,615),(615,616),(616,617),(617,618),(618,619),(620,621),(621,622),(622,623),(623,624),(624,625),(625,626),(626,627),(627,628),(628,629),(629,630),(630,631),(631,632),(632,633),(633,634),(634,635),(635,636),(636,637),(637,638);


-- Дополнительные мероприятия афиши (по мотивам официальных новостей)
INSERT INTO `events` (`title`, `description`, `event_date`, `event_time`, `place`, `room_key`, `status`) VALUES
('День открытых дверей МЦК-КТИТС', 'Приглашаем будущих абитуриентов и родителей: экскурсия по корпусам, знакомство с отделениями и преподавателями, ответы на вопросы о поступлении.', '2026-11-22', '10:00', 'Актовый зал', 'conf', 'published'),
('Финал олимпиады по татарскому языку и литературе', 'Финальный тур республиканской олимпиады среди обучающихся техникумов. Поддержите наших студентов!', '2026-11-20', '14:00', 'Аудитория 305', '305', 'published'),
('Выставка «Навигатор Поступления»', 'Образовательная выставка для абитуриентов: программы обучения МЦК-КТИТС, консультации приёмной комиссии.', '2026-11-25', '12:00', 'Конференц-зал', 'conf', 'published'),
('Семинар наставников «Научные клубы Первых»', 'Региональный семинар наставников проекта «Научные клубы Первых» для педагогов и наставников IT-CUBE.', '2026-11-27', '15:00', 'IT-CUBE, аудитория 307', '307', 'published'),
('Республиканский турнир по робототехнике', 'Соревнования команд техникумов республики по робототехнике. Приходите болеть за команду МЦК-КТИТС!', '2026-11-29', '11:00', 'Спортивный зал', 'sport', 'published');

SET FOREIGN_KEY_CHECKS = 1;

-- Учебная практика: блоки и полная сетка аудиторий дата × пара.
DROP TABLE IF EXISTS `practice_lessons`, `practice_blocks`;
CREATE TABLE IF NOT EXISTS `practice_blocks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` SMALLINT UNSIGNED NOT NULL,
  `module` VARCHAR(180) NOT NULL,
  `specialty` VARCHAR(180) NOT NULL,
  `subgroup` VARCHAR(60) NOT NULL DEFAULT '',
  `teacher` VARCHAR(120) NOT NULL DEFAULT '',
  `date_start` DATE NOT NULL,
  `date_end` DATE NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `ix_practice_blocks_group` (`group_id`,`date_start`,`date_end`),
  CONSTRAINT `fk_practice_blocks_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `practice_lessons` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `block_id` INT UNSIGNED NOT NULL,
  `lesson_date` DATE NOT NULL,
  `pair_number` TINYINT UNSIGNED NOT NULL,
  `room` VARCHAR(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_practice_lesson` (`block_id`,`lesson_date`,`pair_number`),
  CONSTRAINT `fk_practice_lessons_block` FOREIGN KEY (`block_id`) REFERENCES `practice_blocks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

START TRANSACTION;
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (1,(SELECT `id` FROM `groups` WHERE `code`='435'),'ПМ.02 УП.02.01 «Организация сетевого администрирования»','09.02.06 «Сетевое и системное администрирование»','I подгруппа','Фархутдинов А.М.','2026-10-27','2026-11-23',1,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (1,'2026-10-27',1,'1303'),(1,'2026-10-27',2,''),(1,'2026-10-27',3,''),(1,'2026-10-27',4,''),(1,'2026-10-27',5,''),(1,'2026-10-27',6,''),(1,'2026-10-27',7,''),
  (1,'2026-10-28',1,'1301'),(1,'2026-10-28',2,''),(1,'2026-10-28',3,''),(1,'2026-10-28',4,''),(1,'2026-10-28',5,''),(1,'2026-10-28',6,''),(1,'2026-10-28',7,''),
  (1,'2026-10-29',1,'1303'),(1,'2026-10-29',2,''),(1,'2026-10-29',3,''),(1,'2026-10-29',4,''),(1,'2026-10-29',5,''),(1,'2026-10-29',6,''),(1,'2026-10-29',7,''),
  (1,'2026-10-30',1,'1303'),(1,'2026-10-30',2,''),(1,'2026-10-30',3,''),(1,'2026-10-30',4,''),(1,'2026-10-30',5,''),(1,'2026-10-30',6,''),(1,'2026-10-30',7,''),
  (1,'2026-10-31',1,'1217'),(1,'2026-10-31',2,''),(1,'2026-10-31',3,''),(1,'2026-10-31',4,'1217'),(1,'2026-10-31',5,''),(1,'2026-10-31',6,''),(1,'2026-10-31',7,''),
  (1,'2026-11-02',1,'1301'),(1,'2026-11-02',2,''),(1,'2026-11-02',3,''),(1,'2026-11-02',4,'1301'),(1,'2026-11-02',5,''),(1,'2026-11-02',6,''),(1,'2026-11-02',7,''),
  (1,'2026-11-03',1,'1303'),(1,'2026-11-03',2,''),(1,'2026-11-03',3,''),(1,'2026-11-03',4,'1303'),(1,'2026-11-03',5,''),(1,'2026-11-03',6,''),(1,'2026-11-03',7,''),
  (1,'2026-11-04',1,''),(1,'2026-11-04',2,''),(1,'2026-11-04',3,''),(1,'2026-11-04',4,''),(1,'2026-11-04',5,''),(1,'2026-11-04',6,''),(1,'2026-11-04',7,''),
  (1,'2026-11-05',1,'1303'),(1,'2026-11-05',2,''),(1,'2026-11-05',3,''),(1,'2026-11-05',4,'1303'),(1,'2026-11-05',5,''),(1,'2026-11-05',6,''),(1,'2026-11-05',7,''),
  (1,'2026-11-06',1,''),(1,'2026-11-06',2,''),(1,'2026-11-06',3,''),(1,'2026-11-06',4,''),(1,'2026-11-06',5,''),(1,'2026-11-06',6,''),(1,'2026-11-06',7,''),
  (1,'2026-11-07',1,'1217'),(1,'2026-11-07',2,''),(1,'2026-11-07',3,''),(1,'2026-11-07',4,'1217'),(1,'2026-11-07',5,''),(1,'2026-11-07',6,''),(1,'2026-11-07',7,''),
  (1,'2026-11-09',1,'1301'),(1,'2026-11-09',2,''),(1,'2026-11-09',3,''),(1,'2026-11-09',4,'1301'),(1,'2026-11-09',5,''),(1,'2026-11-09',6,''),(1,'2026-11-09',7,''),
  (1,'2026-11-10',1,'1303'),(1,'2026-11-10',2,''),(1,'2026-11-10',3,''),(1,'2026-11-10',4,''),(1,'2026-11-10',5,''),(1,'2026-11-10',6,''),(1,'2026-11-10',7,''),
  (1,'2026-11-11',1,'1301'),(1,'2026-11-11',2,''),(1,'2026-11-11',3,''),(1,'2026-11-11',4,''),(1,'2026-11-11',5,''),(1,'2026-11-11',6,''),(1,'2026-11-11',7,''),
  (1,'2026-11-12',1,'1303'),(1,'2026-11-12',2,''),(1,'2026-11-12',3,''),(1,'2026-11-12',4,''),(1,'2026-11-12',5,''),(1,'2026-11-12',6,''),(1,'2026-11-12',7,''),
  (1,'2026-11-13',1,'1303'),(1,'2026-11-13',2,''),(1,'2026-11-13',3,''),(1,'2026-11-13',4,''),(1,'2026-11-13',5,''),(1,'2026-11-13',6,''),(1,'2026-11-13',7,''),
  (1,'2026-11-14',1,'1217'),(1,'2026-11-14',2,''),(1,'2026-11-14',3,''),(1,'2026-11-14',4,''),(1,'2026-11-14',5,''),(1,'2026-11-14',6,''),(1,'2026-11-14',7,''),
  (1,'2026-11-16',1,'1301'),(1,'2026-11-16',2,''),(1,'2026-11-16',3,''),(1,'2026-11-16',4,''),(1,'2026-11-16',5,''),(1,'2026-11-16',6,''),(1,'2026-11-16',7,''),
  (1,'2026-11-17',1,'1303'),(1,'2026-11-17',2,''),(1,'2026-11-17',3,''),(1,'2026-11-17',4,''),(1,'2026-11-17',5,''),(1,'2026-11-17',6,''),(1,'2026-11-17',7,''),
  (1,'2026-11-18',1,'1301'),(1,'2026-11-18',2,''),(1,'2026-11-18',3,''),(1,'2026-11-18',4,''),(1,'2026-11-18',5,''),(1,'2026-11-18',6,''),(1,'2026-11-18',7,''),
  (1,'2026-11-19',1,'1303'),(1,'2026-11-19',2,''),(1,'2026-11-19',3,''),(1,'2026-11-19',4,''),(1,'2026-11-19',5,''),(1,'2026-11-19',6,''),(1,'2026-11-19',7,''),
  (1,'2026-11-20',1,'1303'),(1,'2026-11-20',2,''),(1,'2026-11-20',3,''),(1,'2026-11-20',4,''),(1,'2026-11-20',5,''),(1,'2026-11-20',6,''),(1,'2026-11-20',7,''),
  (1,'2026-11-21',1,'1217'),(1,'2026-11-21',2,''),(1,'2026-11-21',3,''),(1,'2026-11-21',4,''),(1,'2026-11-21',5,''),(1,'2026-11-21',6,''),(1,'2026-11-21',7,''),
  (1,'2026-11-23',1,'1301'),(1,'2026-11-23',2,''),(1,'2026-11-23',3,''),(1,'2026-11-23',4,''),(1,'2026-11-23',5,''),(1,'2026-11-23',6,''),(1,'2026-11-23',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (2,(SELECT `id` FROM `groups` WHERE `code`='435'),'ПМ.02 УП.02.01 «Организация сетевого администрирования»','09.02.06 «Сетевое и системное администрирование»','II подгруппа','Валиуллина А. Р.','2026-10-27','2026-11-23',2,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (2,'2026-10-27',1,''),(2,'2026-10-27',2,''),(2,'2026-10-27',3,''),(2,'2026-10-27',4,''),(2,'2026-10-27',5,'1217'),(2,'2026-10-27',6,''),(2,'2026-10-27',7,''),
  (2,'2026-10-28',1,''),(2,'2026-10-28',2,''),(2,'2026-10-28',3,''),(2,'2026-10-28',4,''),(2,'2026-10-28',5,'1217'),(2,'2026-10-28',6,''),(2,'2026-10-28',7,''),
  (2,'2026-10-29',1,''),(2,'2026-10-29',2,''),(2,'2026-10-29',3,''),(2,'2026-10-29',4,''),(2,'2026-10-29',5,'1217'),(2,'2026-10-29',6,''),(2,'2026-10-29',7,''),
  (2,'2026-10-30',1,'1217'),(2,'2026-10-30',2,''),(2,'2026-10-30',3,''),(2,'2026-10-30',4,''),(2,'2026-10-30',5,''),(2,'2026-10-30',6,''),(2,'2026-10-30',7,''),
  (2,'2026-10-31',1,'1217'),(2,'2026-10-31',2,''),(2,'2026-10-31',3,''),(2,'2026-10-31',4,'1217'),(2,'2026-10-31',5,''),(2,'2026-10-31',6,''),(2,'2026-10-31',7,''),
  (2,'2026-11-02',1,''),(2,'2026-11-02',2,''),(2,'2026-11-02',3,''),(2,'2026-11-02',4,''),(2,'2026-11-02',5,'1217'),(2,'2026-11-02',6,''),(2,'2026-11-02',7,''),
  (2,'2026-11-03',1,''),(2,'2026-11-03',2,''),(2,'2026-11-03',3,''),(2,'2026-11-03',4,''),(2,'2026-11-03',5,''),(2,'2026-11-03',6,'1217'),(2,'2026-11-03',7,''),
  (2,'2026-11-04',1,''),(2,'2026-11-04',2,''),(2,'2026-11-04',3,''),(2,'2026-11-04',4,''),(2,'2026-11-04',5,''),(2,'2026-11-04',6,''),(2,'2026-11-04',7,''),
  (2,'2026-11-05',1,''),(2,'2026-11-05',2,''),(2,'2026-11-05',3,''),(2,'2026-11-05',4,''),(2,'2026-11-05',5,''),(2,'2026-11-05',6,'1217'),(2,'2026-11-05',7,''),
  (2,'2026-11-06',1,''),(2,'2026-11-06',2,''),(2,'2026-11-06',3,''),(2,'2026-11-06',4,''),(2,'2026-11-06',5,''),(2,'2026-11-06',6,''),(2,'2026-11-06',7,''),
  (2,'2026-11-07',1,'1217'),(2,'2026-11-07',2,''),(2,'2026-11-07',3,''),(2,'2026-11-07',4,'1217'),(2,'2026-11-07',5,''),(2,'2026-11-07',6,''),(2,'2026-11-07',7,''),
  (2,'2026-11-09',1,''),(2,'2026-11-09',2,''),(2,'2026-11-09',3,''),(2,'2026-11-09',4,''),(2,'2026-11-09',5,''),(2,'2026-11-09',6,'1217'),(2,'2026-11-09',7,''),
  (2,'2026-11-10',1,''),(2,'2026-11-10',2,''),(2,'2026-11-10',3,''),(2,'2026-11-10',4,''),(2,'2026-11-10',5,'1217'),(2,'2026-11-10',6,''),(2,'2026-11-10',7,''),
  (2,'2026-11-11',1,''),(2,'2026-11-11',2,''),(2,'2026-11-11',3,''),(2,'2026-11-11',4,''),(2,'2026-11-11',5,'1217'),(2,'2026-11-11',6,''),(2,'2026-11-11',7,''),
  (2,'2026-11-12',1,''),(2,'2026-11-12',2,''),(2,'2026-11-12',3,''),(2,'2026-11-12',4,''),(2,'2026-11-12',5,'1217'),(2,'2026-11-12',6,''),(2,'2026-11-12',7,''),
  (2,'2026-11-13',1,'1217'),(2,'2026-11-13',2,''),(2,'2026-11-13',3,''),(2,'2026-11-13',4,''),(2,'2026-11-13',5,''),(2,'2026-11-13',6,''),(2,'2026-11-13',7,''),
  (2,'2026-11-14',1,'1217'),(2,'2026-11-14',2,''),(2,'2026-11-14',3,''),(2,'2026-11-14',4,'1217'),(2,'2026-11-14',5,''),(2,'2026-11-14',6,''),(2,'2026-11-14',7,''),
  (2,'2026-11-16',1,''),(2,'2026-11-16',2,''),(2,'2026-11-16',3,''),(2,'2026-11-16',4,''),(2,'2026-11-16',5,'1217'),(2,'2026-11-16',6,''),(2,'2026-11-16',7,''),
  (2,'2026-11-17',1,''),(2,'2026-11-17',2,''),(2,'2026-11-17',3,''),(2,'2026-11-17',4,''),(2,'2026-11-17',5,'1217'),(2,'2026-11-17',6,''),(2,'2026-11-17',7,''),
  (2,'2026-11-18',1,''),(2,'2026-11-18',2,''),(2,'2026-11-18',3,''),(2,'2026-11-18',4,''),(2,'2026-11-18',5,'1217'),(2,'2026-11-18',6,''),(2,'2026-11-18',7,''),
  (2,'2026-11-19',1,''),(2,'2026-11-19',2,''),(2,'2026-11-19',3,''),(2,'2026-11-19',4,''),(2,'2026-11-19',5,'1217'),(2,'2026-11-19',6,''),(2,'2026-11-19',7,''),
  (2,'2026-11-20',1,'1217'),(2,'2026-11-20',2,''),(2,'2026-11-20',3,''),(2,'2026-11-20',4,''),(2,'2026-11-20',5,''),(2,'2026-11-20',6,''),(2,'2026-11-20',7,''),
  (2,'2026-11-21',1,'1217'),(2,'2026-11-21',2,''),(2,'2026-11-21',3,''),(2,'2026-11-21',4,'1217'),(2,'2026-11-21',5,''),(2,'2026-11-21',6,''),(2,'2026-11-21',7,''),
  (2,'2026-11-23',1,''),(2,'2026-11-23',2,''),(2,'2026-11-23',3,''),(2,'2026-11-23',4,''),(2,'2026-11-23',5,'1217'),(2,'2026-11-23',6,''),(2,'2026-11-23',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (3,(SELECT `id` FROM `groups` WHERE `code`='415'),'ПМ.04 УП.04.01 «Выполнение работ по одной или нескольким профессиям, должностям служащих»','09.02.01 «Компьютерные системы и комплексы»','','Сабиров Р. Б. и Макеев И. Н.','2026-11-03','2026-11-16',3,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (3,'2026-11-03',1,'1316'),(3,'2026-11-03',2,''),(3,'2026-11-03',3,''),(3,'2026-11-03',4,'1316'),(3,'2026-11-03',5,''),(3,'2026-11-03',6,''),(3,'2026-11-03',7,''),
  (3,'2026-11-04',1,''),(3,'2026-11-04',2,''),(3,'2026-11-04',3,''),(3,'2026-11-04',4,''),(3,'2026-11-04',5,''),(3,'2026-11-04',6,''),(3,'2026-11-04',7,''),
  (3,'2026-11-05',1,'1307'),(3,'2026-11-05',2,''),(3,'2026-11-05',3,''),(3,'2026-11-05',4,'1307'),(3,'2026-11-05',5,''),(3,'2026-11-05',6,''),(3,'2026-11-05',7,''),
  (3,'2026-11-06',1,''),(3,'2026-11-06',2,''),(3,'2026-11-06',3,''),(3,'2026-11-06',4,''),(3,'2026-11-06',5,''),(3,'2026-11-06',6,''),(3,'2026-11-06',7,''),
  (3,'2026-11-07',1,''),(3,'2026-11-07',2,''),(3,'2026-11-07',3,'1307'),(3,'2026-11-07',4,''),(3,'2026-11-07',5,'1307'),(3,'2026-11-07',6,''),(3,'2026-11-07',7,''),
  (3,'2026-11-09',1,''),(3,'2026-11-09',2,''),(3,'2026-11-09',3,''),(3,'2026-11-09',4,''),(3,'2026-11-09',5,''),(3,'2026-11-09',6,'1307'),(3,'2026-11-09',7,''),
  (3,'2026-11-10',1,''),(3,'2026-11-10',2,''),(3,'2026-11-10',3,''),(3,'2026-11-10',4,'1316'),(3,'2026-11-10',5,''),(3,'2026-11-10',6,''),(3,'2026-11-10',7,''),
  (3,'2026-11-11',1,''),(3,'2026-11-11',2,''),(3,'2026-11-11',3,''),(3,'2026-11-11',4,''),(3,'2026-11-11',5,''),(3,'2026-11-11',6,''),(3,'2026-11-11',7,''),
  (3,'2026-11-12',1,''),(3,'2026-11-12',2,''),(3,'2026-11-12',3,''),(3,'2026-11-12',4,''),(3,'2026-11-12',5,''),(3,'2026-11-12',6,''),(3,'2026-11-12',7,''),
  (3,'2026-11-13',1,''),(3,'2026-11-13',2,''),(3,'2026-11-13',3,''),(3,'2026-11-13',4,''),(3,'2026-11-13',5,''),(3,'2026-11-13',6,''),(3,'2026-11-13',7,''),
  (3,'2026-11-14',1,''),(3,'2026-11-14',2,''),(3,'2026-11-14',3,''),(3,'2026-11-14',4,''),(3,'2026-11-14',5,''),(3,'2026-11-14',6,''),(3,'2026-11-14',7,''),
  (3,'2026-11-16',1,''),(3,'2026-11-16',2,''),(3,'2026-11-16',3,''),(3,'2026-11-16',4,''),(3,'2026-11-16',5,''),(3,'2026-11-16',6,''),(3,'2026-11-16',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (4,(SELECT `id` FROM `groups` WHERE `code`='431'),'ПМ.02 УП.02.01 «Защита информации в автоматизированных системах программными и программно-аппаратными средствами»','10.02.05 «ОИБАС»','','Гаврилова А. А.','2026-11-03','2026-11-16',4,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (4,'2026-11-03',1,''),(4,'2026-11-03',2,'1313'),(4,'2026-11-03',3,''),(4,'2026-11-03',4,'1313'),(4,'2026-11-03',5,''),(4,'2026-11-03',6,''),(4,'2026-11-03',7,''),
  (4,'2026-11-04',1,''),(4,'2026-11-04',2,''),(4,'2026-11-04',3,''),(4,'2026-11-04',4,''),(4,'2026-11-04',5,''),(4,'2026-11-04',6,''),(4,'2026-11-04',7,''),
  (4,'2026-11-05',1,''),(4,'2026-11-05',2,''),(4,'2026-11-05',3,''),(4,'2026-11-05',4,''),(4,'2026-11-05',5,'1313'),(4,'2026-11-05',6,''),(4,'2026-11-05',7,''),
  (4,'2026-11-06',1,''),(4,'2026-11-06',2,''),(4,'2026-11-06',3,''),(4,'2026-11-06',4,''),(4,'2026-11-06',5,''),(4,'2026-11-06',6,''),(4,'2026-11-06',7,''),
  (4,'2026-11-07',1,'1313'),(4,'2026-11-07',2,''),(4,'2026-11-07',3,''),(4,'2026-11-07',4,''),(4,'2026-11-07',5,''),(4,'2026-11-07',6,''),(4,'2026-11-07',7,''),
  (4,'2026-11-09',1,''),(4,'2026-11-09',2,''),(4,'2026-11-09',3,'1313'),(4,'2026-11-09',4,'1313'),(4,'2026-11-09',5,''),(4,'2026-11-09',6,''),(4,'2026-11-09',7,''),
  (4,'2026-11-10',1,''),(4,'2026-11-10',2,'1313'),(4,'2026-11-10',3,''),(4,'2026-11-10',4,'1313'),(4,'2026-11-10',5,''),(4,'2026-11-10',6,''),(4,'2026-11-10',7,''),
  (4,'2026-11-11',1,'1313'),(4,'2026-11-11',2,''),(4,'2026-11-11',3,''),(4,'2026-11-11',4,''),(4,'2026-11-11',5,''),(4,'2026-11-11',6,''),(4,'2026-11-11',7,''),
  (4,'2026-11-12',1,''),(4,'2026-11-12',2,''),(4,'2026-11-12',3,''),(4,'2026-11-12',4,''),(4,'2026-11-12',5,''),(4,'2026-11-12',6,'1313'),(4,'2026-11-12',7,''),
  (4,'2026-11-13',1,''),(4,'2026-11-13',2,''),(4,'2026-11-13',3,'1313'),(4,'2026-11-13',4,'1313'),(4,'2026-11-13',5,''),(4,'2026-11-13',6,''),(4,'2026-11-13',7,''),
  (4,'2026-11-14',1,'1313'),(4,'2026-11-14',2,''),(4,'2026-11-14',3,''),(4,'2026-11-14',4,''),(4,'2026-11-14',5,''),(4,'2026-11-14',6,''),(4,'2026-11-14',7,''),
  (4,'2026-11-16',1,''),(4,'2026-11-16',2,''),(4,'2026-11-16',3,'1313'),(4,'2026-11-16',4,''),(4,'2026-11-16',5,'1313'),(4,'2026-11-16',6,''),(4,'2026-11-16',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (5,(SELECT `id` FROM `groups` WHERE `code`='424'),'ПМ.06 «Сопровождение информационных систем»','09.02.07 «Информационные системы и программирование»','','Фархуллин И. А.','2026-11-06','2026-11-16',5,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (5,'2026-11-07',1,''),(5,'2026-11-07',2,''),(5,'2026-11-07',3,''),(5,'2026-11-07',4,''),(5,'2026-11-07',5,'1318'),(5,'2026-11-07',6,'1318'),(5,'2026-11-07',7,'1318'),
  (5,'2026-11-09',1,'1301'),(5,'2026-11-09',2,'1301'),(5,'2026-11-09',3,'1301'),(5,'2026-11-09',4,'1301'),(5,'2026-11-09',5,''),(5,'2026-11-09',6,''),(5,'2026-11-09',7,''),
  (5,'2026-11-10',1,'1220'),(5,'2026-11-10',2,'1220'),(5,'2026-11-10',3,'1220'),(5,'2026-11-10',4,'1220'),(5,'2026-11-10',5,''),(5,'2026-11-10',6,''),(5,'2026-11-10',7,''),
  (5,'2026-11-11',1,''),(5,'2026-11-11',2,''),(5,'2026-11-11',3,''),(5,'2026-11-11',4,''),(5,'2026-11-11',5,'Точка кипения'),(5,'2026-11-11',6,'Точка кипения'),(5,'2026-11-11',7,''),
  (5,'2026-11-12',1,''),(5,'2026-11-12',2,''),(5,'2026-11-12',3,''),(5,'2026-11-12',4,''),(5,'2026-11-12',5,'1301'),(5,'2026-11-12',6,'1301'),(5,'2026-11-12',7,'1301'),
  (5,'2026-11-13',1,''),(5,'2026-11-13',2,''),(5,'2026-11-13',3,''),(5,'2026-11-13',4,''),(5,'2026-11-13',5,''),(5,'2026-11-13',6,'1301'),(5,'2026-11-13',7,'1301'),
  (5,'2026-11-14',1,''),(5,'2026-11-14',2,''),(5,'2026-11-14',3,''),(5,'2026-11-14',4,''),(5,'2026-11-14',5,'1303'),(5,'2026-11-14',6,'1303'),(5,'2026-11-14',7,'1303'),
  (5,'2026-11-16',1,'1301'),(5,'2026-11-16',2,'1301'),(5,'2026-11-16',3,'1301'),(5,'2026-11-16',4,'1301'),(5,'2026-11-16',5,''),(5,'2026-11-16',6,''),(5,'2026-11-16',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (6,(SELECT `id` FROM `groups` WHERE `code`='305'),'ПМ.02 «Сопровождение и схемотехническое обслуживание интеллектуальных интегрированных систем»','09.02.08 «Интеллектуальные интегрированные системы»','','Сабиров Р. Б. и Макеев И. Н.','2026-11-10','2026-11-23',6,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (6,'2026-11-10',1,'1307'),(6,'2026-11-10',2,'1307'),(6,'2026-11-10',3,''),(6,'2026-11-10',4,''),(6,'2026-11-10',5,''),(6,'2026-11-10',6,''),(6,'2026-11-10',7,''),
  (6,'2026-11-11',1,''),(6,'2026-11-11',2,''),(6,'2026-11-11',3,''),(6,'2026-11-11',4,'1301'),(6,'2026-11-11',5,'1301'),(6,'2026-11-11',6,'1301'),(6,'2026-11-11',7,''),
  (6,'2026-11-12',1,''),(6,'2026-11-12',2,'1317'),(6,'2026-11-12',3,'1317'),(6,'2026-11-12',4,'1317'),(6,'2026-11-12',5,'1317'),(6,'2026-11-12',6,''),(6,'2026-11-12',7,''),
  (6,'2026-11-13',1,'1317'),(6,'2026-11-13',2,'1317'),(6,'2026-11-13',3,'1317'),(6,'2026-11-13',4,''),(6,'2026-11-13',5,''),(6,'2026-11-13',6,''),(6,'2026-11-13',7,''),
  (6,'2026-11-14',1,''),(6,'2026-11-14',2,'1317'),(6,'2026-11-14',3,'1317'),(6,'2026-11-14',4,'1317'),(6,'2026-11-14',5,''),(6,'2026-11-14',6,''),(6,'2026-11-14',7,''),
  (6,'2026-11-16',1,'1317'),(6,'2026-11-16',2,'1317'),(6,'2026-11-16',3,'1317'),(6,'2026-11-16',4,''),(6,'2026-11-16',5,''),(6,'2026-11-16',6,''),(6,'2026-11-16',7,''),
  (6,'2026-11-17',1,'1307'),(6,'2026-11-17',2,'1307'),(6,'2026-11-17',3,''),(6,'2026-11-17',4,''),(6,'2026-11-17',5,''),(6,'2026-11-17',6,''),(6,'2026-11-17',7,''),
  (6,'2026-11-18',1,''),(6,'2026-11-18',2,''),(6,'2026-11-18',3,''),(6,'2026-11-18',4,'1301'),(6,'2026-11-18',5,'1301'),(6,'2026-11-18',6,'1301'),(6,'2026-11-18',7,''),
  (6,'2026-11-19',1,''),(6,'2026-11-19',2,'1317'),(6,'2026-11-19',3,'1317'),(6,'2026-11-19',4,'1317'),(6,'2026-11-19',5,'1317'),(6,'2026-11-19',6,''),(6,'2026-11-19',7,''),
  (6,'2026-11-20',1,'1317'),(6,'2026-11-20',2,'1317'),(6,'2026-11-20',3,'1317'),(6,'2026-11-20',4,''),(6,'2026-11-20',5,''),(6,'2026-11-20',6,''),(6,'2026-11-20',7,''),
  (6,'2026-11-21',1,''),(6,'2026-11-21',2,'1317'),(6,'2026-11-21',3,'1317'),(6,'2026-11-21',4,'1317'),(6,'2026-11-21',5,''),(6,'2026-11-21',6,''),(6,'2026-11-21',7,''),
  (6,'2026-11-23',1,'1317'),(6,'2026-11-23',2,'1317'),(6,'2026-11-23',3,'1317'),(6,'2026-11-23',4,''),(6,'2026-11-23',5,''),(6,'2026-11-23',6,''),(6,'2026-11-23',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (7,(SELECT `id` FROM `groups` WHERE `code`='320'),'ПМ.11 «Разработка, администрирование и защита баз данных»','09.02.07 «Информационные системы и программирование»','','Артемьев Е. А.','2026-11-10','2026-11-23',7,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (7,'2026-11-10',1,'1220'),(7,'2026-11-10',2,'1220'),(7,'2026-11-10',3,'1220'),(7,'2026-11-10',4,''),(7,'2026-11-10',5,''),(7,'2026-11-10',6,''),(7,'2026-11-10',7,''),
  (7,'2026-11-11',1,'1220'),(7,'2026-11-11',2,'1220'),(7,'2026-11-11',3,'1220'),(7,'2026-11-11',4,''),(7,'2026-11-11',5,''),(7,'2026-11-11',6,''),(7,'2026-11-11',7,''),
  (7,'2026-11-12',1,''),(7,'2026-11-12',2,''),(7,'2026-11-12',3,''),(7,'2026-11-12',4,''),(7,'2026-11-12',5,''),(7,'2026-11-12',6,'1220'),(7,'2026-11-12',7,'1220'),
  (7,'2026-11-13',1,'1220'),(7,'2026-11-13',2,'1220'),(7,'2026-11-13',3,'1220'),(7,'2026-11-13',4,'1220'),(7,'2026-11-13',5,''),(7,'2026-11-13',6,''),(7,'2026-11-13',7,''),
  (7,'2026-11-14',1,'1220'),(7,'2026-11-14',2,'1220'),(7,'2026-11-14',3,'1220'),(7,'2026-11-14',4,''),(7,'2026-11-14',5,''),(7,'2026-11-14',6,''),(7,'2026-11-14',7,''),
  (7,'2026-11-16',1,'1220'),(7,'2026-11-16',2,'1220'),(7,'2026-11-16',3,'1220'),(7,'2026-11-16',4,''),(7,'2026-11-16',5,''),(7,'2026-11-16',6,''),(7,'2026-11-16',7,''),
  (7,'2026-11-17',1,'1220'),(7,'2026-11-17',2,'1220'),(7,'2026-11-17',3,'1220'),(7,'2026-11-17',4,''),(7,'2026-11-17',5,''),(7,'2026-11-17',6,''),(7,'2026-11-17',7,''),
  (7,'2026-11-18',1,'1220'),(7,'2026-11-18',2,'1220'),(7,'2026-11-18',3,'1220'),(7,'2026-11-18',4,''),(7,'2026-11-18',5,''),(7,'2026-11-18',6,''),(7,'2026-11-18',7,''),
  (7,'2026-11-19',1,''),(7,'2026-11-19',2,''),(7,'2026-11-19',3,''),(7,'2026-11-19',4,''),(7,'2026-11-19',5,''),(7,'2026-11-19',6,'1220'),(7,'2026-11-19',7,'1220'),
  (7,'2026-11-20',1,'1220'),(7,'2026-11-20',2,'1220'),(7,'2026-11-20',3,'1220'),(7,'2026-11-20',4,'1220'),(7,'2026-11-20',5,''),(7,'2026-11-20',6,''),(7,'2026-11-20',7,''),
  (7,'2026-11-21',1,'1220'),(7,'2026-11-21',2,'1220'),(7,'2026-11-21',3,'1220'),(7,'2026-11-21',4,''),(7,'2026-11-21',5,''),(7,'2026-11-21',6,''),(7,'2026-11-21',7,''),
  (7,'2026-11-23',1,'1220'),(7,'2026-11-23',2,'1220'),(7,'2026-11-23',3,'1220'),(7,'2026-11-23',4,''),(7,'2026-11-23',5,''),(7,'2026-11-23',6,''),(7,'2026-11-23',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (8,(SELECT `id` FROM `groups` WHERE `code`='320'),'ПМ.11 «Разработка, администрирование и защита баз данных»','09.02.07 «Информационные системы и программирование»','','Мавлекаев Д. Р.','2026-11-10','2026-11-23',8,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (8,'2026-11-10',1,''),(8,'2026-11-10',2,''),(8,'2026-11-10',3,''),(8,'2026-11-10',4,'1318'),(8,'2026-11-10',5,'1318'),(8,'2026-11-10',6,'1318'),(8,'2026-11-10',7,''),
  (8,'2026-11-11',1,'1220'),(8,'2026-11-11',2,'1220'),(8,'2026-11-11',3,''),(8,'2026-11-11',4,''),(8,'2026-11-11',5,''),(8,'2026-11-11',6,''),(8,'2026-11-11',7,''),
  (8,'2026-11-12',1,''),(8,'2026-11-12',2,''),(8,'2026-11-12',3,'1215'),(8,'2026-11-12',4,'1215'),(8,'2026-11-12',5,'1215'),(8,'2026-11-12',6,'1215'),(8,'2026-11-12',7,''),
  (8,'2026-11-13',1,''),(8,'2026-11-13',2,''),(8,'2026-11-13',3,''),(8,'2026-11-13',4,''),(8,'2026-11-13',5,'1318'),(8,'2026-11-13',6,'1318'),(8,'2026-11-13',7,'1318'),
  (8,'2026-11-14',1,''),(8,'2026-11-14',2,''),(8,'2026-11-14',3,''),(8,'2026-11-14',4,'1318'),(8,'2026-11-14',5,'1318'),(8,'2026-11-14',6,'1318'),(8,'2026-11-14',7,''),
  (8,'2026-11-16',1,''),(8,'2026-11-16',2,''),(8,'2026-11-16',3,''),(8,'2026-11-16',4,''),(8,'2026-11-16',5,'1318'),(8,'2026-11-16',6,'1318'),(8,'2026-11-16',7,'1318'),
  (8,'2026-11-17',1,''),(8,'2026-11-17',2,''),(8,'2026-11-17',3,''),(8,'2026-11-17',4,'1318'),(8,'2026-11-17',5,'1318'),(8,'2026-11-17',6,'1318'),(8,'2026-11-17',7,''),
  (8,'2026-11-18',1,'1220'),(8,'2026-11-18',2,'1220'),(8,'2026-11-18',3,''),(8,'2026-11-18',4,''),(8,'2026-11-18',5,''),(8,'2026-11-18',6,''),(8,'2026-11-18',7,''),
  (8,'2026-11-19',1,''),(8,'2026-11-19',2,''),(8,'2026-11-19',3,'1215'),(8,'2026-11-19',4,'1215'),(8,'2026-11-19',5,'1215'),(8,'2026-11-19',6,'1215'),(8,'2026-11-19',7,''),
  (8,'2026-11-20',1,''),(8,'2026-11-20',2,''),(8,'2026-11-20',3,''),(8,'2026-11-20',4,''),(8,'2026-11-20',5,'1318'),(8,'2026-11-20',6,'1318'),(8,'2026-11-20',7,'1318'),
  (8,'2026-11-21',1,''),(8,'2026-11-21',2,''),(8,'2026-11-21',3,''),(8,'2026-11-21',4,'1318'),(8,'2026-11-21',5,'1318'),(8,'2026-11-21',6,'1318'),(8,'2026-11-21',7,''),
  (8,'2026-11-23',1,''),(8,'2026-11-23',2,''),(8,'2026-11-23',3,''),(8,'2026-11-23',4,''),(8,'2026-11-23',5,'1318'),(8,'2026-11-23',6,'1318'),(8,'2026-11-23',7,'1318');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (9,(SELECT `id` FROM `groups` WHERE `code`='327'),'ПМ.08 «Разработка дизайна веб-приложений»','09.02.07 «Информационные системы и программирование»','','Лапаев М. Д. и Хабибуллина Л. Р.','2026-11-10','2026-11-23',9,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (9,'2026-11-10',1,'1317'),(9,'2026-11-10',2,'1317'),(9,'2026-11-10',3,''),(9,'2026-11-10',4,''),(9,'2026-11-10',5,''),(9,'2026-11-10',6,''),(9,'2026-11-10',7,''),
  (9,'2026-11-11',1,''),(9,'2026-11-11',2,''),(9,'2026-11-11',3,'Точка кипения'),(9,'2026-11-11',4,'Точка кипения'),(9,'2026-11-11',5,''),(9,'2026-11-11',6,''),(9,'2026-11-11',7,''),
  (9,'2026-11-12',1,''),(9,'2026-11-12',2,''),(9,'2026-11-12',3,'1124'),(9,'2026-11-12',4,'1124'),(9,'2026-11-12',5,'1124'),(9,'2026-11-12',6,''),(9,'2026-11-12',7,''),
  (9,'2026-11-13',1,''),(9,'2026-11-13',2,'Точка кипения'),(9,'2026-11-13',3,'Точка кипения'),(9,'2026-11-13',4,''),(9,'2026-11-13',5,''),(9,'2026-11-13',6,''),(9,'2026-11-13',7,''),
  (9,'2026-11-14',1,'1124'),(9,'2026-11-14',2,'1124'),(9,'2026-11-14',3,'1124'),(9,'2026-11-14',4,''),(9,'2026-11-14',5,''),(9,'2026-11-14',6,''),(9,'2026-11-14',7,''),
  (9,'2026-11-16',1,'1307'),(9,'2026-11-16',2,'1307'),(9,'2026-11-16',3,'1307'),(9,'2026-11-16',4,''),(9,'2026-11-16',5,''),(9,'2026-11-16',6,''),(9,'2026-11-16',7,''),
  (9,'2026-11-17',1,'1301'),(9,'2026-11-17',2,'1301'),(9,'2026-11-17',3,''),(9,'2026-11-17',4,''),(9,'2026-11-17',5,''),(9,'2026-11-17',6,''),(9,'2026-11-17',7,''),
  (9,'2026-11-18',1,''),(9,'2026-11-18',2,''),(9,'2026-11-18',3,'Точка кипения'),(9,'2026-11-18',4,'Точка кипения'),(9,'2026-11-18',5,''),(9,'2026-11-18',6,''),(9,'2026-11-18',7,''),
  (9,'2026-11-19',1,''),(9,'2026-11-19',2,''),(9,'2026-11-19',3,'1124'),(9,'2026-11-19',4,'1124'),(9,'2026-11-19',5,'1124'),(9,'2026-11-19',6,''),(9,'2026-11-19',7,''),
  (9,'2026-11-20',1,''),(9,'2026-11-20',2,'Точка кипения'),(9,'2026-11-20',3,'Точка кипения'),(9,'2026-11-20',4,''),(9,'2026-11-20',5,''),(9,'2026-11-20',6,''),(9,'2026-11-20',7,''),
  (9,'2026-11-21',1,'1124'),(9,'2026-11-21',2,'1124'),(9,'2026-11-21',3,'1124'),(9,'2026-11-21',4,''),(9,'2026-11-21',5,''),(9,'2026-11-21',6,''),(9,'2026-11-21',7,''),
  (9,'2026-11-23',1,'1307'),(9,'2026-11-23',2,'1307'),(9,'2026-11-23',3,'1307'),(9,'2026-11-23',4,''),(9,'2026-11-23',5,''),(9,'2026-11-23',6,''),(9,'2026-11-23',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (10,(SELECT `id` FROM `groups` WHERE `code`='401'),'ПМ.05 «Адаптация конвергентных технологий и систем к потребностям заказчика»','11.02.15 «Инфокоммуникационные сети и системы связи»','I подгруппа','Васильева Е. С.','2026-11-10','2026-11-16',10,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (10,'2026-11-10',1,''),(10,'2026-11-10',2,''),(10,'2026-11-10',3,'1201'),(10,'2026-11-10',4,'1201'),(10,'2026-11-10',5,'1201'),(10,'2026-11-10',6,''),(10,'2026-11-10',7,''),
  (10,'2026-11-11',1,'1201'),(10,'2026-11-11',2,'1201'),(10,'2026-11-11',3,'1201'),(10,'2026-11-11',4,''),(10,'2026-11-11',5,''),(10,'2026-11-11',6,''),(10,'2026-11-11',7,''),
  (10,'2026-11-12',1,''),(10,'2026-11-12',2,''),(10,'2026-11-12',3,''),(10,'2026-11-12',4,''),(10,'2026-11-12',5,'1201'),(10,'2026-11-12',6,'1201'),(10,'2026-11-12',7,''),
  (10,'2026-11-13',1,'1201'),(10,'2026-11-13',2,'1201'),(10,'2026-11-13',3,''),(10,'2026-11-13',4,''),(10,'2026-11-13',5,''),(10,'2026-11-13',6,''),(10,'2026-11-13',7,''),
  (10,'2026-11-14',1,'1201'),(10,'2026-11-14',2,'1201'),(10,'2026-11-14',3,'1201'),(10,'2026-11-14',4,'1201'),(10,'2026-11-14',5,''),(10,'2026-11-14',6,''),(10,'2026-11-14',7,''),
  (10,'2026-11-16',1,''),(10,'2026-11-16',2,''),(10,'2026-11-16',3,'1201'),(10,'2026-11-16',4,'1201'),(10,'2026-11-16',5,'1201'),(10,'2026-11-16',6,'1201'),(10,'2026-11-16',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (11,(SELECT `id` FROM `groups` WHERE `code`='401'),'ПМ.05 «Адаптация конвергентных технологий и систем к потребностям заказчика»','11.02.15 «Инфокоммуникационные сети и системы связи»','II подгруппа','Крохина С. В.','2026-11-10','2026-11-16',11,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (11,'2026-11-10',1,'1203'),(11,'2026-11-10',2,'1203'),(11,'2026-11-10',3,'1203'),(11,'2026-11-10',4,''),(11,'2026-11-10',5,''),(11,'2026-11-10',6,''),(11,'2026-11-10',7,''),
  (11,'2026-11-11',1,'1203'),(11,'2026-11-11',2,'1203'),(11,'2026-11-11',3,''),(11,'2026-11-11',4,''),(11,'2026-11-11',5,''),(11,'2026-11-11',6,''),(11,'2026-11-11',7,''),
  (11,'2026-11-12',1,''),(11,'2026-11-12',2,''),(11,'2026-11-12',3,''),(11,'2026-11-12',4,''),(11,'2026-11-12',5,'1203'),(11,'2026-11-12',6,'1203'),(11,'2026-11-12',7,'1203'),
  (11,'2026-11-13',1,''),(11,'2026-11-13',2,''),(11,'2026-11-13',3,''),(11,'2026-11-13',4,'1203'),(11,'2026-11-13',5,'1203'),(11,'2026-11-13',6,'1203'),(11,'2026-11-13',7,'1203'),
  (11,'2026-11-14',1,''),(11,'2026-11-14',2,''),(11,'2026-11-14',3,''),(11,'2026-11-14',4,''),(11,'2026-11-14',5,''),(11,'2026-11-14',6,'1203'),(11,'2026-11-14',7,'1203'),
  (11,'2026-11-16',1,'1203'),(11,'2026-11-16',2,'1203'),(11,'2026-11-16',3,'1203'),(11,'2026-11-16',4,'1203'),(11,'2026-11-16',5,''),(11,'2026-11-16',6,''),(11,'2026-11-16',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (12,(SELECT `id` FROM `groups` WHERE `code`='402'),'ПМ.03 «Обеспечение информационной безопасности инфокоммуникационных сетей и систем связи»','11.02.15 «Инфокоммуникационные сети и системы связи»','','Тимохина В. А.','2026-11-10','2026-11-16',12,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (12,'2026-11-10',1,''),(12,'2026-11-10',2,''),(12,'2026-11-10',3,''),(12,'2026-11-10',4,'1220'),(12,'2026-11-10',5,'1220'),(12,'2026-11-10',6,'1220'),(12,'2026-11-10',7,''),
  (12,'2026-11-11',1,'1317'),(12,'2026-11-11',2,'1317'),(12,'2026-11-11',3,''),(12,'2026-11-11',4,''),(12,'2026-11-11',5,''),(12,'2026-11-11',6,''),(12,'2026-11-11',7,''),
  (12,'2026-11-12',1,''),(12,'2026-11-12',2,''),(12,'2026-11-12',3,''),(12,'2026-11-12',4,'1312'),(12,'2026-11-12',5,'1312'),(12,'2026-11-12',6,''),(12,'2026-11-12',7,''),
  (12,'2026-11-13',1,''),(12,'2026-11-13',2,''),(12,'2026-11-13',3,'1314'),(12,'2026-11-13',4,'1314'),(12,'2026-11-13',5,'1314'),(12,'2026-11-13',6,'1314'),(12,'2026-11-13',7,''),
  (12,'2026-11-14',1,''),(12,'2026-11-14',2,''),(12,'2026-11-14',3,'1314'),(12,'2026-11-14',4,'1314'),(12,'2026-11-14',5,'1314'),(12,'2026-11-14',6,''),(12,'2026-11-14',7,''),
  (12,'2026-11-16',1,''),(12,'2026-11-16',2,''),(12,'2026-11-16',3,''),(12,'2026-11-16',4,'1314'),(12,'2026-11-16',5,'1314'),(12,'2026-11-16',6,'1314'),(12,'2026-11-16',7,'1314');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (13,(SELECT `id` FROM `groups` WHERE `code`='415'),'ПМ.02 «Проектирование управляющих программ компьютерных систем и комплексов»','09.02.01 «Компьютерные системы и комплексы»','I подгруппа','Царев К. В., Макеев И.Н.','2026-11-10','2026-11-23',13,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (13,'2026-11-10',1,''),(13,'2026-11-10',2,''),(13,'2026-11-10',3,'1307'),(13,'2026-11-10',4,'УП04 (1307)'),(13,'2026-11-10',5,'УП.04 (1307)'),(13,'2026-11-10',6,''),(13,'2026-11-10',7,''),
  (13,'2026-11-11',1,'1307'),(13,'2026-11-11',2,'1307'),(13,'2026-11-11',3,'1307'),(13,'2026-11-11',4,'1307 вся группа'),(13,'2026-11-11',5,''),(13,'2026-11-11',6,''),(13,'2026-11-11',7,''),
  (13,'2026-11-12',1,'1307'),(13,'2026-11-12',2,'1307'),(13,'2026-11-12',3,'1307'),(13,'2026-11-12',4,'1307'),(13,'2026-11-12',5,''),(13,'2026-11-12',6,''),(13,'2026-11-12',7,''),
  (13,'2026-11-13',1,''),(13,'2026-11-13',2,''),(13,'2026-11-13',3,''),(13,'2026-11-13',4,'1307'),(13,'2026-11-13',5,'1307'),(13,'2026-11-13',6,'1307'),(13,'2026-11-13',7,''),
  (13,'2026-11-14',1,''),(13,'2026-11-14',2,''),(13,'2026-11-14',3,'1303'),(13,'2026-11-14',4,'1303'),(13,'2026-11-14',5,''),(13,'2026-11-14',6,''),(13,'2026-11-14',7,''),
  (13,'2026-11-16',1,'402'),(13,'2026-11-16',2,'402'),(13,'2026-11-16',3,'402'),(13,'2026-11-16',4,'402'),(13,'2026-11-16',5,''),(13,'2026-11-16',6,''),(13,'2026-11-16',7,''),
  (13,'2026-11-17',1,'1316'),(13,'2026-11-17',2,'1316'),(13,'2026-11-17',3,'1316'),(13,'2026-11-17',4,''),(13,'2026-11-17',5,''),(13,'2026-11-17',6,''),(13,'2026-11-17',7,''),
  (13,'2026-11-18',1,'1307'),(13,'2026-11-18',2,'1307'),(13,'2026-11-18',3,'1307'),(13,'2026-11-18',4,''),(13,'2026-11-18',5,''),(13,'2026-11-18',6,''),(13,'2026-11-18',7,''),
  (13,'2026-11-19',1,''),(13,'2026-11-19',2,''),(13,'2026-11-19',3,'1307'),(13,'2026-11-19',4,'1307'),(13,'2026-11-19',5,''),(13,'2026-11-19',6,''),(13,'2026-11-19',7,''),
  (13,'2026-11-20',1,''),(13,'2026-11-20',2,''),(13,'2026-11-20',3,''),(13,'2026-11-20',4,'1307'),(13,'2026-11-20',5,'1307'),(13,'2026-11-20',6,'1307'),(13,'2026-11-20',7,''),
  (13,'2026-11-21',1,''),(13,'2026-11-21',2,''),(13,'2026-11-21',3,''),(13,'2026-11-21',4,''),(13,'2026-11-21',5,'1303'),(13,'2026-11-21',6,'1303'),(13,'2026-11-21',7,'1303'),
  (13,'2026-11-23',1,'402'),(13,'2026-11-23',2,'402'),(13,'2026-11-23',3,'402'),(13,'2026-11-23',4,'402'),(13,'2026-11-23',5,''),(13,'2026-11-23',6,''),(13,'2026-11-23',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (14,(SELECT `id` FROM `groups` WHERE `code`='415'),'ПМ.02 «Проектирование управляющих программ компьютерных систем и комплексов»','09.02.01 «Компьютерные системы и комплексы»','II подгруппа','Царев К. В., Макеев И.Н.','2026-11-10','2026-11-23',14,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (14,'2026-11-10',1,''),(14,'2026-11-10',2,''),(14,'2026-11-10',3,'1307'),(14,'2026-11-10',4,'УП04 (1307)'),(14,'2026-11-10',5,'УП.04 (1307)'),(14,'2026-11-10',6,'1307'),(14,'2026-11-10',7,'1307'),
  (14,'2026-11-11',1,''),(14,'2026-11-11',2,''),(14,'2026-11-11',3,''),(14,'2026-11-11',4,'1307 вся группа'),(14,'2026-11-11',5,'1307'),(14,'2026-11-11',6,'1307'),(14,'2026-11-11',7,'1307'),
  (14,'2026-11-12',1,'1307'),(14,'2026-11-12',2,'1307'),(14,'2026-11-12',3,'1307'),(14,'2026-11-12',4,'1307'),(14,'2026-11-12',5,''),(14,'2026-11-12',6,''),(14,'2026-11-12',7,''),
  (14,'2026-11-13',1,''),(14,'2026-11-13',2,''),(14,'2026-11-13',3,''),(14,'2026-11-13',4,'1307'),(14,'2026-11-13',5,'1307'),(14,'2026-11-13',6,'1307'),(14,'2026-11-13',7,''),
  (14,'2026-11-14',1,''),(14,'2026-11-14',2,''),(14,'2026-11-14',3,''),(14,'2026-11-14',4,''),(14,'2026-11-14',5,''),(14,'2026-11-14',6,'1303'),(14,'2026-11-14',7,'1303'),
  (14,'2026-11-16',1,''),(14,'2026-11-16',2,''),(14,'2026-11-16',3,''),(14,'2026-11-16',4,''),(14,'2026-11-16',5,'402'),(14,'2026-11-16',6,'402'),(14,'2026-11-16',7,'402'),
  (14,'2026-11-17',1,'1316'),(14,'2026-11-17',2,'1316'),(14,'2026-11-17',3,'1316'),(14,'2026-11-17',4,''),(14,'2026-11-17',5,''),(14,'2026-11-17',6,''),(14,'2026-11-17',7,''),
  (14,'2026-11-18',1,''),(14,'2026-11-18',2,''),(14,'2026-11-18',3,''),(14,'2026-11-18',4,'1307'),(14,'2026-11-18',5,'1307'),(14,'2026-11-18',6,'1307'),(14,'2026-11-18',7,'1307'),
  (14,'2026-11-19',1,'1307'),(14,'2026-11-19',2,'1307'),(14,'2026-11-19',3,'1307 вся группа'),(14,'2026-11-19',4,'1307 вся группа'),(14,'2026-11-19',5,''),(14,'2026-11-19',6,''),(14,'2026-11-19',7,''),
  (14,'2026-11-20',1,''),(14,'2026-11-20',2,''),(14,'2026-11-20',3,''),(14,'2026-11-20',4,''),(14,'2026-11-20',5,''),(14,'2026-11-20',6,'1307'),(14,'2026-11-20',7,'1307'),
  (14,'2026-11-21',1,''),(14,'2026-11-21',2,''),(14,'2026-11-21',3,'1303'),(14,'2026-11-21',4,'1303'),(14,'2026-11-21',5,''),(14,'2026-11-21',6,''),(14,'2026-11-21',7,''),
  (14,'2026-11-23',1,''),(14,'2026-11-23',2,''),(14,'2026-11-23',3,''),(14,'2026-11-23',4,''),(14,'2026-11-23',5,'402'),(14,'2026-11-23',6,'402'),(14,'2026-11-23',7,'402');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (15,(SELECT `id` FROM `groups` WHERE `code`='425'),'ПМ.05 «Проектирование и разработка информационных систем»','09.02.07 «Информационные системы и программирование»','','Зарипов Р. Р.','2026-11-10','2026-11-16',15,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (15,'2026-11-10',1,'1304'),(15,'2026-11-10',2,'1304'),(15,'2026-11-10',3,'1304'),(15,'2026-11-10',4,''),(15,'2026-11-10',5,''),(15,'2026-11-10',6,''),(15,'2026-11-10',7,''),
  (15,'2026-11-11',1,'1304'),(15,'2026-11-11',2,'1304'),(15,'2026-11-11',3,''),(15,'2026-11-11',4,''),(15,'2026-11-11',5,''),(15,'2026-11-11',6,''),(15,'2026-11-11',7,''),
  (15,'2026-11-12',1,''),(15,'2026-11-12',2,''),(15,'2026-11-12',3,'1301'),(15,'2026-11-12',4,'1301'),(15,'2026-11-12',5,'1301'),(15,'2026-11-12',6,'1301'),(15,'2026-11-12',7,''),
  (15,'2026-11-13',1,'1304'),(15,'2026-11-13',2,'1304'),(15,'2026-11-13',3,'1304'),(15,'2026-11-13',4,''),(15,'2026-11-13',5,''),(15,'2026-11-13',6,''),(15,'2026-11-13',7,''),
  (15,'2026-11-14',1,''),(15,'2026-11-14',2,''),(15,'2026-11-14',3,''),(15,'2026-11-14',4,'1304'),(15,'2026-11-14',5,'1304'),(15,'2026-11-14',6,'1304'),(15,'2026-11-14',7,''),
  (15,'2026-11-16',1,'1304'),(15,'2026-11-16',2,'1304'),(15,'2026-11-16',3,'1304'),(15,'2026-11-16',4,''),(15,'2026-11-16',5,''),(15,'2026-11-16',6,''),(15,'2026-11-16',7,'');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (16,(SELECT `id` FROM `groups` WHERE `code`='425'),'ПМ.05 «Проектирование и разработка информационных систем»','09.02.07 «Информационные системы и программирование»','','Хабибуллина Л. Р.','2026-11-10','2026-11-16',16,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (16,'2026-11-10',1,''),(16,'2026-11-10',2,''),(16,'2026-11-10',3,''),(16,'2026-11-10',4,'1304'),(16,'2026-11-10',5,'1304'),(16,'2026-11-10',6,'1304'),(16,'2026-11-10',7,'1304'),
  (16,'2026-11-11',1,''),(16,'2026-11-11',2,''),(16,'2026-11-11',3,''),(16,'2026-11-11',4,''),(16,'2026-11-11',5,'1304'),(16,'2026-11-11',6,'1304'),(16,'2026-11-11',7,'1304'),
  (16,'2026-11-12',1,'1301'),(16,'2026-11-12',2,'1301'),(16,'2026-11-12',3,''),(16,'2026-11-12',4,''),(16,'2026-11-12',5,''),(16,'2026-11-12',6,''),(16,'2026-11-12',7,''),
  (16,'2026-11-13',1,''),(16,'2026-11-13',2,''),(16,'2026-11-13',3,''),(16,'2026-11-13',4,''),(16,'2026-11-13',5,'1304'),(16,'2026-11-13',6,'1304'),(16,'2026-11-13',7,'1304'),
  (16,'2026-11-14',1,''),(16,'2026-11-14',2,''),(16,'2026-11-14',3,''),(16,'2026-11-14',4,'1304'),(16,'2026-11-14',5,'1304'),(16,'2026-11-14',6,'1304'),(16,'2026-11-14',7,''),
  (16,'2026-11-16',1,''),(16,'2026-11-16',2,''),(16,'2026-11-16',3,''),(16,'2026-11-16',4,''),(16,'2026-11-16',5,'1304'),(16,'2026-11-16',6,'1304'),(16,'2026-11-16',7,'1304');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (17,(SELECT `id` FROM `groups` WHERE `code`='323'),'ПМ.02 «Осуществление интеграции программных модулей»','09.02.07 «Информационные системы и программирование»','I подгруппа','Габитова Е. Н.','2026-11-17','2026-11-26',17,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (17,'2026-11-17',1,''),(17,'2026-11-17',2,''),(17,'2026-11-17',3,''),(17,'2026-11-17',4,'1312'),(17,'2026-11-17',5,'1312'),(17,'2026-11-17',6,'1312'),(17,'2026-11-17',7,''),
  (17,'2026-11-18',1,''),(17,'2026-11-18',2,''),(17,'2026-11-18',3,''),(17,'2026-11-18',4,''),(17,'2026-11-18',5,'1202'),(17,'2026-11-18',6,'1210'),(17,'2026-11-18',7,'1210'),
  (17,'2026-11-19',1,''),(17,'2026-11-19',2,''),(17,'2026-11-19',3,''),(17,'2026-11-19',4,'1312'),(17,'2026-11-19',5,'1312'),(17,'2026-11-19',6,'1312'),(17,'2026-11-19',7,''),
  (17,'2026-11-20',1,''),(17,'2026-11-20',2,''),(17,'2026-11-20',3,''),(17,'2026-11-20',4,''),(17,'2026-11-20',5,'1312'),(17,'2026-11-20',6,'1312'),(17,'2026-11-20',7,'1312'),
  (17,'2026-11-21',1,''),(17,'2026-11-21',2,''),(17,'2026-11-21',3,''),(17,'2026-11-21',4,''),(17,'2026-11-21',5,'1210'),(17,'2026-11-21',6,'1210'),(17,'2026-11-21',7,'1210'),
  (17,'2026-11-23',1,''),(17,'2026-11-23',2,''),(17,'2026-11-23',3,''),(17,'2026-11-23',4,''),(17,'2026-11-23',5,''),(17,'2026-11-23',6,'1210'),(17,'2026-11-23',7,'1210'),
  (17,'2026-11-24',1,''),(17,'2026-11-24',2,''),(17,'2026-11-24',3,''),(17,'2026-11-24',4,'1312'),(17,'2026-11-24',5,'1312'),(17,'2026-11-24',6,'1312'),(17,'2026-11-24',7,''),
  (17,'2026-11-25',1,''),(17,'2026-11-25',2,''),(17,'2026-11-25',3,''),(17,'2026-11-25',4,''),(17,'2026-11-25',5,'1317'),(17,'2026-11-25',6,'1210'),(17,'2026-11-25',7,'1210'),
  (17,'2026-11-26',1,''),(17,'2026-11-26',2,''),(17,'2026-11-26',3,''),(17,'2026-11-26',4,'1312'),(17,'2026-11-26',5,'1312'),(17,'2026-11-26',6,'1312'),(17,'2026-11-26',7,'1312');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (18,(SELECT `id` FROM `groups` WHERE `code`='323'),'ПМ.02 «Осуществление интеграции программных модулей»','09.02.07 «Информационные системы и программирование»','II подгруппа','Родионова А. А.','2026-11-17','2026-11-26',18,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (18,'2026-11-17',1,''),(18,'2026-11-17',2,''),(18,'2026-11-17',3,''),(18,'2026-11-17',4,'1312'),(18,'2026-11-17',5,'1312'),(18,'2026-11-17',6,'1312'),(18,'2026-11-17',7,'1312'),
  (18,'2026-11-18',1,''),(18,'2026-11-18',2,''),(18,'2026-11-18',3,''),(18,'2026-11-18',4,''),(18,'2026-11-18',5,''),(18,'2026-11-18',6,'1210'),(18,'2026-11-18',7,'1210'),
  (18,'2026-11-19',1,''),(18,'2026-11-19',2,''),(18,'2026-11-19',3,''),(18,'2026-11-19',4,'1312'),(18,'2026-11-19',5,'1312'),(18,'2026-11-19',6,'1312'),(18,'2026-11-19',7,'1312'),
  (18,'2026-11-20',1,'1318'),(18,'2026-11-20',2,'1318'),(18,'2026-11-20',3,''),(18,'2026-11-20',4,''),(18,'2026-11-20',5,''),(18,'2026-11-20',6,''),(18,'2026-11-20',7,''),
  (18,'2026-11-21',1,''),(18,'2026-11-21',2,''),(18,'2026-11-21',3,''),(18,'2026-11-21',4,''),(18,'2026-11-21',5,'1210'),(18,'2026-11-21',6,'1210'),(18,'2026-11-21',7,'1210'),
  (18,'2026-11-23',1,''),(18,'2026-11-23',2,''),(18,'2026-11-23',3,''),(18,'2026-11-23',4,''),(18,'2026-11-23',5,''),(18,'2026-11-23',6,'1210'),(18,'2026-11-23',7,'1210'),
  (18,'2026-11-24',1,''),(18,'2026-11-24',2,''),(18,'2026-11-24',3,''),(18,'2026-11-24',4,'1312'),(18,'2026-11-24',5,'1312'),(18,'2026-11-24',6,'1312'),(18,'2026-11-24',7,'1312'),
  (18,'2026-11-25',1,''),(18,'2026-11-25',2,''),(18,'2026-11-25',3,''),(18,'2026-11-25',4,''),(18,'2026-11-25',5,''),(18,'2026-11-25',6,'1210'),(18,'2026-11-25',7,'1210'),
  (18,'2026-11-26',1,''),(18,'2026-11-26',2,''),(18,'2026-11-26',3,''),(18,'2026-11-26',4,'1312'),(18,'2026-11-26',5,'1312'),(18,'2026-11-26',6,'1312'),(18,'2026-11-26',7,'1312');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (19,(SELECT `id` FROM `groups` WHERE `code`='401'),'ПМ.03 «Обеспечение информационной безопасности инфокоммуникационных сетей и систем связи»','11.02.15 «Инфокоммуникационные сети и системы связи»','','Тимохина В. А.','2026-11-17','2026-11-23',19,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (19,'2026-11-17',1,''),(19,'2026-11-17',2,''),(19,'2026-11-17',3,''),(19,'2026-11-17',4,'1317'),(19,'2026-11-17',5,'1317'),(19,'2026-11-17',6,'1317'),(19,'2026-11-17',7,''),
  (19,'2026-11-18',1,'1317'),(19,'2026-11-18',2,'1317'),(19,'2026-11-18',3,''),(19,'2026-11-18',4,''),(19,'2026-11-18',5,''),(19,'2026-11-18',6,''),(19,'2026-11-18',7,''),
  (19,'2026-11-19',1,''),(19,'2026-11-19',2,''),(19,'2026-11-19',3,''),(19,'2026-11-19',4,'1313'),(19,'2026-11-19',5,'1313'),(19,'2026-11-19',6,''),(19,'2026-11-19',7,''),
  (19,'2026-11-20',1,''),(19,'2026-11-20',2,''),(19,'2026-11-20',3,''),(19,'2026-11-20',4,'1317'),(19,'2026-11-20',5,'1317'),(19,'2026-11-20',6,'1317'),(19,'2026-11-20',7,'1317'),
  (19,'2026-11-21',1,''),(19,'2026-11-21',2,''),(19,'2026-11-21',3,'1314'),(19,'2026-11-21',4,'1314'),(19,'2026-11-21',5,'1314'),(19,'2026-11-21',6,''),(19,'2026-11-21',7,''),
  (19,'2026-11-23',1,''),(19,'2026-11-23',2,''),(19,'2026-11-23',3,''),(19,'2026-11-23',4,'1313'),(19,'2026-11-23',5,'1313'),(19,'2026-11-23',6,'1313'),(19,'2026-11-23',7,'1313');
INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (20,(SELECT `id` FROM `groups` WHERE `code`='402'),'ПМ.05 «Адаптация конвергентных технологий и систем к потребностям заказчика»','11.02.15 «Инфокоммуникационные сети и системы связи»','','Васильева Е. С.','2026-11-17','2026-11-23',20,1);
INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES
  (20,'2026-11-17',1,'1201'),(20,'2026-11-17',2,'1201'),(20,'2026-11-17',3,'1201'),(20,'2026-11-17',4,''),(20,'2026-11-17',5,''),(20,'2026-11-17',6,''),(20,'2026-11-17',7,''),
  (20,'2026-11-18',1,'1201'),(20,'2026-11-18',2,'1201'),(20,'2026-11-18',3,'1201'),(20,'2026-11-18',4,''),(20,'2026-11-18',5,''),(20,'2026-11-18',6,''),(20,'2026-11-18',7,''),
  (20,'2026-11-19',1,''),(20,'2026-11-19',2,''),(20,'2026-11-19',3,''),(20,'2026-11-19',4,''),(20,'2026-11-19',5,'1201'),(20,'2026-11-19',6,'1201'),(20,'2026-11-19',7,'1201'),
  (20,'2026-11-20',1,'1201'),(20,'2026-11-20',2,'1201'),(20,'2026-11-20',3,''),(20,'2026-11-20',4,''),(20,'2026-11-20',5,''),(20,'2026-11-20',6,''),(20,'2026-11-20',7,''),
  (20,'2026-11-21',1,'1201'),(20,'2026-11-21',2,'1201'),(20,'2026-11-21',3,'1201'),(20,'2026-11-21',4,''),(20,'2026-11-21',5,''),(20,'2026-11-21',6,''),(20,'2026-11-21',7,''),
  (20,'2026-11-23',1,'1201'),(20,'2026-11-23',2,'1201'),(20,'2026-11-23',3,'1201'),(20,'2026-11-23',4,'1201'),(20,'2026-11-23',5,''),(20,'2026-11-23',6,''),(20,'2026-11-23',7,'');
COMMIT;
-- MySQL dump 10.13  Distrib 8.0.30, for Win64 (x86_64)
--
-- Host: localhost    Database: ktits_info
-- ------------------------------------------------------
-- Server version	8.0.30

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `itcube_lessons`
--

DROP TABLE IF EXISTS `itcube_lessons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `itcube_lessons` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `day_of_week` tinyint unsigned NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `room` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `subject` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `teacher` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `group_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `sort_order` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_day` (`day_of_week`,`start_time`)
) ENGINE=InnoDB AUTO_INCREMENT=151 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `itcube_lessons`
--

LOCK TABLES `itcube_lessons` WRITE;
/*!40000 ALTER TABLE `itcube_lessons` DISABLE KEYS */;
INSERT INTO `itcube_lessons` VALUES (100,1,'15:30:00','17:00:00','301','','Ясавеев Р.А.','239МР',0),(101,1,'15:00:00','16:30:00','304','','Мурсалимов Д.Р.','51СА',1),(102,1,'15:00:00','16:30:00','','','Бархатов Н.М.','80МР',2),(103,1,'17:00:00','18:30:00','301','','Ясавеев Р.А.','240МР',3),(104,1,'16:30:00','18:00:00','304','','Мурсалимов Д.Р.','52СА',4),(105,1,'16:00:00','18:00:00','305','','Бархатов Н.М.','31VR',5),(106,1,'16:30:00','18:00:00','309','','Садриев В.Э.','P26-1',6),(107,1,'17:00:00','18:30:00','коворкинг','','Гаффарова Д.Л.','230МР',7),(108,1,'18:30:00','20:00:00','301','','Ясавеев Р.А.','241МР',8),(109,1,'18:00:00','20:00:00','305','','Бархатов Н.М.','32VR',9),(110,1,'18:00:00','19:30:00','309','','Садриев В.Э.','P26-2',10),(111,1,'18:30:00','20:00:00','коворкинг','','Гаффарова Д.Л.','231МР',11),(112,2,'09:00:00','10:30:00','коворкинг','','Носова А.Ф.','232МР',12),(113,2,'11:50:00','15:10:00','308','','Галеев Р.Р.','22Кстуд',13),(114,2,'15:30:00','17:00:00','305','','Бархатов Н.М.','236МР',14),(115,2,'15:30:00','17:00:00','308','','Галеев Р.Р.','23К',15),(116,2,'15:30:00','17:30:00','311','','Ясавеев Р.А.','53J',16),(117,2,'15:30:00','17:00:00','коворкинг','','Мурсалимов Д.Р.','233МР',17),(118,2,'17:00:00','18:30:00','305','','Бархатов Н.М.','237МР',18),(119,2,'17:30:00','19:30:00','311','','Ясавеев Р.А.','54J',19),(120,2,'17:00:00','18:30:00','коворкинг','','Мингараева А.Н.','234МР',20),(121,2,'18:30:00','20:00:00','305','','Бархатов Н.М.','238МР',21),(122,2,'18:30:00','20:00:00','коворкинг','','Мингараева А.Н.','235МР',22),(123,3,'15:30:00','17:00:00','301','','Ясавеев Р.А.','239МР',23),(124,3,'15:00:00','16:30:00','304','','Мурсалимов Д.Р.','51СА',24),(125,3,'17:00:00','18:30:00','301','','Ясавеев Р.А.','240МР',25),(126,3,'16:30:00','18:00:00','304','','Мурсалимов Д.Р.','52СА',26),(127,3,'16:00:00','18:00:00','305','','Бархатов Н.М.','31VR',27),(128,3,'17:00:00','18:30:00','коворкинг','','Гаффарова Д.Л','230МР',28),(129,3,'18:30:00','20:00:00','301','','Ясавеев Р.А.','241МР',29),(130,3,'18:00:00','20:00:00','305','','Бархатов Н.М.','32VR',30),(131,3,'18:30:00','20:00:00','коворкинг','','Гаффарова Д.Л','231МР',31),(132,4,'09:00:00','10:30:00','коворкинг','','Носова А.Ф.','232МР',32),(133,4,'15:30:00','17:00:00','305','','Бархатов Н.М.','236МР',33),(134,4,'15:30:00','17:00:00','308','','Галеев Р.Р.','23К',34),(135,4,'15:30:00','17:30:00','311','','Ясавеев Р.А.','53J',35),(136,4,'15:30:00','17:00:00','коворкинг','','Мурсалимов Д.Р.','233МР',36),(137,4,'17:00:00','18:30:00','305','','Бархатов Н.М.','237МР',37),(138,4,'16:30:00','18:00:00','309','','Садриев В.Э.','P26-1',38),(139,4,'17:30:00','19:30:00','311','','Ясавеев Р.А.','54J',39),(140,4,'17:00:00','18:30:00','коворкинг','','Мингараева А.Н.','234МР',40),(141,4,'18:30:00','20:00:00','305','','Бархатов Н.М.','238МР',41),(142,4,'18:00:00','19:30:00','309','','Садриев В.Э.','P26-2',42),(143,4,'18:30:00','20:00:00','коворкинг','','Мингараева А.Н.','235МР',43),(144,5,'18:30:00','20:00:00','305','скрэтч','','',44),(145,5,'18:00:00','20:00:00','308','','Ясавеев Р.А.','8МР/K',45),(146,6,'10:00:00','12:00:00','305','','Бархатов Н.М','15ПS/K',46),(147,6,'12:00:00','14:00:00','305','','Бархатов Н.М','6R/K',47),(148,6,'14:00:00','16:00:00','305','','Бархатов Н.М','53D/K',48),(149,6,'14:00:00','16:00:00','308','','Ясавеев Р.А.','8J/K',49),(150,6,'16:00:00','18:00:00','305','','Бархатов Н.М.','16П/К',50);
/*!40000 ALTER TABLE `itcube_lessons` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-25  2:49:47
