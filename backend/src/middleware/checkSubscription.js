const Tenant = require('../models/Tenant');

// --- PLAN CONFIGURATION (Simple Hardcoded Limits) ---
const PLANS = {
    basic: { maxInvoices: 10, maxUsers: 1, canExport: false, maxInventory: 0, maxSuppliers: 0 },
    premium: { maxInvoices: 100, maxUsers: 5, canExport: true, maxInventory: 100, maxSuppliers: 50 },
    enterprise: { maxInvoices: Infinity, maxUsers: Infinity, canExport: true, maxInventory: Infinity, maxSuppliers: Infinity }
};

const checkSubscription = async (req, res, next) => {
    try {
        if (!req.user || !req.user.tenantId) {
            return res.status(401).json({ message: "Unauthorized" });
        }

        const tenant = await Tenant.findById(req.user.tenantId);

        if (!tenant) {
            return res.status(404).json({ message: "Tenant not found" });
        }

        // 1. CHECK STATUS (Suspended)
        if (tenant.status === 'suspended') {
            return res.status(403).json({ 
                message: "Your account is suspended. Contact Support." 
            });
        }

        // 2. CHECK EXPIRY (Timeline)
        // Agar date nikal gayi hai
        if (new Date() > new Date(tenant.subscriptionEnd)) {
            return res.status(403).json({ 
                message: "Subscription Expired! Please renew your plan." 
            });
        }

        // 3. OPTIONAL: CHECK LIMITS (Only for creation)
        // Agar user naya invoice bana raha hai (POST request)
        if (req.method === 'POST' && req.baseUrl.includes('invoices')) {
            const planDetails = PLANS[tenant.subscriptionPlan || 'basic'];
            
            // Agar limit cross ho gayi (Note: Hame invoice count karna padega)
            // Abhi ke liye hum ise skip kar rahe hain taaki complexity na badhe
            // Future me hum yahan count logic lagayenge
        }

        req.tenant = tenant; // Tenant data ko request me save kar lo
        next();

    } catch (error) {
        console.error("Subscription Check Error:", error);
        res.status(500).json({ message: "Server Error" });
    }
};

checkSubscription.PLANS = PLANS;
module.exports = checkSubscription;