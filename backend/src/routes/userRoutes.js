const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const checkSubscription = require('../middleware/checkSubscription');
const { 
  getTeamMembers, 
  addTeamMember, 
  deleteTeamMember, 
  updateTeamMember 
} = require('../controllers/userController');

// Protect all routes
router.use(protect);

// Only Admins (Tenant Owners) can manage the team
router.route('/')
  .get(authorize('admin', 'super_admin'), getTeamMembers)
  .post(authorize('admin', 'super_admin'), checkSubscription, addTeamMember);

// Individual User Operations
router.route('/:id')
  .delete(authorize('admin', 'super_admin'), deleteTeamMember) // Removed the semicolon here to chain correctly
  .put(authorize('admin', 'super_admin'), updateTeamMember);   // Added the update route

module.exports = router;