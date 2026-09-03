-- Seed data for Certy application

-- Insert an admin user (password is 'password123' - hashed)
-- Note: In production, never use plain passwords like this
-- This is just for demonstration purposes
INSERT INTO users (email, password, name, role) VALUES
('admin@certy.ru', '$2a$10$8K1p/aWnHD0YU7ANcKZyHeIgdEU6s4hFRr2LcU7Nd0a453mK6Lq6e', 'Admin User', 'admin'),
('user@certy.ru', '$2a$10$8K1p/aWnHD0YU7ANcKZyHeIgdEU6s4hFRr2LcU7Nd0a453mK6Lq6e', 'Regular User', 'user')
ON CONFLICT (email) DO NOTHING;

-- Insert some certificate templates
INSERT INTO certificate_templates (name, description, file_path, created_by) VALUES
('Basic Certificate', 'A simple, elegant certificate template', '/templates/basic.pdf', 1),
('Professional Certificate', 'A professional-looking certificate for formal events', '/templates/professional.pdf', 1),
('Academic Certificate', 'A certificate suitable for educational achievements', '/templates/academic.pdf', 1)
ON CONFLICT DO NOTHING;

-- Insert some sample coupons
INSERT INTO coupons (code, discount_percent, is_active, max_uses) VALUES
('WELCOME15', 15, true, 100),
('SAVE20', 20, true, 50),
('FREQUENT25', 25, true, 25)
ON CONFLICT DO NOTHING;

-- Insert some sample orders for testing
INSERT INTO orders (user_id, amount, currency, status) VALUES
(2, 990.00, 'RUB', 'paid'),
(2, 1990.00, 'RUB', 'paid'),
(2, 150.00, 'RUB', 'pending')
ON CONFLICT DO NOTHING;

-- Insert some sample order items
INSERT INTO order_items (order_id, type, name, quantity, unit_price, total_price) VALUES
(1, 'subscription', 'Basic Plan', 1, 990.00, 990.00),
(2, 'subscription', 'Pro Plan', 1, 1990.00, 1990.00),
(3, 'certificate', 'Custom Certificate', 10, 15.00, 150.00)
ON CONFLICT DO NOTHING;

-- Insert a sample subscription
INSERT INTO subscriptions (user_id, plan_id, plan_name, start_date, end_date, is_active, max_certificates) VALUES
(2, 1, 'Basic Plan', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '30 days', true, 50)
ON CONFLICT DO NOTHING;

-- Insert a sample certificate
INSERT INTO certificates (user_id, template_id, template_name, participant_name, event_title, issue_date, status, file_path) VALUES
(2, 1, 'Basic Certificate', 'John Doe', 'Annual Conference 2023', CURRENT_DATE, 'generated', '/certificates/user2_john_doe_2023.pdf')
ON CONFLICT DO NOTHING;

-- Insert sample analytics events
INSERT INTO analytics_events (user_id, event, properties, ip_address, user_agent) VALUES
(2, 'page_view', '{"page": "/dashboard"}', '127.0.0.1', 'Mozilla/5.0...'),
(2, 'generate_certificate', '{"template_id": 1, "participant_count": 5}', '127.0.0.1', 'Mozilla/5.0...')
ON CONFLICT DO NOTHING;