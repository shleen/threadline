from django.core.exceptions import ObjectDoesNotExist
from django.db import connection

from .models import User


def get_or_create_user(username):
    """
    Returns a user object with a matching username from the database.
    If the given username does not exist, create a new user and return. 
    """
    try:
        user = User.objects.get(username=username)
    except ObjectDoesNotExist:
        user = User(username=username)
        user.save()
    
    return user


def filter_and_rank(context):
    """
    Raw SQL query to perform weather filtering and garment ranking
    entirely on the database. Returns the top items for each type of 
    garment. Context includes the username and parameters computed for 
    weather filtering from the API call.

    Code (Lines 32-35) for query execution and converting database records into dictionaries is
    from the official django docs (see dictfetchall function and 'Executing custom SQL directly')
    https://docs.djangoproject.com/en/5.1/topics/db/sql/
    """
    with connection.cursor() as cursor:
        cursor.execute(ranking_query(context), [context["username"]])
        columns = [col[0] for col in cursor.description]
        records = [dict(zip(columns, row)) for row in cursor.fetchall()]

    ranked_queues = {}

    # Group garments into queues based on their type
    for rec in records:
        queue = ranked_queues.get(rec["type"], [])
        queue.append(rec)
        ranked_queues[rec["type"]] = queue

    return ranked_queues

def item_match(ranked):
    """
    Matches clothes from ranking stage to form outfits. The full 
    implementation is an MVP feature so for skeletal it is minimial
    and will just create up to 5 outfits of top, bottom, and shoes.
    """
    if len(ranked.keys()) == 0:
        return []

    outfits = []
    while len(ranked["TOP"]) > 0 and len(ranked["BOTTOM"]) > 0 and len(ranked["SHOES"]) > 0:
        outfit = {}
        for k, queue in ranked.items():
            if k == "DRESS" or k == "OUTERWEAR":
                outfit[k] = None
                continue
            garment = queue.pop()
            outfit[k] = {"id": garment["cloth_id"], "img": garment["img_filename"]}

        outfits.append(outfit)

    return outfits


