use airbnb_db

-- ¿Qué barrios tienen mayor oferta de alojamientos?
SELECT n.neighbourhood, COUNT(l.listing_id) AS total_listings
FROM listings l
JOIN neighbourhoods n ON l.neighbourhood_id = n.neighbourhood_id
GROUP BY n.neighbourhood
ORDER BY total_listings DESC
LIMIT 10;

-- ¿Qué anfitriones tienen más propiedades ofertadas?
SELECT h.host_name, h.calculated_host_listings_count
FROM hosts h
ORDER BY h.calculated_host_listings_count DESC
LIMIT 10;

-- Precio promedio por tipo de habitación y barrio
SELECT n.neighbourhood_group, l.room_type, ROUND(AVG(l.price), 2) AS avg_price
FROM listings l
JOIN neighbourhoods n ON l.neighbourhood_id = n.neighbourhood_id
GROUP BY n.neighbourhood_group, l.room_type
ORDER BY n.neighbourhood_group, avg_price DESC;

-- Distribución de precios por tipo de alojamiento
SELECT room_type, 
MAX(price) AS max_price, 
ROUND(AVG(price), 2) AS avg_price
FROM listings
GROUP BY room_type;

-- Análisis de precios pre COVID por borough
-- Hipótesis: Manhattan, Staten Island y Brooklyn tenían precios medios de Airbnb significativamente más altos en 2019.
-- Qué aporta: descubre qué borough era más caro y cuantifica su dispersión.
SELECT n.neighbourhood_group AS borough,
ROUND(AVG(l.price),2) AS avg_price_2019,
ROUND(STDDEV_POP(l.price),2) AS std_price
FROM listings l
JOIN neighbourhoods n ON l.neighbourhood_id = n.neighbourhood_id
GROUP BY borough
ORDER BY avg_price_2019 DESC;

-- Densidad de listings vs precios.
-- Hipótesis: Los vecindarios con más listings (oferta alta) tienen precios ligeramente más bajos por economía de escala.
-- Qué aporta: identifica “busters” (barrios con mucha oferta y precios bajos) vs. “hot spots”.
SELECT n.neighbourhood,
COUNT(*) AS n_listings,
ROUND(AVG(l.price),2) AS avg_price
FROM listings l
JOIN neighbourhoods n ON l.neighbourhood_id = n.neighbourhood_id
GROUP BY n.neighbourhood
HAVING n_listings > 50
ORDER BY avg_price ASC
LIMIT 10;

-- Efecto de la experiencia del host
-- Hipótesis: Hosts con más listados (calculated_host_listings_count) tienden a mantener precios más altos.
-- Qué aporta: segmenta a los hosts por tamaño y ve cómo fijan precios.
SELECT
CASE
WHEN h.calculated_host_listings_count = 1 THEN 'Solo 1'
WHEN h.calculated_host_listings_count BETWEEN 2 AND 5 THEN '2-5'
ELSE '6+'
END AS host_segmentation,
ROUND(AVG(l.price),2) AS avg_price
FROM listings l
JOIN hosts h ON l.host_id = h.host_id
GROUP BY host_segmentation
ORDER BY avg_price DESC;

-- Temporada baja vs. alta de disponibilidad
-- Hipótesis: Los precios son más bajos en listings con baja disponibilidad (poca demanda) y viceversa.
-- Qué aporta: relación inversa entre disponibilidad y precio.
SELECT
CASE
WHEN l.availability_365 < 100 THEN 'Low avail'
WHEN l.availability_365 BETWEEN 100 AND 250 THEN 'Med avail'
ELSE 'High avail'
END AS avail_segment,
ROUND(AVG(l.price),2) AS avg_price
FROM listings l
GROUP BY avail_segment
ORDER BY avg_price DESC;

-- Estacionalidad de reseñas (CTE + ventana)
-- Hipótesis: Hay meses con picos de reseñas que reflejan la temporada turística (jun–ago).
-- Qué aporta: detecta temporada alta de actividad.
WITH monthly_reviews AS (
  SELECT
    EXTRACT(MONTH FROM r.last_review) AS month,
    COUNT(*) AS reviews_count
  FROM reviews r
  WHERE r.last_review IS NOT NULL
  GROUP BY month
)
SELECT
  month,
  reviews_count,
  ROUND(100 * reviews_count / SUM(reviews_count) OVER (),2) AS pct_total
FROM monthly_reviews
ORDER BY reviews_count DESC;

-- Identificar “superhosts” potenciales (subquery)
-- Hipótesis: Hosts con un promedio de reseñas por mes alto (>1.5) y muchos listings podrían ser “superhosts”.
-- Qué aporta: perfil de los hosts más exitosos.
SELECT
h.host_id,
h.host_name,
AVG(r.reviews_per_month) AS avg_reviews_per_month,
h.calculated_host_listings_count
FROM hosts h
JOIN listings l ON h.host_id = l.host_id
JOIN reviews r ON l.listing_id = r.listing_id
GROUP BY h.host_id
HAVING avg_reviews_per_month > 1.5
ORDER BY h.calculated_host_listings_count DESC
LIMIT 10;

-- Índice de “saturación Airbnb” (window function)
-- Hipótesis: Existe una relación entre saturación (n_listings / población estimada) y precios, pero como no tenemos población, usamos densidad relativa.
-- Qué aporta: barrios con más “presión” de Airbnb.
SELECT DISTINCT
n.neighbourhood_group AS borough,
n.neighbourhood,
COUNT(*) OVER (PARTITION BY n.neighbourhood) AS listings_count,
ROUND(AVG(l.price) OVER (PARTITION BY n.neighbourhood), 2) AS avg_price
FROM listings l
JOIN neighbourhoods n ON l.neighbourhood_id = n.neighbourhood_id
ORDER BY listings_count DESC
LIMIT 10;
