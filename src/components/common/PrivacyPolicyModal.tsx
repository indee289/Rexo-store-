import React, { useState } from 'react';
import { ShieldCheck, X, Mail, MapPin, ChevronRight, FileText, ArrowUp, Lock, ExternalLink, Search } from 'lucide-react';

interface PrivacyPolicyModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const PrivacyPolicyModal: React.FC<PrivacyPolicyModalProps> = ({ isOpen, onClose }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [activeSection, setActiveSection] = useState<string | null>(null);

  if (!isOpen) return null;

  const scrollToSection = (id: string) => {
    setActiveSection(id);
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-2 sm:p-4 overflow-y-auto">
      <div className="bg-white dark:bg-slate-900 w-full max-w-3xl rounded-[28px] sm:rounded-[36px] border border-slate-200/90 dark:border-slate-800 shadow-2xl overflow-hidden flex flex-col my-auto max-h-[90vh] text-slate-800 dark:text-slate-200 font-sans transition-colors">
        
        {/* MODAL HEADER */}
        <div className="px-5 py-4 sm:px-6 sm:py-5 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50/50 dark:bg-slate-900/50 sticky top-0 z-20 backdrop-blur-md">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-2xl bg-indigo-50 dark:bg-indigo-950/80 text-indigo-600 dark:text-indigo-400 border border-indigo-100 dark:border-indigo-900/50 shrink-0">
              <ShieldCheck size={22} />
            </div>
            <div>
              <h2 className="text-base sm:text-lg font-extrabold text-slate-900 dark:text-white tracking-tight">
                Privacy Policy / गोपनीयता नीति
              </h2>
              <p className="text-[11px] sm:text-xs text-slate-500 dark:text-slate-400 font-medium">
                Last updated: August 20, 2026 • Rexo Agency
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2.5 rounded-full text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-all active:scale-95"
            title="Close"
          >
            <X size={20} />
          </button>
        </div>

        {/* QUICK SEARCH BAR & SECTION JUMPER */}
        <div className="px-5 py-3 sm:px-6 bg-slate-100/60 dark:bg-slate-800/40 border-b border-slate-100 dark:border-slate-800/80 flex items-center gap-2">
          <Search size={16} className="text-slate-400 shrink-0" />
          <input
            type="text"
            placeholder="Search privacy topics (e.g., AI, payments, account deletion)..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-transparent text-xs text-slate-900 dark:text-white placeholder-slate-400 focus:outline-none"
          />
          {searchTerm && (
            <button onClick={() => setSearchTerm('')} className="text-xs text-slate-400 hover:text-slate-600">
              Clear
            </button>
          )}
        </div>

        {/* BODY SCROLL CONTENT */}
        <div className="p-5 sm:p-7 overflow-y-auto space-y-6 text-xs sm:text-sm leading-relaxed">
          
          {/* INTRO BANNER */}
          <div className="p-4 sm:p-5 rounded-2xl bg-gradient-to-br from-indigo-50 via-slate-50 to-purple-50 dark:from-indigo-950/40 dark:via-slate-900 dark:to-purple-950/30 border border-indigo-100/80 dark:border-indigo-900/40 space-y-2">
            <div className="flex items-center gap-2 text-indigo-700 dark:text-indigo-300 font-extrabold text-xs">
              <FileText size={16} />
              <span>Rexo Agency Privacy Notice</span>
            </div>
            <p className="text-slate-600 dark:text-slate-300 text-xs">
              This Privacy Notice for <strong>Rexo Agency</strong> ("we," "us," or "our") describes how and why we might access, collect, store, use, and/or share ("process") your personal information when you use our Services, including when you download and use our mobile application (<strong>Rexo Store</strong>).
            </p>
            <p className="text-slate-600 dark:text-slate-300 text-xs">
              <strong>Rexo Store</strong> is a creator marketplace and digital commerce platform that connects creators, brands, and users. The platform allows users to create profiles, discover and participate in campaigns, manage wallets and payments, submit verification documents, communicate with other users, receive notifications, and access marketplace and creator-related services.
            </p>
            <div className="pt-2 flex flex-wrap gap-2 text-[11px] font-bold">
              <a
                href="mailto:rexoagency.in@gmail.com"
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-indigo-600 dark:text-indigo-400 hover:underline"
              >
                <Mail size={12} /> rexoagency.in@gmail.com
              </a>
              <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300">
                <MapPin size={12} /> Jodhpur, Rajasthan 342008, India
              </span>
            </div>
          </div>

          {/* SUMMARY OF KEY POINTS */}
          <div className="space-y-3">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white uppercase tracking-wider text-indigo-600 dark:text-indigo-400">
              Summary of Key Points
            </h3>
            <div className="grid sm:grid-cols-2 gap-2.5 text-xs">
              <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl border border-slate-200/80 dark:border-slate-700/60">
                <span className="font-bold text-slate-900 dark:text-white block mb-0.5">Personal Info Processed</span>
                <span className="text-slate-600 dark:text-slate-400">Names, phone, email, username, device ID, payment logs, KYC verification.</span>
              </div>
              <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl border border-slate-200/80 dark:border-slate-700/60">
                <span className="font-bold text-slate-900 dark:text-white block mb-0.5">Sensitive Data</span>
                <span className="text-slate-600 dark:text-slate-400">We do not process sensitive personal information like racial origin or political beliefs.</span>
              </div>
              <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl border border-slate-200/80 dark:border-slate-700/60">
                <span className="font-bold text-slate-900 dark:text-white block mb-0.5">AI Products</span>
                <span className="text-slate-600 dark:text-slate-400">Content moderation & trust safety checks powered by Google Cloud AI.</span>
              </div>
              <div className="p-3 bg-slate-50 dark:bg-slate-800/60 rounded-xl border border-slate-200/80 dark:border-slate-700/60">
                <span className="font-bold text-slate-900 dark:text-white block mb-0.5">Security & Rights</span>
                <span className="text-slate-600 dark:text-slate-400">Adequate technical safeguards. You can request account review or deletion anytime.</span>
              </div>
            </div>
          </div>

          {/* TABLE OF CONTENTS */}
          <div className="p-4 bg-slate-50 dark:bg-slate-800/50 rounded-2xl border border-slate-200 dark:border-slate-800 space-y-2">
            <h3 className="text-xs font-extrabold text-slate-900 dark:text-white uppercase tracking-wider">
              Table of Contents
            </h3>
            <div className="grid sm:grid-cols-2 gap-1.5 text-xs">
              {[
                { id: 'sec-1', label: '1. What Information Do We Collect?' },
                { id: 'sec-2', label: '2. How Do We Process Your Information?' },
                { id: 'sec-3', label: '3. When & With Whom Do We Share Information?' },
                { id: 'sec-4', label: '4. Do We Offer AI-Based Products?' },
                { id: 'sec-5', label: '5. How Do We Handle Social Logins?' },
                { id: 'sec-6', label: '6. How Long Do We Keep Information?' },
                { id: 'sec-7', label: '7. How Do We Keep Information Safe?' },
                { id: 'sec-8', label: '8. Do We Collect Info From Minors?' },
                { id: 'sec-9', label: '9. What Are Your Privacy Rights?' },
                { id: 'sec-10', label: '10. Controls For Do-Not-Track Features' },
                { id: 'sec-11', label: '11. Do We Make Updates To This Notice?' },
                { id: 'sec-12', label: '12. How Can You Contact Us?' },
                { id: 'sec-13', label: '13. How To Review, Update Or Delete Data?' },
              ].map((item) => (
                <button
                  key={item.id}
                  onClick={() => scrollToSection(item.id)}
                  className="text-left font-semibold text-indigo-600 dark:text-indigo-400 hover:underline py-0.5 truncate flex items-center justify-between"
                >
                  <span className="truncate">{item.label}</span>
                  <ChevronRight size={12} className="shrink-0" />
                </button>
              ))}
            </div>
          </div>

          {/* SECTION 1 */}
          <section id="sec-1" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              1. WHAT INFORMATION DO WE COLLECT?
            </h3>
            <p className="font-bold text-slate-700 dark:text-slate-300">Personal information you disclose to us</p>
            <p className="text-slate-600 dark:text-slate-400">
              <em>In Short: We collect personal information that you provide to us.</em>
            </p>
            <p className="text-slate-600 dark:text-slate-400">
              We collect personal information that you voluntarily provide when you register on the Services, express an interest in obtaining information about us or our products, or contact us.
            </p>
            <ul className="list-disc pl-5 space-y-1 text-slate-600 dark:text-slate-400">
              <li><strong>Names & Usernames:</strong> Used for public profiles, creator campaigns, and marketplace transactions.</li>
              <li><strong>Phone Numbers & Email Addresses:</strong> Used for account security, OTP 2FA verification, notifications, and customer support.</li>
              <li><strong>Passwords & Credentials:</strong> Encrypted credentials used for user authentication.</li>
              <li><strong>Sensitive Information:</strong> We do not process sensitive personal information (such as political opinions or religious beliefs).</li>
              <li><strong>Social Media Login Data:</strong> If you choose to register using social media accounts (Facebook, Google, X), we collect profile info as granted.</li>
              <li><strong>Mobile Device Data & Push Notifications:</strong> Mobile device ID, model, OS version, IP address, and push notification tokens.</li>
            </ul>
            <div className="p-3 bg-blue-50 dark:bg-blue-950/40 rounded-xl border border-blue-100 dark:border-blue-900/50 text-[11px] text-blue-900 dark:text-blue-200">
              <strong>Google API Policy:</strong> Our use of information received from Google APIs adheres to the{' '}
              <a href="https://developers.google.com/terms/api-services-user-data-policy" target="_blank" rel="noreferrer" className="underline font-bold">
                Google API Services User Data Policy
              </a>, including Limited Use requirements.
            </div>
          </section>

          {/* SECTION 2 */}
          <section id="sec-2" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              2. HOW DO WE PROCESS YOUR INFORMATION?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              <em>In Short: We process your information to provide, improve, and administer our Services, communicate with you, for security and fraud prevention, and to comply with law.</em>
            </p>
            <ul className="list-disc pl-5 space-y-1 text-slate-600 dark:text-slate-400">
              <li>To facilitate account creation, authentication, and user profile management.</li>
              <li>To deliver marketplace services, creator campaign workflows, and wallet transactions.</li>
              <li>To respond to user inquiries and offer technical support.</li>
              <li>To send administrative details, order updates, and policy notifications.</li>
              <li>To fulfill and manage orders, payments, withdrawals, and digital store purchases.</li>
              <li>To enable secure user-to-user chat and campaign communications.</li>
              <li>To request feedback and send opted-in promotional communications.</li>
              <li>To protect our Services, monitor fraud, perform KYC processing, content moderation, AI-assisted safety checks, and send push notifications.</li>
            </ul>
          </section>

          {/* SECTION 3 */}
          <section id="sec-3" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              3. WHEN AND WITH WHOM DO WE SHARE YOUR PERSONAL INFORMATION?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              <em>In Short: We may share information in specific situations described in this section.</em>
            </p>
            <p className="text-slate-600 dark:text-slate-400">
              <strong>Business Transfers:</strong> We may share or transfer your information in connection with any merger, sale of company assets, financing, or acquisition of all or a portion of our business.
            </p>
            <p className="text-slate-600 dark:text-slate-400">
              <strong>Other Users:</strong> When you share personal information or interact with public marketplace areas, campaign boards, or connected social accounts, descriptions of your profile and activity may be viewed by other users.
            </p>
          </section>

          {/* SECTION 4 */}
          <section id="sec-4" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              4. DO WE OFFER ARTIFICIAL INTELLIGENCE-BASED PRODUCTS?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              <em>In Short: We offer tools powered by artificial intelligence or machine learning.</em>
            </p>
            <p className="text-slate-600 dark:text-slate-400">
              We provide AI-based features through third-party service providers ("AI Service Providers"), including <strong>Google Cloud AI</strong>. Your input, text submissions, and content moderation checks will be processed by these AI Service Providers solely for trust, safety, research, and abuse monitoring purposes.
            </p>
          </section>

          {/* SECTION 5 */}
          <section id="sec-5" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              5. HOW DO WE HANDLE YOUR SOCIAL LOGINS?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              If you register or log in using third-party social media accounts (Facebook, Google, X), we receive basic profile information like your name, email address, and profile picture. We use this information strictly for account authentication and creation.
            </p>
          </section>

          {/* SECTION 6 */}
          <section id="sec-6" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              6. HOW LONG DO WE KEEP YOUR INFORMATION?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              We keep your personal information for as long as necessary to fulfill the purposes set out in this Privacy Notice, or as long as you maintain an active account with us, unless a longer retention period is required by law (such as tax, accounting, or legal requirements).
            </p>
          </section>

          {/* SECTION 7 */}
          <section id="sec-7" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              7. HOW DO WE KEEP YOUR INFORMATION SAFE?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              We have implemented appropriate organizational and technical security measures (including row-level security, encrypted SSL channels, edge function isolation, and secure storage) designed to protect your personal information.
            </p>
          </section>

          {/* SECTION 8 */}
          <section id="sec-8" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              8. DO WE COLLECT INFORMATION FROM MINORS?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              We do not knowingly collect data from or market to children under 18 years of age. By using the Services, you represent that you are at least 18 or that you are the parent/guardian of such a minor.
            </p>
          </section>

          {/* SECTION 9 */}
          <section id="sec-9" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              9. WHAT ARE YOUR PRIVACY RIGHTS?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Depending on your location, you have rights to review, change, or terminate your account at any time. You may withdraw consent or opt-out of marketing communications by updating your account settings or emailing us at{' '}
              <a href="mailto:rexoagency.in@gmail.com" className="text-indigo-600 font-bold hover:underline">
                rexoagency.in@gmail.com
              </a>.
            </p>
          </section>

          {/* SECTION 10 */}
          <section id="sec-10" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              10. CONTROLS FOR DO-NOT-TRACK FEATURES
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Most web browsers include a Do-Not-Track ("DNT") feature. As no uniform technology standard has been finalized, we do not currently respond to automated DNT browser signals.
            </p>
          </section>

          {/* SECTION 11 */}
          <section id="sec-11" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              11. DO WE MAKE UPDATES TO THIS NOTICE?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Yes, we will update this notice as necessary to stay compliant with relevant laws. The updated version will be indicated by a revised date at the top of this Privacy Notice.
            </p>
          </section>

          {/* SECTION 12 */}
          <section id="sec-12" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              12. HOW CAN YOU CONTACT US ABOUT THIS NOTICE?
            </h3>
            <div className="p-4 bg-slate-50 dark:bg-slate-800/80 rounded-2xl border border-slate-200 dark:border-slate-700 space-y-1 text-slate-700 dark:text-slate-200">
              <p className="font-extrabold text-slate-900 dark:text-white">Rexo Agency</p>
              <p>Jodhpur, Pal Road</p>
              <p>Jodhpur, Rajasthan 342008, India</p>
              <p className="pt-1 font-bold text-indigo-600 dark:text-indigo-400">
                Email: <a href="mailto:rexoagency.in@gmail.com" className="hover:underline">rexoagency.in@gmail.com</a>
              </p>
            </div>
          </section>

          {/* SECTION 13 */}
          <section id="sec-13" className="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800 pb-4">
            <h3 className="text-sm font-extrabold text-slate-900 dark:text-white">
              13. HOW CAN YOU REVIEW, UPDATE, OR DELETE THE DATA WE COLLECT FROM YOU?
            </h3>
            <p className="text-slate-600 dark:text-slate-400">
              Based on the applicable laws of your country, you may have the right to request access to the personal information we collect from you, correct inaccuracies, or delete your personal data.
            </p>
            <p className="text-slate-600 dark:text-slate-400">
              To submit a data access or deletion request, please log in to your account settings or contact us directly at{' '}
              <a href="mailto:rexoagency.in@gmail.com" className="text-indigo-600 font-bold hover:underline">
                rexoagency.in@gmail.com
              </a>.
            </p>
          </section>

        </div>

        {/* FOOTER ACTION */}
        <div className="p-4 sm:px-6 border-t border-slate-100 dark:border-slate-800 bg-slate-50 dark:bg-slate-900 flex items-center justify-between">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-medium">
            Rexo Store • Privacy Policy Compliant
          </span>
          <button
            onClick={onClose}
            className="px-5 py-2.5 rounded-2xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs shadow-xs transition-all active:scale-95"
          >
            I Understand
          </button>
        </div>

      </div>
    </div>
  );
};
