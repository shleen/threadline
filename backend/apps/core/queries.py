from django.db import connection


def execute_read_query(sql, params):
    """
    Executes a parameterized raw sql query and makes a dictionary for each record.
    Returns the records fetched.

    Code (Lines 32-35) for query execution and converting database records into dictionaries is
    from the official django docs (see dictfetchall function and 'Executing custom SQL directly')
    https://docs.djangoproject.com/en/5.1/topics/db/sql/
    """
    with connection.cursor() as cursor:
        cursor.execute(sql, params)
        columns = [col[0] for col in cursor.description]
        records = [dict(zip(columns, row)) for row in cursor.fetchall()]
    
    return records

def prev_outfit_query():
    """
    Returns the query to fetch up to 15 previously worn outfits
    """
    return """
        SELECT O1.outfit_id, O1.clothing_id, C.img_filename, O2.date_worn
          FROM core_outfititem O1
          JOIN core_outfit O2
            ON O1.outfit_id = O2.id
          JOIN core_clothing C
            ON O1.clothing_id = C.id
          JOIN core_user U
            ON U.id = C.user_id
         WHERE U.username = %s
      ORDER BY O1.outfit_id
    """


def utilization_query():
    """
    Returns a query that computes the total percent utilization of 
    the wardrobe, and utilization for each type of clothing that has
    been worn.
    """
    return """
    WITH 
    USER_CLOTHES AS (
        SELECT C.id, C.type, C.img_filename
        FROM core_clothing C
        JOIN core_user U
            ON C.user_id = U.id
        WHERE U.username = %s
          AND C.is_deleted IS FALSE
    ),
    WORN_CLOTHES AS (
        SELECT U.id, U.type, U.img_filename, I.outfit_id
        FROM USER_CLOTHES U
            JOIN core_outfititem I
            ON U.id = I.clothing_id
            JOIN core_outfit O
            ON O.id = I.outfit_id
        WHERE O.date_worn >= date_trunc('day', NOW() - interval '1 month')
    ),
    DISTINCT_COUNTS AS (
        SELECT CAST(COUNT(*) AS FLOAT) AS counts, W.type
        FROM (
            SELECT DISTINCT id, type 
            FROM WORN_CLOTHES
        ) W
        GROUP BY W.type
    ),
    TYPE_PERCENT AS (
        SELECT D.type AS util_type,
        CASE 
            WHEN (SELECT COUNT(*) FROM USER_CLOTHES WHERE type = D.type) = 0 THEN 0.0
            ELSE ROUND(D.counts::numeric / (SELECT COUNT(*) FROM USER_CLOTHES WHERE type = D.type), 2)
        END AS percent
        FROM DISTINCT_COUNTS D
    )

    (SELECT 'TOTAL' AS util_type,
        CASE
            WHEN (SELECT COUNT(*) FROM USER_CLOTHES) = 0 THEN 0.0
            WHEN (SELECT COUNT(*) FROM DISTINCT_COUNTS) = 0 THEN 0.0
            ELSE ROUND(SUM(D.counts)::numeric / (SELECT COUNT(*) FROM USER_CLOTHES), 2)
        END AS percent
        FROM DISTINCT_COUNTS D)
    UNION ALL
    (SELECT T.util_type,
       CASE
         WHEN P.percent IS NULL THEN 0.0
         ELSE P.percent
        END AS percent
       FROM TYPE_PERCENT P
 RIGHT JOIN (SELECT DISTINCT type AS util_type FROM USER_CLOTHES) T
         ON T.util_type = P.util_type
       );
    """


