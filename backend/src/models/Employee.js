const mongoose = require('mongoose');

const employeeSchema = new mongoose.Schema({
  tenantId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true,
    index: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  name: {
    type: String,
    required: [true, 'Employee name is required'],
    trim: true
  },
  role: {
    type: String,
    required: [true, 'Role/Designation is required'],
    trim: true
  },
  email: {
    type: String,
    trim: true
  },
  phone: {
    type: String,
    trim: true
  },
  monthlySalary: {
    type: Number,
    required: [true, 'Monthly salary is required'],
    min: 0
  },
  joinDate: {
    type: Date,
    required: [true, 'Join date is required'],
    default: Date.now
  },
  leaveDate: {
    type: Date
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, { timestamps: true });

employeeSchema.index({ tenantId: 1, name: 1 });

module.exports = mongoose.model('Employee', employeeSchema);
