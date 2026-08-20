import React from 'react';

export interface PermissionRequest {
  title: string;
  description: string;
  onAllow: () => void;
  onDeny: () => void;
}

interface NativePermissionModalProps {
  isOpen: boolean;
  request: PermissionRequest | null;
}

export const NativePermissionModal: React.FC<NativePermissionModalProps> = ({
  isOpen,
  request,
}) => {
  if (!isOpen || !request) return null;

  return (
    <div className="fixed inset-0 z-[1000] flex items-center justify-center bg-black/40 backdrop-blur-sm px-4 animate-in fade-in duration-200">
      <div className="bg-[#f2f2f2] dark:bg-[#1e1e1e] max-w-[270px] w-full mx-auto rounded-[14px] shadow-2xl overflow-hidden animate-in zoom-in-95 duration-200">
        <div className="text-center p-5 pt-6">
          <p className="text-[17px] font-semibold mb-1 text-black dark:text-white leading-tight tracking-tight">
            {request.title}
          </p>
          <p className="text-[13px] mb-0 text-gray-700 dark:text-gray-300 leading-snug">
            {request.description}
          </p>
        </div>
        <div className="border-t border-gray-300 dark:border-gray-700 flex justify-center p-0">
          <div className="flex-1 text-center">
            <button 
              onClick={request.onDeny}
              className="text-blue-500 hover:bg-gray-200 dark:hover:bg-gray-800 w-full py-2.5 text-[17px] transition-colors" 
              type="button"
            >
              Don't Allow
            </button>
          </div>
          <div className="border-l border-gray-300 dark:border-gray-700" />
          <div className="flex-1 text-center">
            <button 
              onClick={request.onAllow}
              className="text-blue-500 font-semibold hover:bg-gray-200 dark:hover:bg-gray-800 w-full py-2.5 text-[17px] transition-colors" 
              type="button"
            >
              Allow
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