def rewears_query(context):
    """
    Raw SQL query to find the items that were reworn (i.e., worn more than once)
    the most in the last month
    """
    query = """
    WITH
    REWORN_CLOTHES AS (
        SELECT COUNT(*) AS wears, W.id, W.type, W.img_filename
        FROM (
            SELECT C.id, C.type, C.img_filename
            FROM core_clothing C
            JOIN core_outfititem I
                ON C.id = I.clothing_id
            JOIN core_outfit O
                ON O.id = I.outfit_id
            JOIN core_user U
                ON U.id = C.user_id
            WHERE O.date_worn >= date_trunc('day', NOW() - interval '1 month')
            AND U.username = %s
            AND C.is_deleted IS FALSE
        ) W
        GROUP BY W.id, W.type, W.img_filename
            HAVING COUNT(*) > 1
    )
    
    SELECT *
      FROM (
    """
    for cl_type in context["clothing_types"]:
        query += f"""
        (SELECT R.id, R.type, R.img_filename, R.wears
            FROM REWORN_CLOTHES R
            WHERE R.type = '{cl_type}'
            AND R.wears = (
            SELECT MAX(wears)
            FROM REWORN_CLOTHES
            WHERE type = '{cl_type}')
            LIMIT 1)
        """
        if cl_type != context["clothing_types"][-1]:
              query += "UNION ALL"

    query += """
    ) R
    ORDER BY R.type
    """

    return query


def ranking_query(context):
    """
    Returns the query to perform item ranking.
    """
    precip_where = " WHERE 1=0" if context["precip"] is None else " WHERE precip IS NOT NULL"

    query = f"""
    WITH 
    USER_CLOTHES AS (
        SELECT C.id, C.type, C.subtype, C.fit, C.occasion, C.img_filename,
               C.color_lstar, C.color_astar, C.color_bstar, C.layerable, C.precip,
               C.is_deleted
          FROM core_clothing C
          JOIN core_user U
            ON C.user_id = U.id
         WHERE U.username = %s
           AND C.weather = '{context["weather"]}'
    ),
    WORN_CLOTHES AS (
        SELECT U.id, U.type, U.subtype, U.fit, U.occasion
          FROM USER_CLOTHES U
          JOIN core_outfititem I
            ON U.id = I.clothing_id
          JOIN core_outfit O
            ON O.id = I.outfit_id
    ),
    SUBTYPE_GROUPING AS (
        SELECT CAST(COUNT(*) AS FLOAT) AS counts, W.subtype AS subtype, W.type AS type
          FROM WORN_CLOTHES W
      GROUP BY W.subtype, W.type
    ),
    SUBTYPE_WEIGHTS AS (
        SELECT 	counts /
            (SELECT SUM(counts)
               FROM SUBTYPE_GROUPING S2
              WHERE S2.type = S1.type) / 3
            AS weight, S1.type, S1.subtype
          FROM SUBTYPE_GROUPING S1
    ),
    FIT_GROUPING AS (
        SELECT CAST(COUNT(*) AS FLOAT) AS counts, W.fit AS fit, W.type AS type
          FROM WORN_CLOTHES W
      GROUP BY W.fit, W.type
    ),
    FIT_WEIGHTS AS (
        SELECT 	counts /
            (SELECT SUM(counts)
               FROM FIT_GROUPING F2
              WHERE F2.type = F1.type) / 3
            AS weight, F1.type, F1.fit
          FROM FIT_GROUPING F1
    ),
    OCCASION_GROUPING AS (
        SELECT CAST(COUNT(*) AS FLOAT) AS counts, W.occasion AS occasion, W.type AS type
          FROM WORN_CLOTHES W
      GROUP BY W.occasion, W.type
    ),
    OCCASION_WEIGHTS AS (
        SELECT 	counts /
            (SELECT SUM(counts)
               FROM OCCASION_GROUPING O2
              WHERE O2.type = O1.type) / 3
            AS weight, O1.type, O1.occasion
          FROM OCCASION_GROUPING O1
    ),
    WEAR_TIMES AS (
        SELECT MAX(date_worn) AS recent_date, I.clothing_id
          FROM core_outfititem I
          JOIN core_outfit O
            ON I.outfit_id = O.id
      GROUP BY I.clothing_id
    ),
    TIME_DEDUCTIONS AS (
        SELECT clothing_id,
          CASE
              WHEN recent_date >= date_trunc('day', NOW() - interval '3' day) THEN 0.25
              WHEN recent_date < date_trunc('day', NOW() - interval '3' day)
              AND recent_date >= date_trunc('day', NOW() - interval '10' day) THEN 0.75
              ELSE 1.0
           END AS time_deduct
          FROM WEAR_TIMES
    ),
    WEIGHTED_CLOTHES AS (
        SELECT U.id, U.type, U.subtype, U.fit, U.occasion, U.img_filename, 
            U.color_lstar, U.color_astar, U.color_bstar, U.layerable, U.precip,
          CASE 
              WHEN S.weight IS NULL THEN 0.0
              ELSE S.weight
           END AS subtype_weight,
          CASE 
              WHEN F.weight IS NULL THEN 0.0
              ELSE F.weight
           END AS fit_weight,
          CASE 
              WHEN O.weight IS NULL THEN 0.0
              ELSE O.weight
           END AS occasion_weight,
          CASE 
              WHEN T.time_deduct IS NULL THEN 1.0
              ELSE T.time_deduct
           END AS time_deduct
          FROM USER_CLOTHES U
     LEFT JOIN SUBTYPE_WEIGHTS S
            ON (S.subtype IS NULL AND U.subtype IS NULL AND S.type = U.type)
            OR (S.subtype = U.subtype AND S.type = U.type)
     LEFT JOIN FIT_WEIGHTS F
            ON F.fit = U.fit
           AND F.type = U.type
     LEFT JOIN OCCASION_WEIGHTS O
            ON O.occasion = U.occasion
           AND O.type = U.type
     LEFT JOIN TIME_DEDUCTIONS T
            ON T.clothing_id = U.id
         WHERE U.is_deleted IS FALSE
    ),
    SCORED AS (
        SELECT *, time_deduct * (subtype_weight + fit_weight + occasion_weight) + random() * 0.05 AS score
          FROM WEIGHTED_CLOTHES
    ),
    """

    for cl_type in context["clothing_types"]:
      query += f"""
          RANKED_{cl_type} AS (
              (SELECT id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip
                FROM SCORED
                WHERE type = '{cl_type}'
            ORDER BY score DESC
                LIMIT 5)
                  UNION
              (SELECT id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip
                FROM (SELECT * FROM USER_CLOTHES {precip_where} AND is_deleted IS FALSE) U
                WHERE type = '{cl_type}'
                  AND precip = '{context["precip"]}' 
                LIMIT 1)
          )
        """
      if cl_type != context["clothing_types"][-1]:
        query += ","

    for cl_type in context["clothing_types"]:
      query += f"""
          SELECT id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit
            FROM RANKED_{cl_type}          
            """
      if cl_type != context["clothing_types"][-1]:
        query += "UNION ALL"

    return query

