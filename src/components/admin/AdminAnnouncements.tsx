import React, { useState } from 'react';
import { useData } from '../../context/DataContext';
import {
  Bell,
  Plus,
  Trash2,
  Calendar,
  Sparkles,
  Send,
  MessageSquare,
} from 'lucide-react';

export const AdminAnnouncements: React.FC = () => {
  const { announcements, addAnnouncement, deleteAnnouncement, themeMode } = useData();

  const [showAddModal, setShowAddModal] = useState(false);
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');

  const isDark = themeMode === 'dark';

  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !message.trim()) return;
    addAnnouncement(title.trim(), message.trim());
    setShowAddModal(false);
    setTitle('');
    setMessage('');
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black tracking-tight">HQ Announcements & Broadcasts</h1>
          <p className="text-xs text-neutral-500 font-medium">
            Broadcast official notices, promo instructions, and quality memos to all 19 branch managers.
          </p>
        </div>

        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2.5 rounded-xl bg-[#F37021] text-white text-xs sm:text-sm font-bold shadow-md hover:bg-[#d85e15] transition-all flex items-center space-x-1.5 self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>New Broadcast Notice</span>
        </button>
      </div>

      {/* Announcements List */}
      <div className="space-y-4">
        {announcements.length === 0 ? (
          <div className={`p-12 text-center rounded-3xl border ${
            isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-neutral-200'
          }`}>
            <Bell className="w-12 h-12 text-neutral-400 mx-auto mb-3 opacity-60" />
            <p className="text-sm font-bold">No announcements published</p>
          </div>
        ) : (
          announcements.map((ann) => (
            <div
              key={ann.id}
              className={`p-6 rounded-3xl border transition-all relative ${
                isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'
              }`}
            >
              <div className="flex items-start justify-between gap-4">
                <div className="space-y-2">
                  <div className="flex items-center space-x-2">
                    <span className="p-1.5 rounded-lg bg-[#80C7F2]/15 text-[#1a7bb5] dark:text-[#80C7F2]">
                      <Sparkles className="w-3.5 h-3.5" />
                    </span>
                    <h3 className="text-base font-bold">{ann.title}</h3>
                  </div>

                  <p className="text-sm text-neutral-600 dark:text-neutral-300 leading-relaxed">
                    {ann.message}
                  </p>

                  <p className="text-xs text-neutral-400 font-medium pt-1 flex items-center space-x-1">
                    <Calendar className="w-3.5 h-3.5" />
                    <span>Posted {new Date(ann.createdAt).toLocaleString()}</span>
                  </p>
                </div>

                <button
                  onClick={() => deleteAnnouncement(ann.id)}
                  className="p-2 rounded-xl text-neutral-400 hover:text-red-500 hover:bg-red-500/10 transition-colors flex-shrink-0"
                  title="Delete Announcement"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Broadcast Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className={`w-full max-w-md rounded-3xl p-6 shadow-2xl border ${
            isDark ? 'bg-[#1c1c1c] border-neutral-700 text-white' : 'bg-white border-neutral-200 text-neutral-900'
          }`}>
            <div className="flex items-center space-x-2 text-[#F37021] mb-2">
              <Send className="w-5 h-5" />
              <h3 className="text-base font-bold">Publish Broadcast Announcement</h3>
            </div>
            <p className="text-xs text-neutral-500">
              This message will immediately appear on all 19 branch manager dashboards.
            </p>

            <form onSubmit={handleAdd} className="mt-4 space-y-3 text-xs">
              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Subject / Heading
                </label>
                <input
                  type="text"
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g. Weekend Promo Guidelines & Bicol Restock Schedule"
                  className={`w-full p-2.5 rounded-xl border ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div>
                <label className="block font-bold uppercase tracking-wider text-neutral-400 mb-1">
                  Announcement Body
                </label>
                <textarea
                  rows={4}
                  required
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="Type full instructions or notice..."
                  className={`w-full p-2.5 rounded-xl border ${
                    isDark ? 'bg-neutral-900 border-neutral-700 text-white' : 'bg-neutral-50 border-neutral-200'
                  }`}
                />
              </div>

              <div className="flex items-center justify-end space-x-2 pt-3">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-3.5 py-2 font-medium rounded-xl border border-neutral-300 dark:border-neutral-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 font-bold rounded-xl bg-[#F37021] text-white hover:bg-[#d85e15]"
                >
                  Publish Broadcast
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
