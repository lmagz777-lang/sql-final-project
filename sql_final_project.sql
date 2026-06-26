#1 Используя данные таблиц за период с 01.06.2015 по 01.06.2016, нужно вывести

select * FROM customers;
select * FROM transactions;

# список клиентов с непрерывной историей за год, то есть каждый месяц на регулярной основе без пропусков за указанный годовой период
SELECT 
    ID_client,
	COUNT(DISTINCT YEAR(date_new) * 100 + MONTH(date_new)) as active_months
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY ID_client
HAVING active_months = 12;

#  средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, количество всех операций по клиенту за период

SELECT 
    ID_client,
    AVG(Sum_payment) as avg_check,
    SUM(Sum_payment)/12 as avg_month_amount,
    COUNT(Id_check) AS total_operations
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT YEAR(date_new) * 100 + MONTH(date_new)) = 12;

# 2 информацию в разрезе месяцев: a) средняя сумма чека в месяц:

SELECT DATE_FORMAT(date_new, '%Y-%m') as month, AVG(Sum_payment) as avg_check
FROM transactions
GROUP BY month
ORDER BY month;

# b) среднее количество операций в месяц;

SELECT DATE_FORMAT(date_new, '%Y-%m') as month,
    COUNT(DISTINCT Id_check) as operations_count
FROM transactions
GROUP BY month;

# c) среднее количество клиентов, которые совершали операции;

SELECT DATE_FORMAT(date_new, '%Y-%m') as month,
    COUNT(DISTINCT ID_client) as clients_count
FROM transactions
GROUP BY month;

# d) долю от общего количества операций за год и долю в месяц от общей суммы операций;

SELECT 
    DATE_FORMAT(date_new, '%Y-%m') as month,
    COUNT(DISTINCT Id_check) / SUM(COUNT(DISTINCT Id_check)) OVER() * 100 as operations_percent,
    SUM(Sum_payment) / SUM(SUM(Sum_payment)) OVER() * 100 as month_percent
FROM transactions
GROUP BY month
ORDER BY month;

# e) вывести % соотношение M/F/NA в каждом месяце с их долей затрат;

SELECT DATE_FORMAT(t.date_new, '%Y-%m') as month, c.Gender,
    COUNT(DISTINCT t.ID_client) / SUM(COUNT(DISTINCT t.ID_client)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100 as gender_count,
    SUM(t.Sum_payment) / SUM(SUM(t.Sum_payment)) OVER(PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) * 100 as gender_payment
FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client
GROUP BY month, c.Gender
ORDER BY month, c.Gender;

# 3. возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации, с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.

SELECT age_group, quarter_name, SUM(Sum_payment) as total_sum, COUNT(Id_check) as total_operations,
   ROUND(SUM(Sum_payment) / SUM(SUM(Sum_payment)) OVER(PARTITION BY quarter_name) * 100, 2) as sum_percent
FROM (SELECT 
        IFNULL(CONCAT(FLOOR(c.Age / 10) * 10, '-', FLOOR(c.Age / 10) * 10 + 9), 'Unknown') as age_group,
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) as quarter_name,
        t.Sum_payment,
        t.Id_check
    FROM transactions t
    JOIN customers c ON t.ID_client = c.Id_client
) as sub
GROUP BY age_group, quarter_name
ORDER BY quarter_name, age_group;