def declutter_query():
    """
    Returns the query to perform declutter recommending. Pulls 
    the least worn items, worn over a month ago from today or not at all
    """
    return """
      WITH 
      USER_CLOTHES AS (
        SELECT C.id, C.img_filename, C.created_at
          FROM core_clothing C
          JOIN core_user U
            ON C.user_id = U.id
         WHERE U.username = %s
           AND C.is_deleted IS FALSE
      ),
      WORN_CLOTHES AS (
        SELECT U.id, O.date_worn
          FROM USER_ClOTHES U
          JOIN core_outfititem I
            ON U.id = I.clothing_id
          JOIN core_outfit O
            ON I.outfit_id = O.id
      ),
      WEAR_COUNTS AS (
            SELECT W.id, COUNT(*) AS wears, MAX(W.date_worn) AS recent
              FROM WORN_CLOTHES W
          GROUP BY W.id
      )
        SELECT U.id, U.img_filename, W.recent,
          CASE
              WHEN W.wears IS NULL THEN 0
              ELSE W.wears
           END AS wear_counts
          FROM USER_CLOTHES U
     LEFT JOIN WEAR_COUNTS W
            ON U.id = W.id
         WHERE (W.recent IS NULL
            OR W.recent < date_trunc('day', NOW() - interval '1 month'))
           AND U.created_at < date_trunc('day', NOW() - interval '1 month')
      ORDER BY wear_counts
    """

