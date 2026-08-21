import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';

export const SplashScreen: React.FC = () => {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(false);
    }, 3000);

    return () => clearTimeout(timer);
  }, []);

  if (!isVisible) return null;

  return (
    <div className="fixed inset-0 z-50 bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center overflow-hidden">
      {/* Animated background gradient orbs */}
      <div className="absolute inset-0 overflow-hidden">
        <motion.div
          className="absolute w-96 h-96 bg-emerald-500/20 rounded-full blur-3xl"
          animate={{
            x: [0, 50, -50, 0],
            y: [0, -50, 50, 0],
          }}
          transition={{ duration: 8, repeat: Infinity }}
          style={{ top: '-10%', left: '-10%' }}
        />
        <motion.div
          className="absolute w-96 h-96 bg-blue-500/20 rounded-full blur-3xl"
          animate={{
            x: [0, -50, 50, 0],
            y: [0, 50, -50, 0],
          }}
          transition={{ duration: 8, repeat: Infinity }}
          style={{ bottom: '-10%', right: '-10%' }}
        />
      </div>

      {/* Content container */}
      <div className="relative z-10 flex flex-col items-center justify-center gap-6">
        {/* Logo with fade-in and scale animation */}
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{
            duration: 0.8,
            ease: 'easeOut',
          }}
          className="w-32 h-32 rounded-3xl bg-white/10 backdrop-blur-md flex items-center justify-center shadow-2xl border border-white/20 p-4"
        >
          <img
            src="/logo.png"
            alt="Rexo Global"
            className="w-full h-full object-contain"
          />
        </motion.div>

        {/* Branding text */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{
            duration: 0.8,
            delay: 0.2,
            ease: 'easeOut',
          }}
          className="text-center"
        >
          <h1 className="text-4xl font-black text-white tracking-tight">
            Rexo Global
          </h1>
          <p className="text-slate-300 text-sm font-medium mt-2">
            Creator Commerce & Influence Platform
          </p>
        </motion.div>

        {/* Loading spinner with animation */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{
            duration: 0.6,
            delay: 0.4,
          }}
          className="mt-8"
        >
          <div className="flex gap-2 justify-center">
            <motion.div
              className="w-2 h-2 rounded-full bg-emerald-400"
              animate={{
                y: [0, -8, 0],
                boxShadow: [
                  '0 0 0 rgba(16, 185, 129, 0)',
                  '0 0 20px rgba(16, 185, 129, 0.8)',
                  '0 0 0 rgba(16, 185, 129, 0)',
                ],
              }}
              transition={{ duration: 1.2, repeat: Infinity }}
            />
            <motion.div
              className="w-2 h-2 rounded-full bg-emerald-400"
              animate={{
                y: [0, -8, 0],
                boxShadow: [
                  '0 0 0 rgba(16, 185, 129, 0)',
                  '0 0 20px rgba(16, 185, 129, 0.8)',
                  '0 0 0 rgba(16, 185, 129, 0)',
                ],
              }}
              transition={{ duration: 1.2, repeat: Infinity, delay: 0.2 }}
            />
            <motion.div
              className="w-2 h-2 rounded-full bg-emerald-400"
              animate={{
                y: [0, -8, 0],
                boxShadow: [
                  '0 0 0 rgba(16, 185, 129, 0)',
                  '0 0 20px rgba(16, 185, 129, 0.8)',
                  '0 0 0 rgba(16, 185, 129, 0)',
                ],
              }}
              transition={{ duration: 1.2, repeat: Infinity, delay: 0.4 }}
            />
          </div>
          <p className="text-slate-400 text-xs font-medium mt-4 text-center">
            Loading...
          </p>
        </motion.div>
      </div>
    </div>
  );
};