def ranking_query(context):
    """
    Returns the query to perform item ranking.
    """
    precip_where = "AND 1=0" if context["precip"] is None else "AND precip = " + "\'" + context["precip"] + "\'"

    return f"""
        WITH 
        USER_CLOTHES AS (
            SELECT *, C.id AS cloth_id
            FROM core_clothing C
            JOIN core_user U
                ON C.user_id = U.id
            WHERE U.username = %s
        ),
        GARMENTS AS (
            SELECT *
            FROM USER_CLOTHES U
            LEFT JOIN core_outfititem O
                ON U.cloth_id = O.clothing_id
            WHERE U.winter IS {"TRUE" if context["iswinter"] else "NOT TRUE"}
        ),
        COUNTS_GARMENTS AS (
            SELECT CAST(COUNT(*) AS FLOAT) AS count, T1.subtype AS attribute, T1.type AS type
                FROM GARMENTS T1
                WHERE T1.outfit_id IS NOT NULL
            GROUP BY T1.subtype, T1.type
            UNION ALL
            SELECT CAST(COUNT(*) AS FLOAT) AS count, T2.fit AS attribute, T2.type AS type
                FROM GARMENTS T2
                WHERE T2.outfit_id IS NOT NULL
            GROUP BY T2.fit, T2.type
            UNION ALL 
            SELECT CAST(COUNT(*) AS FLOAT) AS count, T3.occasion AS attribute, T3.type AS type
                FROM GARMENTS T3
                WHERE T3.outfit_id IS NOT NULL
            GROUP BY T3.occasion, T3.type
        ),
        WEAR_COUNTS_GARMENTS AS (
            SELECT (-1 / (CAST(COUNT(*) AS FLOAT) + 2)) + 0.5 AS num_wear_weight, C.id
            FROM core_outfititem O
            JOIN core_clothing C
                ON O.clothing_id = C.id
            GROUP BY C.id
        ),
        WEIGHTS_GARMENTS AS (
            SELECT *,
            CASE
                WHEN (SELECT COUNT(*) FROM GARMENTS WHERE type = C.type AND outfit_id IS NOT NULL) = 0 THEN 0.0
                ELSE C.count / (SELECT COUNT(*) FROM GARMENTS WHERE type = C.type AND outfit_id IS NOT NULL)
            END weight
            FROM COUNTS_GARMENTS C
        ),
        WEIGHTED AS (
            SELECT T.cloth_id, T.outfit_id, T.type, T.fit, T.subtype, T.occasion, T.img_filename,
                T.color_lstar, T.color_astar, T.color_bstar, T.layerable, T.precip,
            CASE
                WHEN W1.weight IS NULL THEN 0.0
                ELSE W1.weight
            END sub_type_weight,
            CASE 
                WHEN W2.weight IS NULL THEN 0.0
                ELSE W2.weight
            END fit_weight,
            CASE 
                WHEN W3.weight IS NULL THEN 0.0
                ELSE W3.weight
            END occasion_weight
            FROM GARMENTS T
            LEFT JOIN WEIGHTS_GARMENTS W1
                ON (W1.attribute = T.subtype AND W1.type = T.type)
            LEFT JOIN WEIGHTS_GARMENTS W2
                ON (W2.attribute = T.fit AND W2.type = T.type)
            LEFT JOIN WEIGHTS_GARMENTS W3
                ON (W3.attribute = T.occasion AND W3.type = T.type)
        ),
        TIMED AS (
            SELECT *, 
            CASE
                WHEN (SELECT COUNT(*) FROM WEIGHTED) = 0 THEN 0.0
                WHEN O.date_worn IS NULL THEN 0.0
                ELSE 10 / EXTRACT(EPOCH FROM (NOW() - O.date_worn))
            END time_const,
            CASE
                WHEN C.num_wear_weight IS NULL THEN 0.0
                ELSE C.num_wear_weight
            END wear_weight
            FROM WEIGHTED W
            LEFT JOIN core_outfit O
                ON W.outfit_id = O.id
            LEFT JOIN WEAR_COUNTS_GARMENTS C
                    ON W.cloth_id = C.id
        ),
        RANKED_TOPS AS (
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip,
                fit_weight + sub_type_weight + occasion_weight + random() * 0.3 - time_const - wear_weight AS score
                FROM TIMED
                WHERE type = 'TOP'
            ORDER BY score DESC
                LIMIT 5)
                UNION
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip, 0.0 AS score
                FROM USER_CLOTHES
                WHERE type = 'TOP'
                {precip_where}
                LIMIT 2)
        ),
        RANKED_BOTTOMS AS (
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip,
                fit_weight + sub_type_weight + occasion_weight + random() * 0.3 - time_const - wear_weight AS score
                FROM TIMED
                WHERE type = 'BOTTOM'
            ORDER BY score DESC
                LIMIT 5)
                UNION
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip, 0.0 AS score
                FROM USER_CLOTHES
                WHERE type = 'BOTTOM'
                {precip_where}
                LIMIT 2)
        ),
        RANKED_OUTERWEAR AS (
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip,
                fit_weight + sub_type_weight + occasion_weight + random() * 0.3 - time_const - wear_weight AS score
                FROM TIMED
                WHERE type = 'OUTERWEAR'
            ORDER BY score DESC
                LIMIT 5)
                UNION
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip, 0.0 AS score
                FROM USER_CLOTHES
                WHERE type = 'OUTERWEAR'
                {precip_where}
                LIMIT 2)
                
        ),
        RANKED_DRESSES AS (
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip,
                fit_weight + sub_type_weight + occasion_weight + random() * 0.3 - time_const - wear_weight AS score
                FROM TIMED
                WHERE type = 'DRESS'
            ORDER BY score DESC
                LIMIT 5)
                UNION
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip, 0.0 AS score
                FROM USER_CLOTHES
                WHERE type = 'DRESS'
                {precip_where}
                LIMIT 2)
        ),
        RANKED_SHOES AS (
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip,
                fit_weight + sub_type_weight + occasion_weight + random() * 0.3 - time_const - wear_weight AS score
                FROM TIMED
                WHERE type = 'SHOES'
            ORDER BY score DESC
                LIMIT 5)
                UNION
            (SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, precip, 0.0 AS score
                FROM USER_CLOTHES
                WHERE type = 'SHOES'
                {precip_where}
                LIMIT 2)
        )

        SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, score
            FROM RANKED_TOPS
        UNION ALL
        SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, score
            FROM RANKED_BOTTOMS
        UNION ALL
        SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, score
            FROM RANKED_OUTERWEAR
        UNION ALL
        SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, score
            FROM RANKED_DRESSES
        UNION ALL
        SELECT cloth_id, type, img_filename, subtype, color_lstar, color_astar, color_bstar, fit, layerable, score
            FROM RANKED_SHOES;
           """
