-- =================================================================
-- BLOG PLATFORMU VERİTABANI ŞEMASI VE ÖRNEK SORGULAR
-- =================================================================

-- Önceki çalıştırmalardan kalan tabloları temizle (script'in tekrar tekrar çalışabilmesi için)
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS post_tags;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS authors;


-- Tabloların Oluşturulması
-- -----------------------------------------------------------------

CREATE TABLE authors (
    id INT GENERATED ALWAYS AS IDENTITY,
    username VARCHAR(100) NOT NULL UNIQUE,
    join_date DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id)
);

CREATE TABLE posts (
    id INT GENERATED ALWAYS AS IDENTITY,
    author_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (id),
    CONSTRAINT fk_author
        FOREIGN KEY (author_id)
        REFERENCES authors(id)
        ON DELETE CASCADE -- Yazar silinirse yazıları da silinsin.
);

CREATE TABLE tags (
    id INT GENERATED ALWAYS AS IDENTITY,
    tag_name VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

-- Yazılar ve Etiketler arasında Çoğa-Çok ilişki için bağlantı tablosu
CREATE TABLE post_tags (
    post_id INT NOT NULL,
    tag_id INT NOT NULL,
    PRIMARY KEY (post_id, tag_id), -- İki sütun birden birincil anahtar
    CONSTRAINT fk_post
        FOREIGN KEY (post_id)
        REFERENCES posts(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_tag
        FOREIGN KEY (tag_id)
        REFERENCES tags(id)
        ON DELETE CASCADE
);

CREATE TABLE comments (
    id INT GENERATED ALWAYS AS IDENTITY,
    post_id INT NOT NULL,
    commenter_name VARCHAR(100) NOT NULL,
    comment_body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (id),
    CONSTRAINT fk_post_comment
        FOREIGN KEY (post_id)
        REFERENCES posts(id)
        ON DELETE CASCADE
);


-- Örnek Verilerin Eklenmesi (Seeding)
-- -----------------------------------------------------------------

INSERT INTO authors (username) VALUES
('ali_yilmaz'),
('zeynep_kaya'),
('can_demir');

INSERT INTO posts (author_id, title, content) VALUES
(1, 'PostgreSQL''e Giriş', 'PostgreSQL, güçlü ve açık kaynaklı bir ilişkisel veritabanıdır...'),
(1, 'SQL JOIN Tipleri', 'INNER JOIN, LEFT JOIN ve diğer birleştirme türleri...'),
(2, 'Veritabanı Normalizasyonu Neden Önemli?', 'Veri tekrarını önlemek ve veri bütünlüğünü sağlamak için...'),
(2, 'Python ve PostgreSQL Bağlantısı', 'Psycopg2 kütüphanesi kullanarak Python ile PostgreSQL''e nasıl bağlanılır...'),
(1, 'Advanced SQL: CTE ve Window Functions', 'Common Table Expressions (CTE) sorguları nasıl daha okunabilir hale getirir...');

INSERT INTO tags (tag_name) VALUES
('sql'),
('postgresql'),
('database'),
('python'),
('tutorial');

-- Yazılara etiket atamaları
INSERT INTO post_tags (post_id, tag_id) VALUES
(1, 1), (1, 2), (1, 3), -- PostgreSQL'e Giriş -> sql, postgresql, database
(2, 1), (2, 3),          -- SQL JOIN Tipleri -> sql, database
(3, 3),                  -- Veritabanı Normalizasyonu -> database
(4, 2), (4, 4),          -- Python ve PostgreSQL -> postgresql, python
(5, 1), (5, 2);          -- Advanced SQL -> sql, postgresql

INSERT INTO comments (post_id, commenter_name, comment_body) VALUES
(1, 'ahmet', 'Harika bir başlangıç rehberi, teşekkürler!'),
(1, 'leyla', 'Çok faydalı buldum.'),
(2, 'mehmet', 'LEFT JOIN her zaman aklımı karıştırıyordu, şimdi anladım.'),
(4, 'ayse', 'Tam da aradığım konuydu!');


-- =================================================================
-- GELİŞMİŞ SORGULAR
-- =================================================================

-- Sorgu 1: Her yazarın toplam kaç yazı yazdığını bulma. (JOIN, COUNT, GROUP BY)
SELECT
    a.username,
    COUNT(p.id) AS post_count
FROM
    authors a
LEFT JOIN
    posts p ON a.id = p.author_id
GROUP BY
    a.username
ORDER BY
    post_count DESC;


-- Sorgu 2: En az 2 yazı yazmış olan yazarları bulma. (GROUP BY, HAVING)
SELECT
    a.username
FROM
    authors a
JOIN
    posts p ON a.id = p.author_id
GROUP BY
    a.username
HAVING
    COUNT(p.id) >= 2;


-- Sorgu 3: Her bir yazının başlığını ve sahip olduğu tüm etiketleri yan yana gösterme. (Many-to-Many JOIN)
SELECT
    p.title,
    t.tag_name
FROM
    posts p
JOIN
    post_tags pt ON p.id = pt.post_id
JOIN
    tags t ON pt.tag_id = t.id
ORDER BY
    p.title;


-- Sorgu 4: Hiç yorum almamış yazıların başlıklarını bulma. (LEFT JOIN, WHERE IS NULL)
SELECT
    p.title
FROM
    posts p
LEFT JOIN
    comments c ON p.id = c.post_id
WHERE
    c.id IS NULL;


-- Sorgu 5: 'postgresql' etiketine sahip yazıların yazarlarını ve başlıklarını bulma. (Subquery / Alt Sorgu ile IN kullanımı)
SELECT
    a.username,
    p.title
FROM
    posts p
JOIN
    authors a ON p.author_id = a.id
WHERE
    p.id IN (
        SELECT post_id FROM post_tags WHERE tag_id = (SELECT id FROM tags WHERE tag_name = 'postgresql')
    );