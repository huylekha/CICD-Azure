-- Initialize database with sample data
-- This script runs when PostgreSQL container starts

-- Create sample accounts
INSERT INTO "Accounts" ("Id", "AccountNumber", "AccountHolderName", "Balance", "Currency", "IsActive", "CreatedAt", "UpdatedAt", "Version")
VALUES 
    ('550e8400-e29b-41d4-a716-446655440001', 'ACC001', 'John Doe', 5000.00, 'USD', true, NOW(), NOW(), 'v1'),
    ('550e8400-e29b-41d4-a716-446655440002', 'ACC002', 'Jane Smith', 3000.00, 'USD', true, NOW(), NOW(), 'v1'),
    ('550e8400-e29b-41d4-a716-446655440003', 'ACC003', 'Bob Johnson', 7500.00, 'USD', true, NOW(), NOW(), 'v1'),
    ('550e8400-e29b-41d4-a716-446655440004', 'ACC004', 'Alice Brown', 1200.00, 'USD', false, NOW(), NOW(), 'v1'),
    ('550e8400-e29b-41d4-a716-446655440005', 'ACC005', 'Charlie Wilson', 9800.00, 'USD', true, NOW(), NOW(), 'v1')
ON CONFLICT ("Id") DO NOTHING;

-- Create sample transactions
INSERT INTO "Transactions" ("Id", "FromAccountId", "ToAccountId", "Amount", "Currency", "Description", "Status", "Type", "CreatedAt", "CompletedAt", "CorrelationId")
VALUES 
    ('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440002', 1000.00, 'USD', 'Payment for services', 2, 0, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'corr-001'),
    ('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003', 500.00, 'USD', 'Monthly rent payment', 1, 0, NOW() - INTERVAL '2 hours', NULL, 'corr-002'),
    ('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 2500.00, 'USD', 'Refund for cancelled order', 2, 3, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours', 'corr-003'),
    ('660e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440005', 750.00, 'USD', 'Failed transfer - insufficient funds', 3, 0, NOW() - INTERVAL '4 hours', NULL, 'corr-004'),
    ('660e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440001', 2000.00, 'USD', 'Business payment', 5, 0, NOW() - INTERVAL '5 hours', NULL, 'corr-005')
ON CONFLICT ("Id") DO NOTHING;

-- Create sample notifications
INSERT INTO "Notifications" ("Id", "RecipientEmail", "RecipientPhone", "Subject", "Message", "Type", "Priority", "Status", "CreatedAt", "SentAt", "CorrelationId")
VALUES 
    ('770e8400-e29b-41d4-a716-446655440001', 'john.doe@example.com', '+1234567890', 'Transfer Completed', 'Your transfer of $1000.00 has been completed successfully.', 0, 1, 1, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', 'corr-001'),
    ('770e8400-e29b-41d4-a716-446655440002', 'jane.smith@example.com', '+1234567891', 'Transfer Processing', 'Your transfer of $500.00 is being processed.', 0, 1, 0, NOW() - INTERVAL '2 hours', NULL, 'corr-002'),
    ('770e8400-e29b-41d4-a716-446655440003', 'bob.johnson@example.com', '+1234567892', 'Refund Completed', 'Your refund of $2500.00 has been processed.', 0, 1, 1, NOW() - INTERVAL '3 hours', NOW() - INTERVAL '3 hours', 'corr-003')
ON CONFLICT ("Id") DO NOTHING;
