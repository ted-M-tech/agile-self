// Action item type
export interface Action {
  id: string;
  text: string;
  completed: boolean;
  retrospectiveId: string;
  createdAt: string;
  deadline?: string;
  fromTryItem?: boolean;
}

// Retrospective type
export interface Retrospective {
  id: string;
  title: string;
  type: 'weekly' | 'monthly';
  startDate: string;
  endDate: string;
  date: string; // Kept for backward compatibility, same as endDate
  keeps: string[];
  problems: string[];
  tries: string[];
  actions: Action[];
}

// App settings type
export interface AppSettings {
  reminderEnabled: boolean;
  reminderFrequency: 'weekly' | 'monthly';
  reminderDay?: string;
}
