import React from "react";

// Tiny visual previews (CSS only) for the Picker
const StandardPreview = () => (
  <div className="w-full h-full bg-white border border-gray-200 p-2 flex flex-col gap-1">
    <div className="h-2 w-1/3 bg-gray-300 mb-1"></div>
    <div className="h-1 w-full bg-gray-100"></div>
    <div className="h-1 w-full bg-gray-100"></div>
    <div className="mt-2 h-8 w-full border border-gray-100"></div>
  </div>
);

const ModernPreview = () => (
  <div className="w-full h-full bg-white border border-gray-200 flex flex-col">
    <div className="h-4 w-full bg-gray-800 mb-2"></div>
    <div className="p-2 flex flex-col gap-1">
        <div className="h-2 w-1/2 bg-gray-300"></div>
        <div className="h-1 w-full bg-gray-100"></div>
    </div>
  </div>
);

const ModernBluePreview = () => (
  <div className="w-full h-full bg-white border border-gray-200 flex flex-col">
     <div className="flex h-8 bg-blue-600">
        <div className="w-2/3"></div>
        <div className="w-1/3 bg-blue-800"></div>
     </div>
     <div className="p-2 gap-1 flex flex-col">
        <div className="h-2 w-1/3 bg-gray-400"></div>
        <div className="mt-2 h-6 w-full bg-gray-50 border border-gray-100"></div>
        <div className="mt-auto h-2 w-1/4 bg-gray-200 self-end"></div>
     </div>
  </div>
);

export const INVOICE_TEMPLATES = [
  {
    id: "standard",
    name: "Standard",
    description: "Simple, clean, and professional. Good for service businesses.",
    preview: <StandardPreview />
  },
  {
    id: "modern",
    name: "Modern Dark",
    description: "Bold header with high contrast. Stand out from the crowd.",
    preview: <ModernPreview />
  },
  {
    id: "modern-blue",
    name: "Professional Blue",
    description: "Corporate style with blue accents and detailed layout.",
    preview: <ModernBluePreview />
  }
]