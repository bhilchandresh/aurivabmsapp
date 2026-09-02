const Employee = require('../models/Employee');
const EmployeeTransaction = require('../models/EmployeeTransaction');

// Helper to auto-calculate and upsert salary credits
const syncEmployeeSalary = async (employee, tenantId) => {
  if (!employee.joinDate || !employee.monthlySalary) return;
  
  const today = new Date();
  let current = new Date(employee.joinDate);
  current.setHours(0, 0, 0, 0); // Start of day

  while (current <= today || (current.getFullYear() === today.getFullYear() && current.getMonth() === today.getMonth())) {
    const year = current.getFullYear();
    const month = current.getMonth();
    const monthStr = `${year}-${(month + 1).toString().padStart(2, '0')}`;
    
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    
    // Calculate start day (join date if it's the first month, otherwise 1)
    const isJoinMonth = year === employee.joinDate.getFullYear() && month === employee.joinDate.getMonth();
    const startDay = isJoinMonth ? employee.joinDate.getDate() : 1;
    
    // Calculate end day (today if it's the current month, otherwise last day of month)
    const isCurrentMonth = year === today.getFullYear() && month === today.getMonth();
    const endDay = isCurrentMonth ? today.getDate() : daysInMonth;
    
    const daysWorked = endDay - startDay + 1;
    
    if (daysWorked > 0) {
      const amount = Math.round((employee.monthlySalary / daysInMonth) * daysWorked);
      const description = `Salary for ${new Date(year, month).toLocaleString('default', { month: 'short', year: 'numeric' })} (Auto)`;
      
      await EmployeeTransaction.updateOne(
        { employeeId: employee._id, tenantId, type: 'Salary Credit', forMonth: monthStr },
        {
          $set: {
            amount,
            description,
            date: new Date(year, month, endDay)
          }
        },
        { upsert: true }
      );
    }
    
    // Move to next month
    current = new Date(year, month + 1, 1);
    if (current > today && !(current.getFullYear() === today.getFullYear() && current.getMonth() === today.getMonth())) {
      break;
    }
  }
};

exports.getEmployees = async (req, res) => {
  try {
    const employees = await Employee.find({ tenantId: req.user.tenantId })
      .populate('createdBy', 'name email')
      .sort({ createdAt: -1 });

    // Calculate balance for each employee
    const employeesWithBalance = await Promise.all(employees.map(async (emp) => {
      await syncEmployeeSalary(emp, req.user.tenantId);
      
      const transactions = await EmployeeTransaction.find({ employeeId: emp._id, tenantId: req.user.tenantId });
      let balance = 0;
      transactions.forEach(t => {
        if (t.type === 'Salary Credit') balance += t.amount;
        if (t.type === 'Payment' || t.type === 'Advance' || t.type === 'Deduction') balance -= t.amount;
      });
      return { ...emp.toObject(), currentBalance: balance };
    }));

    res.status(200).json({ success: true, count: employeesWithBalance.length, data: employeesWithBalance });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getEmployee = async (req, res) => {
  try {
    const employee = await Employee.findOne({ _id: req.params.id, tenantId: req.user.tenantId })
      .populate('createdBy', 'name email');
    if (!employee) return res.status(404).json({ success: false, message: 'Employee not found' });
    res.status(200).json({ success: true, data: employee });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createEmployee = async (req, res) => {
  try {
    const newEmployee = await Employee.create({
      ...req.body,
      tenantId: req.user.tenantId,
      createdBy: req.user._id
    });
    res.status(201).json({ success: true, data: newEmployee });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.updateEmployee = async (req, res) => {
  try {
    const employee = await Employee.findOneAndUpdate(
      { _id: req.params.id, tenantId: req.user.tenantId },
      req.body,
      { new: true, runValidators: true }
    );
    if (!employee) return res.status(404).json({ success: false, message: 'Employee not found' });
    res.status(200).json({ success: true, data: employee });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteEmployee = async (req, res) => {
  try {
    const employee = await Employee.findOneAndDelete({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!employee) return res.status(404).json({ success: false, message: 'Employee not found' });
    
    // Optionally delete related transactions or keep them for history?
    // Let's delete them to avoid orphaned records.
    await EmployeeTransaction.deleteMany({ employeeId: req.params.id, tenantId: req.user.tenantId });

    res.status(200).json({ success: true, data: {} });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Transactions
exports.getEmployeeTransactions = async (req, res) => {
  try {
    const employee = await Employee.findOne({ _id: req.params.id, tenantId: req.user.tenantId });
    if (employee) await syncEmployeeSalary(employee, req.user.tenantId);
    
    const transactions = await EmployeeTransaction.find({
      employeeId: req.params.id,
      tenantId: req.user.tenantId
    })
    .populate('createdBy', 'name email')
    .sort({ date: -1, createdAt: -1 });
    res.status(200).json({ success: true, count: transactions.length, data: transactions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.addTransaction = async (req, res) => {
  try {
    const employee = await Employee.findOne({ _id: req.params.id, tenantId: req.user.tenantId });
    if (!employee) return res.status(404).json({ success: false, message: 'Employee not found' });

    const tx = await EmployeeTransaction.create({
      ...req.body,
      employeeId: employee._id,
      tenantId: req.user.tenantId,
      createdBy: req.user._id
    });

    res.status(201).json({ success: true, data: tx });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteTransaction = async (req, res) => {
  try {
    const tx = await EmployeeTransaction.findOneAndDelete({
      _id: req.params.txId,
      employeeId: req.params.id,
      tenantId: req.user.tenantId
    });
    if (!tx) return res.status(404).json({ success: false, message: 'Transaction not found' });
    res.status(200).json({ success: true, data: {} });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
