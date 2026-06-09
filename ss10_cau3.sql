CREATE TABLE employees
(
    id       SERIAL PRIMARY KEY,
    name     VARCHAR(100),
    position VARCHAR(50),
    salary   NUMERIC(10, 2)
);

-- Tạo bảng employees_log với cấu trúc phù hợp
CREATE TABLE employees_log
(
    id SERIAL PRIMARY KEY,
    employee_id INT,
    operation   VARCHAR(50) CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data    JSON,
    new_data    JSON,
    change_time TIMESTAMP
);

-- Viết Function Trigger bằng PL/pgSQL
CREATE OR REPLACE FUNCTION tg_employees_audit_log()
    RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO employees_log (employee_id, operation, old_data, new_data)
        VALUES (NEW.id, 'INSERT', NULL, to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO employees_log (employee_id, operation, old_data, new_data)
        VALUES (NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO employees_log (employee_id, operation, old_data, new_data)
        VALUES (OLD.id, 'DELETE', to_jsonb(OLD), NULL);
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Tạo Trigger gắn với bảng employees
CREATE OR REPLACE TRIGGER trg_employees_audit
    AFTER INSERT OR UPDATE OR DELETE
    ON employees
    FOR EACH ROW
EXECUTE FUNCTION tg_employees_audit_log();

-- Thực hành: chèn, cập nhật và xóa dữ liệu nhân viên, kiểm tra log có chính xác không
INSERT INTO employees (name, position, salary) VALUES ('Nguyen Duy Trung', 'Backend Developer', 20000000);
INSERT INTO employees (name, position, salary) VALUES ('Tran Van A', 'Tester', 12000000);

SELECT id, employee_id, operation, old_data, new_data, change_time
FROM employees_log
ORDER BY id;

UPDATE employees
SET position = 'Senior Backend', salary = 28000000
WHERE id = 1;

DELETE FROM employees WHERE id = 2;