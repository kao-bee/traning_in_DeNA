CREATE TABLE todos(
       id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
       text TEXT,
       due_at DATETIME,
       done TINYINT(1) NOT NULL DEFAULT 0,
       created_at DATETIME NOT NULL,
       updated_at DATETIME NOT NULL,
       primary key(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
