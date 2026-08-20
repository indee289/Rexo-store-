import React from 'react';
import { Plus, Repeat } from 'lucide-react';
import { useStore } from '../../context/StoreContext';

interface Wallet3DPocketProps {
  onOpenDeposit: () => void;
  onOpenWithdraw: () => void;
}

export const Wallet3DPocket: React.FC<Wallet3DPocketProps> = ({
  onOpenDeposit,
  onOpenWithdraw,
}) => {
  const { currentWallet } = useStore();
  const availableBalance = currentWallet.availableBalance ?? 0;

  return (
    <div className="relative w-full max-w-md mx-auto flex flex-col items-center">
      <style>{`
        /* Wallet Wrapper */
        .wallet-ui-container {
          padding-bottom: 40px;
          margin-top: 20px;
        }
        .wallet-interactive {
          position: relative;
          width: 280px;
          height: 230px;
          cursor: pointer;
          perspective: 1000px;
          display: flex;
          justify-content: center;
          align-items: flex-end;
          transition: transform 0.4s ease;
          margin: 0 auto;
        }
        .wallet-interactive::after {
          content: "Hover to see Balance";
          position: absolute;
          bottom: -30px;
          font-style: italic;
          color: #64748b;
          font-size: 14px;
          font-weight: 600;
          text-decoration: underline;
        }
        @keyframes slideIntoPocket {
          0% { transform: translateY(-100px); opacity: 0; }
          100% { transform: translateY(0); opacity: 1; }
        }
        .wallet-back {
          position: absolute;
          bottom: 0;
          width: 280px;
          height: 200px;
          background: #1e341e;
          border-radius: 22px 22px 60px 60px;
          z-index: 5;
          box-shadow: inset 0 25px 35px rgba(0, 0, 0, 0.4), inset 0 5px 15px rgba(0, 0, 0, 0.5);
        }
        .wallet-card {
          position: absolute;
          width: 260px;
          height: 140px;
          left: 10px;
          border-radius: 16px;
          padding: 18px;
          color: white;
          box-sizing: border-box;
          box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.3), 0 -4px 15px rgba(0, 0, 0, 0.1);
          transition: transform 0.6s cubic-bezier(0.34, 1.56, 0.64, 1), z-index 0s;
          animation: slideIntoPocket 0.8s cubic-bezier(0.2, 0.8, 0.2, 1) backwards;
        }
        .wallet-card-inner {
          display: flex;
          flex-direction: column;
          justify-content: space-between;
          height: 100%;
        }
        .wallet-card-top {
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-size: 14px;
          text-transform: uppercase;
          letter-spacing: 1px;
        }
        .wallet-chip {
          width: 32px;
          height: 24px;
          background: rgba(255, 255, 255, 0.2);
          border-radius: 4px;
          border: 1px solid rgba(255, 255, 255, 0.1);
        }
        .wallet-card-bottom {
          display: flex;
          justify-content: space-between;
          align-items: flex-end;
        }
        .wallet-card-info {
          display: flex;
          flex-direction: column;
          align-items: flex-start;
        }
        .wallet-label {
          font-size: 8px;
          opacity: 0.7;
          text-transform: uppercase;
          margin-bottom: 2px;
          display: block;
        }
        .wallet-value {
          font-size: 10px;
          font-weight: 500;
        }
        .wallet-card-number-wrapper {
          text-align: right;
        }
        .wallet-hidden-stars {
          font-size: 16px;
          letter-spacing: 2px;
        }
        .wallet-card-number {
          display: none;
          font-size: 14px;
          letter-spacing: 1px;
          font-family: monospace;
        }
        .wallet-stripe {
          background: #635bff;
          bottom: 90px;
          z-index: 10;
          animation-delay: 0.1s;
        }
        .wallet-wise {
          background: #9bd86a;
          bottom: 65px;
          z-index: 20;
          animation-delay: 0.2s;
        }
        .wallet-paypal {
          background: #ffffff;
          color: #003087;
          bottom: 40px;
          z-index: 30;
          animation-delay: 0.3s;
        }
        .wallet-paypal .wallet-chip {
          background: rgba(0, 0, 0, 0.05);
        }
        .wallet-paypal .wallet-label {
          color: #8c979d;
        }
        .wallet-pocket {
          position: absolute;
          bottom: 0;
          width: 280px;
          height: 160px;
          z-index: 40;
          filter: drop-shadow(0 15px 25px rgba(20, 40, 20, 0.4));
        }
        .wallet-pocket-content {
          position: absolute;
          top: 45px;
          width: 100%;
          text-align: center;
          z-index: 50;
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 8px;
        }
        .wallet-balance-stars {
          color: #839e7b;
          font-size: 24px;
          letter-spacing: 4px;
          transition: 0.3s;
        }
        .wallet-balance-real {
          color: #a7c59e;
          font-size: 22px;
          font-weight: 600;
          opacity: 0;
          position: absolute;
          top: 0;
          left: 50%;
          transform: translate(-50%, 10px);
          transition: 0.3s;
        }
        .wallet-eye-icon-wrapper {
          margin-top: 8px;
          height: 20px;
          width: 20px;
          position: relative;
          opacity: 0.3;
          transition: 0.3s;
        }
        .wallet-eye-icon {
          position: absolute;
          top: 0;
          left: 0;
          stroke: #3be60b;
          transition: 0.3s;
        }
        .wallet-interactive:hover {
          transform: translateY(-5px);
        }
        .wallet-interactive:hover .wallet-eye-icon-wrapper {
          opacity: 1;
        }
        .wallet-interactive:hover .wallet-stripe {
          transform: translateY(-75px) rotate(-3deg);
        }
        .wallet-interactive:hover .wallet-wise {
          transform: translateY(-45px) rotate(2deg);
        }
        .wallet-interactive:hover .wallet-paypal {
          transform: translateY(-10px);
        }
        .wallet-card:hover {
          z-index: 100 !important;
          transition-delay: 0s !important;
        }
        .wallet-interactive:hover .wallet-stripe:hover {
          transform: translateY(-60px) scale(1.05) rotate(0);
        }
        .wallet-interactive:hover .wallet-wise:hover {
          transform: translateY(-70px) scale(1.05) rotate(0);
        }
        .wallet-interactive:hover .wallet-paypal:hover {
          transform: translateY(-60px) scale(1.05) rotate(0);
        }
        .wallet-card:hover .wallet-hidden-stars {
          display: none;
        }
        .wallet-card:hover .wallet-card-number {
          display: block;
        }
        .wallet-interactive:hover .wallet-balance-stars {
          opacity: 0;
        }
        .wallet-interactive:hover .wallet-balance-real {
          opacity: 1;
          transform: translate(-50%, 0);
        }
        .wallet-interactive:hover .wallet-eye-slash {
          opacity: 0;
          transform: scale(0.5);
        }
        .wallet-interactive:hover .wallet-eye-open {
          opacity: 1;
          transform: scale(1.1);
        }
      `}</style>

      <div className="wallet-ui-container">
        <div className="wallet-interactive">
          <div className="wallet-back" />
          <div className="wallet-card wallet-stripe">
            <div className="wallet-card-inner">
              <div className="wallet-card-top">
                <span>Stripe</span>
                <div className="wallet-chip" />
              </div>
              <div className="wallet-card-bottom">
                <div className="wallet-card-info">
                  <span className="wallet-label">Holder</span><span className="wallet-value">ALEX SMITH</span>
                </div>
                <div className="wallet-card-number-wrapper">
                  <span className="wallet-hidden-stars">**** 4242</span>
                  <span className="wallet-card-number">5524 9910 4242</span>
                </div>
              </div>
            </div>
          </div>
          <div className="wallet-card wallet-wise">
            <div className="wallet-card-inner">
              <div className="wallet-card-top">
                <span>Wise</span>
                <div className="wallet-chip" />
              </div>
              <div className="wallet-card-bottom">
                <div className="wallet-card-info">
                  <span className="wallet-label">Business</span><span className="wallet-value">STUDIO LLC</span>
                </div>
                <div className="wallet-card-number-wrapper">
                  <span className="wallet-hidden-stars">**** 8810</span>
                  <span className="wallet-card-number">9012 4432 8810</span>
                </div>
              </div>
            </div>
          </div>
          <div className="wallet-card wallet-paypal">
            <div className="wallet-card-inner">
              <div className="wallet-card-top">
                <span>Pay<b style={{color: '#0079C1'}}>Pal</b></span>
                <div className="wallet-chip" />
              </div>
              <div className="wallet-card-bottom">
                <div className="wallet-card-info">
                  <span className="wallet-label">Email</span><span className="wallet-value">hello@work.com</span>
                </div>
                <div className="wallet-card-number-wrapper">
                  <span className="wallet-hidden-stars">**** 0094</span>
                  <span className="wallet-card-number">3312 0045 0094</span>
                </div>
              </div>
            </div>
          </div>
          <div className="wallet-pocket">
            <svg className="wallet-pocket-svg" viewBox="0 0 280 160" fill="none" style={{ width: '100%', height: '100%' }}>
              <path d="M 0 20 C 0 10, 5 10, 10 10 C 20 10, 25 25, 40 25 L 240 25 C 255 25, 260 10, 270 10 C 275 10, 280 10, 280 20 L 280 120 C 280 155, 260 160, 240 160 L 40 160 C 20 160, 0 155, 0 120 Z" fill="#1e341e" />
              <path d="M 8 22 C 8 16, 12 16, 15 16 C 23 16, 27 29, 40 29 L 240 29 C 253 29, 257 16, 265 16 C 268 16, 272 16, 272 22 L 272 120 C 272 150, 255 152, 240 152 L 40 152 C 25 152, 8 152, 8 120 Z" stroke="#3d5635" strokeWidth="1.5" strokeDasharray="6 4" />
            </svg>
            <div className="wallet-pocket-content">
              <div style={{position: 'relative', height: 24, width: '100%'}}>
                <div className="wallet-balance-stars">******</div>
                <div className="wallet-balance-real">₹{availableBalance.toLocaleString('en-IN')}</div>
              </div>
              <div style={{color: '#698263', fontSize: 12, fontWeight: 500}}>
                Total Balance
              </div>
              <div className="wallet-eye-icon-wrapper">
                <svg className="wallet-eye-icon wallet-eye-slash" width={20} height={20} viewBox="0 0 24 24" fill="none" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                  <circle cx={12} cy={12} r={3} />
                  <line x1={3} y1={3} x2={21} y2={21} />
                </svg>
                <svg className="wallet-eye-icon wallet-eye-open" style={{opacity: 0}} width={20} height={20} viewBox="0 0 24 24" fill="none" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
                  <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                  <circle cx={12} cy={12} r={3} />
                </svg>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ACTION BUTTONS (ADD BALANCE / WITHDRAW) */}
      <div className="flex items-center justify-center gap-3 w-full max-w-[280px] mt-2 mb-4">
        <button
          onClick={onOpenDeposit}
          className="flex-1 py-2 px-3.5 rounded-xl bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-extrabold text-xs transition-all shadow-md active:scale-95 flex items-center justify-center gap-1.5"
        >
          <Plus size={15} />
          <span>Add Balance</span>
        </button>
        <button
          onClick={onOpenWithdraw}
          className="py-2 px-3.5 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-800 dark:text-white transition-all shadow-md active:scale-95 flex items-center justify-center font-extrabold text-xs shrink-0 gap-1.5"
          title="Withdraw Funds"
        >
          <Repeat size={15} />
          <span>Withdraw</span>
        </button>
      </div>
    </div>
  );
};
