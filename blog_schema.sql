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


-- =================================================================
-- DAHA İLERİ SEVİYE SORGULAR
-- =================================================================

-- Sorgu 6: Her yazının başlığını ve etiketlerini tek bir satırda, virgülle ayrılmış olarak birleştirme. (CTE, STRING_AGG)
WITH PostWithTags AS (
    SELECT
        p.id,
        p.title,
        t.tag_name
    FROM
        posts p
    JOIN
        post_tags pt ON p.id = pt.post_id
    JOIN
        tags t ON pt.tag_id = t.id
)
SELECT
    pwt.title,
    STRING_AGG(pwt.tag_name, ', ') AS tags
FROM
    PostWithTags pwt
GROUP BY
    pwt.id, pwt.title
ORDER BY
    pwt.title;


-- Sorgu 7: Her yazarın en son yazdığı yazıyı bulma. (Window Function, RANK, CTE)
WITH RankedPosts AS (
    SELECT
        a.username,
        p.title,
        p.published_at,
        RANK() OVER (PARTITION BY a.id ORDER BY p.published_at DESC) as rank_num
    FROM
        authors a
    JOIN
        posts p ON a.id = p.author_id
)
SELECT
    username,
    title,
    published_at
FROM
    RankedPosts
WHERE
    rank_num = 1;


-- Sorgu 8: En çok yoruma sahip ilk 3 yazıyı ve yorum sayılarını bulma. (JOIN, GROUP BY, ORDER BY, LIMIT)
SELECT
    p.title,
    COUNT(c.id) AS comment_count
FROM
    posts p
JOIN
    comments c ON p.id = c.post_id
GROUP BY
    p.id, p.title
ORDER BY
    comment_count DESC
LIMIT 3;


-- Sorgu 9: Yazarların gönderileri arasındaki ortalama süreyi bulma. (Window Function, LAG)
WITH PostPublicationGaps AS (
    SELECT
        author_id,
        published_at,
        LAG(published_at, 1) OVER (PARTITION BY author_id ORDER BY published_at) AS previous_post_date
    FROM
        posts
)
SELECT
    a.username,
    AVG(published_at - previous_post_date) AS average_time_between_posts
FROM
    PostPublicationGaps ppg
JOIN
    authors a ON ppg.author_id = a.id
WHERE
    ppg.previous_post_date IS NOT NULL
GROUP BY
    a.username
ORDER BY
    average_time_between_posts;