import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Send, User, Check, CheckCheck } from 'lucide-react';
import { useStore } from '../../context/StoreContext';
import { Campaign, UserProfile } from '../../types';

interface ChatModalProps {
  campaign: Campaign;
  recipientId: string;
  onClose: () => void;
}

export const ChatModal: React.FC<ChatModalProps> = ({ campaign, recipientId, onClose }) => {
  const { state, sendMessage, markMessagesAsRead } = useStore();
  const [text, setText] = useState('');
  const bottomRef = useRef<HTMLDivElement>(null);
  
  const recipient = state.users.find(u => u.id === recipientId);
  
  const chatMessages = state.messages.filter(m => 
    m.campaignId === campaign.id && 
    (m.senderId === state.currentUser?.id || m.receiverId === state.currentUser?.id)
  ).sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

  useEffect(() => {
    markMessagesAsRead(campaign.id);
  }, [campaign.id, state.messages.length]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [chatMessages]);

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!text.trim()) return;
    sendMessage(campaign.id, recipientId, text);
    setText('');
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-sm animate-in fade-in flex justify-center items-end sm:items-center p-0 sm:p-4">
        <motion.div
          initial={{ y: "100%" }}
          animate={{ y: 0 }}
          exit={{ y: "100%" }}
          transition={{ type: "spring", damping: 25, stiffness: 200 }}
          className="w-full max-w-lg bg-white dark:bg-slate-950 rounded-t-3xl sm:rounded-3xl shadow-2xl overflow-hidden flex flex-col h-[85vh] sm:h-[600px]"
        >
          {/* Header */}
          <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between bg-white dark:bg-slate-900 z-10 shadow-sm relative">
            <div className="flex items-center gap-3">
              {recipient?.avatar ? (
                <img src={recipient.avatar} alt={recipient.name} className="w-10 h-10 rounded-full object-cover border border-slate-200" />
              ) : (
                <div className="w-10 h-10 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
                  <User size={20} className="text-slate-400" />
                </div>
              )}
              <div>
                <h3 className="text-sm font-extrabold text-slate-900 dark:text-white leading-tight">{recipient?.name}</h3>
                <p className="text-[10px] text-slate-500 font-medium">Re: {campaign.title}</p>
              </div>
            </div>
            <button onClick={onClose} className="p-2 bg-slate-50 dark:bg-slate-800 rounded-full text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
              <X size={18} />
            </button>
          </div>

          {/* Chat History */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-slate-50/50 dark:bg-slate-950/50">
            {chatMessages.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-center opacity-50">
                <div className="w-16 h-16 bg-slate-200 dark:bg-slate-800 rounded-full flex items-center justify-center mb-3">
                  <Send size={24} className="text-slate-400" />
                </div>
                <p className="text-sm font-bold text-slate-500">No messages yet</p>
                <p className="text-[11px] text-slate-400">Start the conversation about this campaign.</p>
              </div>
            ) : (
              chatMessages.map((msg, index) => {
                const isMe = msg.senderId === state.currentUser?.id;
                const showAvatar = index === 0 || chatMessages[index - 1].senderId !== msg.senderId;
                
                return (
                  <motion.div 
                    initial={{ opacity: 0, y: 5 }} 
                    animate={{ opacity: 1, y: 0 }} 
                    key={msg.id} 
                    className={`flex ${isMe ? 'justify-end' : 'justify-start'} items-end gap-2`}
                  >
                    {!isMe && showAvatar && recipient?.avatar && (
                       <img src={recipient.avatar} alt="avatar" className="w-6 h-6 rounded-full object-cover shrink-0" />
                    )}
                    {!isMe && showAvatar && !recipient?.avatar && (
                       <div className="w-6 h-6 rounded-full bg-slate-200 shrink-0" />
                    )}
                    {!isMe && !showAvatar && <div className="w-6 h-6 shrink-0" />}

                    <div className={`max-w-[75%] rounded-2xl p-3 text-[13px] relative group ${
                      isMe 
                        ? 'bg-indigo-600 text-white rounded-br-sm' 
                        : 'bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 shadow-sm border border-slate-100 dark:border-slate-700/50 rounded-bl-sm'
                    }`}>
                      <p className="leading-relaxed">{msg.text}</p>
                      <div className={`text-[9px] mt-1 flex items-center gap-1 ${isMe ? 'text-indigo-200 justify-end' : 'text-slate-400'}`}>
                        {new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        {isMe && (
                          msg.read ? <CheckCheck size={12} className="text-indigo-200" /> : <Check size={12} className="text-indigo-300" />
                        )}
                      </div>
                    </div>
                  </motion.div>
                );
              })
            )}
            <div ref={bottomRef} />
          </div>

          {/* Input Area */}
          <div className="p-3 bg-white dark:bg-slate-900 border-t border-slate-100 dark:border-slate-800">
            <form onSubmit={handleSend} className="flex items-center gap-2 relative">
              <input
                type="text"
                value={text}
                onChange={e => setText(e.target.value)}
                placeholder="Type a message..."
                className="w-full bg-slate-100 dark:bg-slate-800/50 border border-transparent focus:border-indigo-500 focus:bg-white dark:focus:bg-slate-900 rounded-full px-5 py-3.5 text-sm text-slate-900 dark:text-white placeholder:text-slate-400 outline-none transition-all pr-12"
              />
              <button 
                type="submit" 
                disabled={!text.trim()}
                className="absolute right-2 p-2 bg-indigo-600 text-white rounded-full disabled:opacity-50 hover:bg-indigo-700 transition-colors"
              >
                <Send size={16} className={text.trim() ? "ml-0.5" : ""} />
              </button>
            </form>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
