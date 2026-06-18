require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./src/models/User');

async function reset() {
  await mongoose.connect(process.env.MONGO_URI);
  const user = await User.findOne({ email: 'riva@auriva.in' });
  if (user) {
    const salt = await bcrypt.genSalt(10);
    user.passwordHash = await bcrypt.hash('Riva@CEO', salt);
    await user.save();
    console.log("SUCCESS: Reset riva@auriva.in to password 'Riva@CEO'");
  } else {
    console.log("FAIL: user not found");
  }


  mongoose.disconnect();
}

reset();
