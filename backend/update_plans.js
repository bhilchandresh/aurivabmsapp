const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load env vars
dotenv.config();

const Tenant = require('./src/models/Tenant');

const updatePlans = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected...');

        const resultBasic = await Tenant.updateMany(
            { subscriptionPlan: 'basic' },
            { $set: { subscriptionPlan: 'freelance' } }
        );
        console.log('Updated basic to freelance:', resultBasic.modifiedCount);

        const resultPremium = await Tenant.updateMany(
            { subscriptionPlan: 'premium' },
            { $set: { subscriptionPlan: 'pro' } }
        );
        console.log('Updated premium to pro:', resultPremium.modifiedCount);

        const resultEnterprise = await Tenant.updateMany(
            { subscriptionPlan: 'enterprise' },
            { $set: { subscriptionPlan: 'business' } }
        );
        console.log('Updated enterprise to business:', resultEnterprise.modifiedCount);

        const resultStarter = await Tenant.updateMany(
            { subscriptionPlan: 'starter' },
            { $set: { subscriptionPlan: 'freelance' } }
        );
        console.log('Updated starter to freelance:', resultStarter.modifiedCount);

        console.log('Data Update Successful');
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

updatePlans();
