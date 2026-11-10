CREATE TABLE IF NOT EXISTS sales (
    client_id INTEGER NOT NULL,
    gender TEXT NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    price_per_item INTEGER NOT NULL,
    discount_per_item INTEGER NOT NULL,
    total_price NUMERIC(12, 2) NOT NULL,
    purchase_date DATE NOT NULL,
    purchased_at TIMESTAMP NOT NULL,
    PRIMARY KEY (client_id, purchased_at, product_id)
);