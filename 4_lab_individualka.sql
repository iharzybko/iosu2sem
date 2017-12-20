--///////////////////////////////////////////////
--/ 1.  Создать процедуру.
CREATE OR  REPLACE PROCEDURE show_active_users
IS
CURSOR cur IS
SELECT workers.name, workers.middle_name, workers.surname,positions.name pos_name
FROM workers 
JOIN 
(
	SELECT * FROM changing_positions
	WHERE ROWID IN
	(
		SELECT MAX(ROWID) 
		FROM changing_positions 
		GROUP BY worker_id
	)
) active_schedule
ON active_schedule.worker_id = workers.worker_id
JOIN positions
ON active_schedule.position_id = positions.position_id;

res cur%ROWTYPE;

BEGIN
	DBMS_OUTPUT.ENABLE;
	OPEN cur;
	FETCH cur
    INTO res;
	WHILE cur%FOUND
	LOOP
	DBMS_OUTPUT.put_line (res.name ||'--'|| res.middle_name ||'--'||  res.surname ||'--'||  res.pos_name);
      FETCH cur
       INTO res;
   END LOOP;
   CLOSE cur;
END;

---------------------------
SET SERVEROUTPUT ON
begin
show_active_users;
end;

--/////////////////////////////////////////////////
-----------3 
CREATE OR  REPLACE PROCEDURE workers_by_departments
IS

CURSOR department_cursor IS
SELECT *
FROM departments;

all_departments department_cursor%ROWTYPE;

CURSOR worker_ids_with_dates(param_department_id IN INTEGER)
IS
SELECT worker_id, name, position_name, date_start, date_end
FROM 
(
	SELECT ch_1.worker_id, workers.surname name, positions.name position_name, ch_1.date_of_changing_position date_start, NVL(ch_2.date_of_changing_position, sysdate) date_end,
	ROW_NUMBER() OVER (PARTITION BY ch_1.worker_id, ch_1.date_of_changing_position ORDER BY ch_2.date_of_changing_position ASC) AS rownumber
	FROM changing_positions ch_1
	LEFT JOIN
	(
		SELECT worker_id, date_of_changing_position 
		FROM changing_positions
	) ch_2
	ON ch_1.worker_id = ch_2.worker_id AND ch_2.date_of_changing_position > ch_1.date_of_changing_position
	JOIN workers ON workers.worker_id = ch_1.worker_id
	JOIN positions ON positions.position_id = ch_1.position_id
	WHERE ch_1.position_id NOT IN(1) AND ch_1.department_id = param_department_id
)
WHERE rownumber = 1;
	
workers_cursor worker_ids_with_dates%ROWTYPE;

FUNCTION WORKED_TIME(param_worker_id IN INTEGER, param_date_from IN DATE, param_date_end IN DATE)
RETURN NUMBER
IS RESULT NUMBER;
BEGIN
	SELECT SUM(worked_time)
	INTO RESULT
	FROM working_time
	WHERE worker_id = param_worker_id 
	AND date_of_working_day >= param_date_from 
	AND date_of_working_day < param_date_end
	GROUP BY worker_id;
	
	RETURN RESULT;
EXCEPTION WHEN OTHERS THEN RETURN 0;
END;

BEGIN
	DBMS_OUTPUT.ENABLE;
	OPEN department_cursor;
	FETCH department_cursor
    INTO all_departments;
	WHILE department_cursor%FOUND
	LOOP
	DBMS_OUTPUT.put_line (all_departments.name);
	
	DECLARE count_hours NUMBER;
	
	BEGIN
		OPEN worker_ids_with_dates(all_departments.department_id);
		FETCH worker_ids_with_dates
		INTO workers_cursor;
		WHILE worker_ids_with_dates%FOUND
		LOOP
		
		count_hours:=WORKED_TIME(workers_cursor.worker_id,
								 workers_cursor.date_start,
								 workers_cursor.date_end);
		
		DBMS_OUTPUT.put_line ('-' || workers_cursor.worker_id
							  || '---' ||workers_cursor.name
							  || '---' ||workers_cursor.position_name
							  || '---' || workers_cursor.date_start
							  || '-' || workers_cursor.date_end
							  || '---'|| count_hours);
		
		FETCH worker_ids_with_dates
		INTO workers_cursor;
		END LOOP;
		CLOSE worker_ids_with_dates;
	END;
	
    FETCH department_cursor
    INTO all_departments;
    END LOOP;
	CLOSE department_cursor;
END;
---------------------------
begin
workers_by_departments;
end;
--///////////////////////////////////////

CREATE OR  REPLACE FUNCTION pensioners_by_departments(param_department_id IN INTEGER)
RETURN


SELECT * FROM get_active_users
WHERE department_id =1;
