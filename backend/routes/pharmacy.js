const express = require('express');
const router = express.Router();

// Pharmacy and location API routes
module.exports = (db) => {

  // 1. GET ALL PHARMACIES
  router.get('/', async (req, res) => {
    try {
      const { latitude, longitude, radius = 10 } = req.query;

      let query, params = [];

      if (latitude && longitude) {
        // Query with distance calculation
        query = `
          SELECT
            p.id, p.pharmacy_name as name, p.pharmacy_address as address,
            p.pharmacy_phone as phone, p.latitude, p.longitude,
            true as is_open, p.operating_hours as opening_hours, null as created_at,
            (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) *
             cos(radians(p.longitude) - radians($2)) +
             sin(radians($3)) * sin(radians(p.latitude)))) AS distance
          FROM pharmacies p
          WHERE p.latitude IS NOT NULL AND p.longitude IS NOT NULL
          AND (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) *
               cos(radians(p.longitude) - radians($2)) +
               sin(radians($3)) * sin(radians(p.latitude)))) <= $4
          ORDER BY distance ASC
        `;
        params = [parseFloat(latitude), parseFloat(longitude), parseFloat(latitude), parseFloat(radius)];
      } else {
        // Simple query without distance calculation
        query = `
          SELECT
            p.id, p.pharmacy_name as name, p.pharmacy_address as address,
            p.pharmacy_phone as phone, p.latitude, p.longitude,
            true as is_open, p.operating_hours as opening_hours, null as created_at,
            null as distance
          FROM pharmacies p
          ORDER BY p.pharmacy_name ASC
        `;
      }

      const result = await db.query(query, params);
      const pharmacies = result.rows;

      res.json({
        pharmacies: pharmacies.map(pharmacy => ({
          id: pharmacy.id,
          name: pharmacy.name,
          address: pharmacy.address,
          phone: pharmacy.phone,
          latitude: pharmacy.latitude ? parseFloat(pharmacy.latitude) : null,
          longitude: pharmacy.longitude ? parseFloat(pharmacy.longitude) : null,
          isOpen: pharmacy.is_open,
          openingHours: pharmacy.opening_hours || null,
          distance: pharmacy.distance ? parseFloat(pharmacy.distance).toFixed(2) : null,
          createdAt: pharmacy.created_at
        }))
      });

    } catch (error) {
      console.error('Get pharmacies error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 2. GET PHARMACY BY ID
  router.get('/:id', async (req, res) => {
    try {
      const { id } = req.params;

      const pharmacyResult = await db.query(
        'SELECT id, pharmacy_name as name, pharmacy_address as address, pharmacy_phone as phone, latitude, longitude, true as is_open, operating_hours as opening_hours, null as created_at, null as updated_at FROM pharmacies WHERE id = $1',
        [id]
      );

      if (pharmacyResult.rows.length === 0) {
        return res.status(404).json({ error: 'Pharmacy not found' });
      }

      const pharmacy = pharmacyResult.rows[0];

      // Get pharmacy products
      const productsResult = await db.query(
        'SELECT * FROM pharmacy_products WHERE pharmacy_id = $1 AND in_stock = TRUE ORDER BY name ASC',
        [id]
      );

      res.json({
        pharmacy: {
          id: pharmacy.id,
          name: pharmacy.name,
          address: pharmacy.address,
          phone: pharmacy.phone,
          latitude: pharmacy.latitude ? parseFloat(pharmacy.latitude) : null,
          longitude: pharmacy.longitude ? parseFloat(pharmacy.longitude) : null,
          isOpen: pharmacy.is_open,
          openingHours: pharmacy.opening_hours || null,
          createdAt: pharmacy.created_at,
          updatedAt: pharmacy.updated_at,
          products: productsResult.rows.map(product => ({
            id: product.id,
            name: product.name,
            category: product.category,
            price: product.price ? parseFloat(product.price) : null,
            inStock: product.in_stock,
            createdAt: product.created_at
          }))
        }
      });

    } catch (error) {
      console.error('Get pharmacy error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 3. SEARCH PHARMACIES
  router.get('/search/:query', async (req, res) => {
    try {
      const { query } = req.params;
      const { latitude, longitude } = req.query;
      const searchTerm = `%${query}%`;

      let sqlQuery = `
        SELECT
          p.id, p.pharmacy_name as name, p.pharmacy_address as address,
          p.pharmacy_phone as phone, p.latitude, p.longitude,
          true as is_open, p.operating_hours as opening_hours, null as created_at
      `;

      const params = [];
      let paramCount = 0;

      if (latitude && longitude) {
        paramCount += 3;
        sqlQuery += `, (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) *
                       cos(radians(p.longitude) - radians($2)) +
                       sin(radians($3)) * sin(radians(p.latitude)))) AS distance`;
        params.push(parseFloat(latitude), parseFloat(longitude), parseFloat(latitude));
      }

      sqlQuery += `
        FROM pharmacies p
        WHERE (p.pharmacy_name ILIKE $${paramCount + 1} OR p.pharmacy_address ILIKE $${paramCount + 2})
      `;
      params.push(searchTerm, searchTerm);

      sqlQuery += ` ORDER BY ${latitude && longitude ? 'distance ASC' : 'p.pharmacy_name ASC'}`;

      const result = await db.query(sqlQuery, params);
      const pharmacies = result.rows;

      res.json({
        pharmacies: pharmacies.map(pharmacy => ({
          id: pharmacy.id,
          name: pharmacy.name,
          address: pharmacy.address,
          phone: pharmacy.phone,
          latitude: pharmacy.latitude ? parseFloat(pharmacy.latitude) : null,
          longitude: pharmacy.longitude ? parseFloat(pharmacy.longitude) : null,
          isOpen: pharmacy.is_open,
          openingHours: pharmacy.opening_hours || null,
          distance: pharmacy.distance ? parseFloat(pharmacy.distance).toFixed(2) : null,
          createdAt: pharmacy.created_at
        })),
        searchQuery: query
      });

    } catch (error) {
      console.error('Search pharmacies error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 4. GET PHARMACY PRODUCTS
  router.get('/:id/products', async (req, res) => {
    try {
      const { id } = req.params;
      const { category, inStock } = req.query;

      // Check if pharmacy exists
      const pharmacyCheck = await db.query(
        'SELECT id FROM pharmacies WHERE id = $1',
        [id]
      );

      if (pharmacyCheck.rows.length === 0) {
        return res.status(404).json({ error: 'Pharmacy not found' });
      }

      let query = 'SELECT * FROM pharmacy_products WHERE pharmacy_id = $1';
      const params = [id];
      let paramCount = 1;

      if (category) {
        paramCount++;
        query += ` AND category = $${paramCount}`;
        params.push(category);
      }

      if (inStock !== undefined) {
        paramCount++;
        query += ` AND in_stock = $${paramCount}`;
        params.push(inStock === 'true');
      }

      query += ' ORDER BY name ASC';

      const result = await db.query(query, params);
      const products = result.rows;

      res.json({
        products: products.map(product => ({
          id: product.id,
          pharmacyId: product.pharmacy_id,
          name: product.name,
          category: product.category,
          price: product.price ? parseFloat(product.price) : null,
          inStock: product.in_stock,
          createdAt: product.created_at
        }))
      });

    } catch (error) {
      console.error('Get pharmacy products error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 5. SEARCH PRODUCTS ACROSS ALL PHARMACIES
  router.get('/products/search/:query', async (req, res) => {
    try {
      const { query } = req.params;
      const { category, latitude, longitude } = req.query;
      const searchTerm = `%${query}%`;

      let sqlQuery = `
        SELECT
          pp.*,
          p.pharmacy_name,
          p.pharmacy_address,
          p.pharmacy_phone,
          p.latitude as pharmacy_latitude,
          p.longitude as pharmacy_longitude,
          true as pharmacy_is_open
      `;

      const params = [];
      let paramCount = 0;

      if (latitude && longitude) {
        paramCount += 3;
        sqlQuery += `, (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) *
                       cos(radians(p.longitude) - radians($2)) +
                       sin(radians($3)) * sin(radians(p.latitude)))) AS distance`;
        params.push(parseFloat(latitude), parseFloat(longitude), parseFloat(latitude));
      }

      sqlQuery += `
        FROM pharmacy_products pp
        JOIN pharmacies p ON pp.pharmacy_id = p.id
        WHERE pp.name ILIKE $${paramCount + 1} AND pp.in_stock = TRUE
      `;
      params.push(searchTerm);
      paramCount++;

      if (category) {
        paramCount++;
        sqlQuery += ` AND pp.category = $${paramCount}`;
        params.push(category);
      }

      sqlQuery += ` ORDER BY ${latitude && longitude ? 'distance ASC,' : ''} pp.price ASC`;

      const result = await db.query(sqlQuery, params);
      const products = result.rows;

      res.json({
        products: products.map(product => ({
          id: product.id,
          name: product.name,
          category: product.category,
          price: product.price ? parseFloat(product.price) : null,
          inStock: product.in_stock,
          pharmacy: {
            id: product.pharmacy_id,
            name: product.pharmacy_name,
            address: product.pharmacy_address,
            phone: product.pharmacy_phone,
            latitude: product.pharmacy_latitude ? parseFloat(product.pharmacy_latitude) : null,
            longitude: product.pharmacy_longitude ? parseFloat(product.pharmacy_longitude) : null,
            isOpen: product.pharmacy_is_open,
            distance: product.distance ? parseFloat(product.distance).toFixed(2) : null
          },
          createdAt: product.created_at
        })),
        searchQuery: query
      });

    } catch (error) {
      console.error('Search products error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 6. GET PRODUCT CATEGORIES
  router.get('/categories/list', async (req, res) => {
    try {
      const result = await db.query(
        'SELECT DISTINCT category FROM pharmacy_products ORDER BY category'
      );

      res.json({
        categories: result.rows.map(row => row.category)
      });

    } catch (error) {
      console.error('Get categories error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // 7. GET NEARBY PHARMACIES WITH SPECIFIC PRODUCT
  router.get('/nearby-with-product/:productName', async (req, res) => {
    try {
      const { productName } = req.params;
      const { latitude, longitude, radius = 10 } = req.query;

      if (!latitude || !longitude) {
        return res.status(400).json({
          error: 'Latitude and longitude are required for nearby search'
        });
      }

      const searchTerm = `%${productName}%`;

      const result = await db.query(
        `SELECT DISTINCT
          p.id, p.pharmacy_name as name, p.pharmacy_address as address,
          p.pharmacy_phone as phone, p.latitude, p.longitude,
          true as is_open, p.operating_hours as opening_hours,
          (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) *
           cos(radians(p.longitude) - radians($2)) +
           sin(radians($3)) * sin(radians(p.latitude)))) AS distance,
          COUNT(pp.id) as matching_products
         FROM pharmacies p
         JOIN pharmacy_products pp ON p.id = pp.pharmacy_id
         WHERE pp.name ILIKE $4 AND pp.in_stock = TRUE
         GROUP BY p.id, p.pharmacy_name, p.pharmacy_address, p.pharmacy_phone, p.latitude, p.longitude, p.operating_hours
         HAVING (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) *
           cos(radians(p.longitude) - radians($2)) +
           sin(radians($3)) * sin(radians(p.latitude)))) <= $5
         ORDER BY distance ASC, matching_products DESC`,
        [
          parseFloat(latitude),
          parseFloat(longitude),
          parseFloat(latitude),
          searchTerm,
          parseFloat(radius)
        ]
      );

      res.json({
        pharmacies: result.rows.map(pharmacy => ({
          id: pharmacy.id,
          name: pharmacy.name,
          address: pharmacy.address,
          phone: pharmacy.phone,
          latitude: parseFloat(pharmacy.latitude),
          longitude: parseFloat(pharmacy.longitude),
          isOpen: pharmacy.is_open,
          openingHours: pharmacy.opening_hours || null,
          distance: parseFloat(pharmacy.distance).toFixed(2),
          matchingProducts: pharmacy.matching_products
        })),
        searchProduct: productName,
        searchRadius: parseFloat(radius)
      });

    } catch (error) {
      console.error('Get nearby pharmacies with product error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  return router;
};