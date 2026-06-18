import React from 'react';
import { CheckCircle } from 'lucide-react';

// Define ALL 6 Templates
const TEMPLATES = [
  { 
    id: 'standard', 
    name: 'Standard', 
    desc: 'Professional B&W', 
    bg: 'bg-gray-100', 
    header: 'bg-gray-800', 
    accent: 'bg-gray-300' 
  },
  { 
    id: 'modern', 
    name: 'Modern', 
    desc: 'Clean Gray & Blue', 
    bg: 'bg-slate-50', 
    header: 'bg-slate-600', 
    accent: 'bg-slate-300' 
  },
  { 
    id: 'modern-blue', 
    name: 'Modern Blue', 
    desc: 'Deep Blue Theme', 
    bg: 'bg-blue-50', 
    header: 'bg-blue-700', 
    accent: 'bg-blue-300' 
  },
  { 
    id: 'classic', 
    name: 'Classic', 
    desc: 'Warm Serif', 
    bg: 'bg-amber-50', 
    header: 'bg-amber-800', 
    accent: 'bg-amber-200' 
  },
  { 
    id: 'minimalist', 
    name: 'Minimalist', 
    desc: 'Simple & Clean', 
    bg: 'bg-white border border-gray-200', 
    header: 'bg-white border-b border-gray-300', 
    accent: 'bg-gray-100' 
  },
  // ✅ NEW TEMPLATE ADDED
  { 
    id: 'elegant', 
    name: 'Elegant', 
    desc: 'Premium Gold & Dark', 
    bg: 'bg-stone-50', 
    header: 'bg-stone-900 border-b-2 border-yellow-600', 
    accent: 'bg-yellow-600' 
  },

  // TEMPLATES array ke andar ek aur object add karein:
  { 
    id: 'vibrant', 
    name: 'Vibrant', 
    desc: 'Colorful Gradient UI', 
    bg: 'bg-fuchsia-50', 
    header: 'bg-gradient-to-r from-violet-500 to-fuchsia-500', 
    accent: 'bg-violet-300' 
  }
// Aur grid ko update karein: className="grid grid-cols-2 lg:grid-cols-7..."
];

const TemplatePicker = ({ selectedId, onSelect }) => {
  return (
    <div className="flex overflow-x-auto gap-6 pb-6 pt-2 px-2 snap-x snap-mandatory scroll-smooth" style={{ scrollbarWidth: 'thin' }}>
      {TEMPLATES.map((template) => (
        <div 
          key={template.id}
          onClick={() => onSelect(template.id)}
          className={`
            shrink-0 w-64 snap-center cursor-pointer relative rounded-2xl border-2 transition-all duration-300 overflow-hidden group
            ${selectedId === template.id 
              ? "border-blue-600 ring-4 ring-blue-50 shadow-2xl scale-[1.02] z-10" 
              : "border-gray-100 hover:border-blue-400 hover:shadow-xl hover:-translate-y-1 bg-white opacity-90 hover:opacity-100"
            }
          `}
        >
          {/* --- PREMIUM VISUAL MOCKUP AREA --- */}
          <div className={`h-48 p-5 ${template.bg} flex flex-col gap-4 relative transition-transform duration-700 group-hover:scale-105`}>
             
             {/* Mini Header Block with "Logo" circle */}
             <div className={`h-6 w-full rounded-md ${template.header} shadow-md flex items-center px-2 gap-2`}>
                <div className="w-2.5 h-2.5 rounded-full bg-white/40"></div>
                <div className="w-12 h-1.5 rounded-full bg-white/20"></div>
             </div>
             
             {/* Mini Content Grid */}
             <div className="flex gap-3 mt-1">
                <div className={`h-20 w-1/3 rounded-lg ${template.accent} shadow-inner flex flex-col p-2 gap-2`}>
                    <div className="h-1.5 w-full bg-white/30 rounded-full"></div>
                    <div className="h-1.5 w-2/3 bg-white/20 rounded-full"></div>
                </div>
                <div className="flex-1 space-y-3 py-1">
                    <div className="space-y-1.5">
                        <div className="h-1.5 w-full bg-gray-400/20 rounded-full"></div>
                        <div className="h-1.5 w-5/6 bg-gray-400/10 rounded-full"></div>
                    </div>
                    <div className="h-10 w-full bg-gray-400/5 rounded-lg p-2 flex items-end justify-between">
                         <div className="h-2 w-1/4 bg-gray-400/20 rounded-full"></div>
                         <div className="h-2 w-1/3 bg-gray-400/40 rounded-full"></div>
                    </div>
                </div>
             </div>

             {/* Dynamic Accent Glow on Hover */}
             <div className={`absolute inset-0 opacity-0 group-hover:opacity-10 transition-opacity duration-300 ${template.accent}`}></div>
          </div>

          {/* --- TEXT INFO (MORE VISIBLE) --- */}
          <div className={`p-5 text-center transition-all duration-300 ${selectedId === template.id ? 'bg-blue-600 text-white' : 'bg-white text-gray-800'}`}>
            <h4 className="font-bold text-base uppercase tracking-widest mb-2">
                {template.name}
            </h4>
            <p className={`text-sm font-medium leading-snug ${selectedId === template.id ? 'text-blue-100' : 'text-gray-500'}`}>
                {template.desc}
            </p>
          </div>

          {/* --- CHECKMARK BADGE (LARGER) --- */}
          {selectedId === template.id && (
            <div className="absolute top-3 right-3 bg-white text-blue-600 rounded-full p-1 shadow-2xl animate-bounce-subtle">
               <CheckCircle className="w-5 h-5 fill-blue-600 text-white" />
            </div>
          )}
        </div>
      ))}
    </div>
  );
};

export default TemplatePicker;