import React, { useState, useRef, useEffect } from 'react';
import { ChevronsRight, CheckCircle2, Lock } from 'lucide-react';

interface SlideToConfirmProps {
  label: string;
  onConfirm: () => void;
  disabled?: boolean;
  isLoading?: boolean;
  resetSignal?: number;
}

export const SlideToConfirm: React.FC<SlideToConfirmProps> = ({
  label,
  onConfirm,
  disabled = false,
  isLoading = false,
  resetSignal = 0,
}) => {
  const [dragProgress, setDragProgress] = useState(0); // 0 to 100
  const [isDragging, setIsDragging] = useState(false);
  const [isConfirmed, setIsConfirmed] = useState(false);

  const containerRef = useRef<HTMLDivElement>(null);
  const startXRef = useRef<number>(0);

  useEffect(() => {
    // Reset state when signal changes
    setDragProgress(0);
    setIsConfirmed(false);
    setIsDragging(false);
  }, [resetSignal]);

  const handleStart = (clientX: number) => {
    if (disabled || isLoading || isConfirmed) return;
    setIsDragging(true);
    startXRef.current = clientX;
  };

  const handleMove = (clientX: number) => {
    if (!isDragging || disabled || isLoading || isConfirmed || !containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const maxDrag = rect.width - 56; // 56px handle size
    const delta = clientX - startXRef.current;
    const clamped = Math.max(0, Math.min(delta, maxDrag));
    const percentage = Math.round((clamped / maxDrag) * 100);
    setDragProgress(percentage);

    if (percentage >= 92) {
      setIsDragging(false);
      setDragProgress(100);
      setIsConfirmed(true);
      if (window.navigator?.vibrate) {
        window.navigator.vibrate(50);
      }
      onConfirm();
    }
  };

  const handleEnd = () => {
    if (isConfirmed) return;
    setIsDragging(false);
    if (dragProgress < 92) {
      // Spring back to start
      setDragProgress(0);
    }
  };

  // Touch Event Listeners
  const onTouchStart = (e: React.TouchEvent) => handleStart(e.touches[0].clientX);
  const onTouchMove = (e: React.TouchEvent) => handleMove(e.touches[0].clientX);
  const onTouchEnd = () => handleEnd();

  // Mouse Event Listeners
  const onMouseDown = (e: React.MouseEvent) => handleStart(e.clientX);
  const onMouseMove = (e: React.MouseEvent) => handleMove(e.clientX);
  const onMouseUp = () => handleEnd();

  useEffect(() => {
    const handleGlobalMouseMove = (e: MouseEvent) => {
      if (isDragging) handleMove(e.clientX);
    };
    const handleGlobalMouseUp = () => {
      if (isDragging) handleEnd();
    };

    if (isDragging) {
      window.addEventListener('mousemove', handleGlobalMouseMove);
      window.addEventListener('mouseup', handleGlobalMouseUp);
    }
    return () => {
      window.removeEventListener('mousemove', handleGlobalMouseMove);
      window.removeEventListener('mouseup', handleGlobalMouseUp);
    };
  }, [isDragging]);

  return (
    <div className="w-full select-none py-2">
      <div
        ref={containerRef}
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
        onMouseDown={onMouseDown}
        className={`relative h-14 w-full rounded-2xl overflow-hidden border transition-all flex items-center px-1.5 ${
          disabled
            ? 'bg-slate-100 border-slate-200 cursor-not-allowed opacity-60'
            : isConfirmed
            ? 'bg-emerald-600 border-emerald-500 text-white'
            : 'bg-slate-900 border-slate-800 dark:bg-slate-800 dark:border-slate-700 shadow-md'
        }`}
      >
        {/* Dynamic Progress Fill */}
        <div
          className={`absolute top-0 left-0 bottom-0 transition-all duration-75 ${
            isConfirmed
              ? 'bg-emerald-600 w-full'
              : 'bg-gradient-to-r from-indigo-600 via-purple-600 to-indigo-500 opacity-90'
          }`}
          style={{ width: `${Math.max(56, dragProgress)}%` }}
        />

        {/* Text Prompt */}
        <div className="absolute inset-0 flex items-center justify-center text-center px-12 pointer-events-none z-10">
          <span
            className={`text-xs sm:text-sm font-extrabold uppercase tracking-wider transition-opacity duration-200 ${
              isConfirmed
                ? 'text-white'
                : disabled
                ? 'text-slate-400'
                : dragProgress > 40
                ? 'text-white drop-shadow-sm'
                : 'text-slate-300'
            }`}
          >
            {isLoading
              ? 'Processing...'
              : isConfirmed
              ? 'Confirmed! Processing Request...'
              : disabled
              ? 'Fill required details above'
              : label}
          </span>
        </div>

        {/* Sliding Handle Button */}
        <div
          className={`relative z-20 h-11 w-11 rounded-xl flex items-center justify-center shadow-lg transition-transform duration-75 ${
            disabled
              ? 'bg-slate-300 text-slate-500'
              : isConfirmed
              ? 'bg-white text-emerald-600 scale-105'
              : 'bg-white text-indigo-600 cursor-grab active:cursor-grabbing hover:scale-105'
          }`}
          style={{
            transform: `translateX(${(dragProgress / 100) * ((containerRef.current?.offsetWidth || 300) - 56)}px)`,
            transition: isDragging ? 'none' : 'transform 0.25s cubic-bezier(0.2, 0.8, 0.2, 1)',
          }}
        >
          {disabled ? (
            <Lock className="w-5 h-5 text-slate-400" />
          ) : isConfirmed ? (
            <CheckCircle2 className="w-6 h-6 text-emerald-600 animate-bounce" />
          ) : (
            <ChevronsRight className="w-6 h-6 text-indigo-600 animate-pulse" />
          )}
        </div>
      </div>
    </div>
  );
};
