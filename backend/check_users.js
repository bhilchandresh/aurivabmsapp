require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

async function checkUsers() {
  await mongoose.connect(process.env.MONGO_URI);
  const users = await User.find({}, 'email role passwordHash');
  console.log("Registered Users:");
  users.forEach(u => {
    console.log(`- Email: ${u.email} | Role: ${u.role} | HasPassword: ${!!u.passwordHash}`);
  });
  mongoose.disconnect();
}

checkUsers();
