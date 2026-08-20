import React from 'react';
import { useData } from '../../context/DataContext';
import { Bell, Sparkles, Calendar, CheckCircle2 } from 'lucide-react';

export const BranchAnnouncements: React.FC = () => {
  const { announcements, themeMode } = useData();
  const isDark = themeMode === 'dark';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-black tracking-tight">HQ Broadcasts & Notices</h1>
        <p className="text-xs text-neutral-500 font-medium">
          Official corporate communications, recipe quality bulletins, and nationwide marketing promos.
        </p>
      </div>

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
              className={`p-6 rounded-3xl border ${
                isDark ? 'bg-[#161616] border-neutral-800' : 'bg-white border-[#80C7F2]/20 shadow-xs'
              }`}
            >
              <div className="flex items-center space-x-2 mb-2">
                <span className="p-1.5 rounded-lg bg-[#80C7F2]/15 text-[#1a7bb5] dark:text-[#80C7F2]">
                  <Sparkles className="w-3.5 h-3.5" />
                </span>
                <h3 className="text-base font-bold text-neutral-900 dark:text-white">
                  {ann.title}
                </h3>
              </div>

              <p className="text-sm text-neutral-600 dark:text-neutral-300 leading-relaxed">
                {ann.message}
              </p>

              <div className="flex items-center justify-between text-xs text-neutral-400 font-medium pt-3 mt-3 border-t border-neutral-100 dark:border-neutral-800">
                <span className="flex items-center space-x-1">
                  <Calendar className="w-3.5 h-3.5" />
                  <span>Posted {new Date(ann.createdAt).toLocaleString()}</span>
                </span>
                <span className="text-emerald-600 dark:text-emerald-400 font-semibold flex items-center space-x-1">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Official HQ Directive</span>
                </span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
