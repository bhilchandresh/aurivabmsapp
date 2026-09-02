const ContactMessage = require('../models/ContactMessage');
const SystemSettings = require('../models/SystemSettings');

// @desc    Submit Contact Us Form
// @route   POST /api/v1/public/contact
// @access  Public
exports.submitContactForm = async (req, res, next) => {
  try {
    const { name, email, subject, message } = req.body;

    if (!name || !email || !subject || !message) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields (name, email, subject, message)'
      });
    }

    const newMessage = await ContactMessage.create({
      name,
      email,
      subject,
      message
    });

    res.status(201).json({
      success: true,
      message: 'Your message has been received. We will contact you soon.',
      data: newMessage
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get Legal Document (Terms or Privacy)
// @route   GET /api/v1/public/legal/:type
// @access  Public
exports.getLegalDocument = async (req, res, next) => {
  try {
    const { type } = req.params; // Expects 'terms_and_conditions' or 'privacy_policy'
    
    if (type !== 'terms_and_conditions' && type !== 'privacy_policy') {
      return res.status(400).json({
        success: false,
        message: 'Invalid document type. Allowed values: terms_and_conditions, privacy_policy'
      });
    }

    const setting = await SystemSettings.findOne({ key: type });

    if (!setting) {
      // Return a default message if not set up yet
      return res.status(200).json({
        success: true,
        data: {
          key: type,
          value: `This is a placeholder for ${type.replace(/_/g, ' ')}. Please configure this in the Super Admin settings.`
        }
      });
    }

    res.status(200).json({
      success: true,
      data: setting
    });
  } catch (error) {
    next(error);
  }
};
