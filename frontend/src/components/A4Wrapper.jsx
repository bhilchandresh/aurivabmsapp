import React, { useRef, useState, useEffect } from 'react';

export default function A4Wrapper({ children }) {
  const containerRef = useRef(null);
  const contentRef = useRef(null);
  const [scale, setScale] = useState(1);
  const [isDesktop, setIsDesktop] = useState(false);

  useEffect(() => {
    let animationFrameId;

    const updateLayout = () => {
      const windowWidth = window.innerWidth;
      const desktop = windowWidth >= 1024;
      setIsDesktop(desktop);

      if (desktop) return;


      if (!containerRef.current || !contentRef.current || !containerRef.current.parentElement) return;
      
      const parentWidth = containerRef.current.parentElement.clientWidth;
      const padding = 32; // 16px safe padding on each side
      const availableWidth = parentWidth - padding;
      
      const A4_WIDTH_PX = 794; // standard 210mm width in pixels at 96 DPI
      
      let newScale = 1;
      if (availableWidth > 0 && availableWidth < A4_WIDTH_PX) {
        newScale = availableWidth / A4_WIDTH_PX;
      }
      
      setScale(newScale);
      
      // Update height synchronously to prevent any jumping
      const unscaledHeight = contentRef.current.offsetHeight;
      if (unscaledHeight > 0) {
        containerRef.current.style.height = `${unscaledHeight * newScale}px`;
      }
    };

    const observer = new ResizeObserver(() => {
      // Use requestAnimationFrame to avoid ResizeObserver loop limits
      cancelAnimationFrame(animationFrameId);
      animationFrameId = requestAnimationFrame(updateLayout);
    });

    if (containerRef.current?.parentElement) {
      observer.observe(containerRef.current.parentElement);
    }
    if (contentRef.current) {
      observer.observe(contentRef.current);
    }

    // Initial layout
    updateLayout();
    window.addEventListener('load', updateLayout);
    window.addEventListener('resize', updateLayout);

    return () => {
      observer.disconnect();
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener('load', updateLayout);
      window.removeEventListener('resize', updateLayout);
    };
  }, []);

  if (isDesktop) {
    return (
      <div className="w-full bg-white shadow-2xl rounded-sm print:shadow-none print:border-none print:max-w-[210mm] print:mx-auto">
        {children}
      </div>
    );
  }


  return (
    <>
      <style>{`
        @media print {
          .universal-a4-container {
            height: auto !important;
            display: block !important;
            overflow: visible !important;
          }
          .universal-a4-content {
            position: relative !important;
            transform: none !important;
            left: auto !important;
            width: 100% !important;
            min-width: 0 !important;
          }
        }
      `}</style>
      <div 
        ref={containerRef} 
        className="w-full flex justify-center overflow-hidden universal-a4-container relative"
        style={{ transition: 'height 0.2s ease-out' }}
      >
        <div 
          ref={contentRef}
          className="universal-a4-content absolute top-0 left-1/2 bg-white shadow-2xl rounded-sm border border-slate-200 print:shadow-none print:border-none print:w-full"
          style={{
            width: '210mm',
            minHeight: '297mm',
            transform: `translateX(-50%) scale(${scale})`,
            transformOrigin: 'top center',
          }}
        >
          {children}
        </div>
      </div>
    </>
  );
}
