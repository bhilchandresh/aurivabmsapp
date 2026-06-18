const express = require('express');
const router = express.Router();
const { 
  registerTenant, 
  login, 
  getTenantSettings, 
  updateTenantSettings, 
  getAllTenants, 
  updateTenantBySuperAdmin,
  getTenantUsage,
  getSystemStats,    // <--- Import
  deleteTenant,      // <--- Import
  createTenantByAdmin, // <--- Import
  resetAdminPassword   // <--- Added
} = require('../controllers/authController');

const { protect, authorize } = require('../middleware/authMiddleware');
const { getAuditLogs } = require('../controllers/authController');

// Public
router.post('/register', registerTenant);
router.post('/login', login);

// Tenant Settings
router.get('/settings', protect, getTenantSettings);
router.put('/settings', protect, updateTenantSettings);

// SUPER ADMIN ROUTES
router.get('/tenants', protect, authorize('super_admin'), getAllTenants);
router.post('/tenants', protect, authorize('super_admin'), createTenantByAdmin); // Create
router.put('/tenants/:id', protect, authorize('super_admin'), updateTenantBySuperAdmin); // Update
router.put('/tenants/:id/password', protect, authorize('super_admin'), resetAdminPassword); // Reset Password
router.delete('/tenants/:id', protect, authorize('super_admin'), deleteTenant); // Delete
router.get('/stats', protect, authorize('super_admin'), getSystemStats); // Stats
// Add Route
router.get('/tenants/:id/usage', protect, authorize('super_admin'), getTenantUsage);
router.get('/logs', protect, authorize('super_admin'), getAuditLogs);

module.exports = router;