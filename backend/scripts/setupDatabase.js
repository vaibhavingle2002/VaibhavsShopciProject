const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupDatabase() {
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME
    });

    await connection.query(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME}`);
    await connection.changeUser({ database: process.env.DB_NAME });

    // Users table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        phone VARCHAR(15),
        address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Categories table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        image VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Products table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10,2) NOT NULL,
        original_price DECIMAL(10,2),
        discount_percentage INT DEFAULT 0,
        category_id INT,
        brand VARCHAR(100),
        stock_quantity INT DEFAULT 0,
        image VARCHAR(255),
        rating DECIMAL(2,1) DEFAULT 0,
        reviews_count INT DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    `);

    // Cart table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS cart (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        product_id INT,
        quantity INT DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    `);

    // Orders table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT,
        total_amount DECIMAL(10,2),
        status VARCHAR(50) DEFAULT 'pending',
        shipping_address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    `);

    // Order items table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT,
        product_id INT,
        quantity INT,
        price DECIMAL(10,2),
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    `);

    // Insert dummy categories
    await connection.query(`
      INSERT IGNORE INTO categories (id, name, description, image) VALUES
      (1, 'Electronics', 'Electronic devices and gadgets', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=300'),
      (2, 'Fashion', 'Clothing and accessories', 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300'),
      (3, 'Home & Kitchen', 'Home appliances and kitchen items', 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=300'),
      (4, 'Books', 'Books and educational materials', 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=300'),
      (5, 'Sports', 'Sports and fitness equipment', 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300')
    `);

    // Insert dummy products
    await connection.query(`
      INSERT IGNORE INTO products (id, name, description, price, original_price, discount_percentage, category_id, brand, stock_quantity, image, rating, reviews_count) VALUES
      (1, 'iPhone 15 Pro', 'Latest iPhone with advanced features and A17 Pro chip', 999.99, 1199.99, 17, 1, 'Apple', 50, 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400&h=400&fit=crop', 4.5, 1250),
      (2, 'Samsung Galaxy S24', 'Premium Android smartphone with AI features', 899.99, 999.99, 10, 1, 'Samsung', 75, 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=400&fit=crop', 4.3, 890),
      (3, 'MacBook Air M2', 'Lightweight laptop with M2 chip and all-day battery', 1199.99, 1299.99, 8, 1, 'Apple', 30, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400&h=400&fit=crop', 4.7, 2100),
      (4, 'Sony WH-1000XM5', 'Industry-leading noise cancelling headphones', 349.99, 399.99, 13, 1, 'Sony', 100, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop', 4.6, 1500),
      (5, 'Nike Air Max 270', 'Comfortable running shoes with Max Air cushioning', 129.99, 149.99, 13, 2, 'Nike', 200, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop', 4.4, 750),
      (6, 'Levi''s 501 Jeans', 'Classic straight fit jeans - original since 1873', 59.99, 79.99, 25, 2, 'Levi''s', 150, 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=400&fit=crop', 4.2, 650),
      (7, 'KitchenAid Stand Mixer', 'Professional 5-quart stand mixer for baking', 299.99, 349.99, 14, 3, 'KitchenAid', 25, 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=400&fit=crop', 4.8, 3200),
      (8, 'Dyson V15 Vacuum', 'Cordless vacuum with laser dust detection', 649.99, 749.99, 13, 3, 'Dyson', 40, 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=400&fit=crop', 4.5, 1800),
      (9, 'The Great Gatsby', 'Classic American novel by F. Scott Fitzgerald', 12.99, 15.99, 19, 4, 'Scribner', 500, 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400&h=400&fit=crop', 4.1, 25000),
      (10, 'Yoga Mat Premium', 'Non-slip exercise mat with alignment lines', 39.99, 49.99, 20, 5, 'Manduka', 80, 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop', 4.3, 420)
    `);

    console.log('Database setup completed successfully!');
    await connection.end();
  } catch (error) {
    console.error('Database setup failed:', error);
  }
}

setupDatabase();
