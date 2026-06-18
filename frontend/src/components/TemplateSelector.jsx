import React from 'react';
// 1. Import all your templates
import StandardTemplate from './templates/StandardTemplate';
import ModernTemplate from './templates/ModernTemplate';
import ModernBlueTemplate from './templates/ModernBlueTemplate'; // <--- IMPORT THIS
import ClassicTemplate from './templates/ClassicTemplate';
import MinimalistTemplate from './templates/MinimalistTemplate';
import ElegantTemplate from './templates/ElegantTemplate'; // 1. Import
import VibrantTemplate from './templates/VibrantTemplate';

const TemplateSelector = ({ data, tenant, type }) => {
  if (!data || !tenant) return <div className="p-4 text-red-500">Error: Missing Data</div>;

  // 1. Determine which ID to look for
  let selectedTemplate = 'standard'; // Default

  if (type === 'invoice') {
      // Check legacy field 'selectedTemplate' first, then new field 'templatePreference'
      selectedTemplate = tenant.templatePreference || tenant.selectedTemplate || 'standard';
  } else if (type === 'quotation') {
      selectedTemplate = tenant.quotationTemplate || 'standard';
  }

  // 2. Switch Statement to return the correct component
  switch (selectedTemplate) {
    case 'modern':
      return <ModernTemplate data={data} tenant={tenant} type={type} />;
    
    // --- THIS WAS LIKELY MISSING OR MISMATCHED ---
    case 'modern-blue': 
      return <ModernBlueTemplate data={data} tenant={tenant} type={type} />;
    
    case 'classic':
      return <ClassicTemplate data={data} tenant={tenant} type={type} />;
    
    case 'minimalist':
      return <MinimalistTemplate data={data} tenant={tenant} type={type} />;
    
    case 'standard':

    case 'elegant': 
      return <ElegantTemplate data={data} tenant={tenant} type={type} />; 
    case 'vibrant': 
      return <VibrantTemplate data={data} tenant={tenant} type={type} />;
    
      // 2. Add Case
    default:
      return <StandardTemplate data={data} tenant={tenant} type={type} />;
  }
};

export default TemplateSelector;