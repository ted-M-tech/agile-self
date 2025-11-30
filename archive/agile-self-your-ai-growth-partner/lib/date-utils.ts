// Date utility functions for deadline presets and relative date formatting

export function formatDate(d: Date): string {
  return d.toISOString().split('T')[0];
}

export function addDays(date: Date, days: number): Date {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

export function getNextMonday(date: Date = new Date()): Date {
  const result = new Date(date);
  const day = result.getDay();
  const daysUntilMonday = day === 0 ? 1 : 8 - day;
  result.setDate(result.getDate() + daysUntilMonday);
  return result;
}

export function getNextWeekend(date: Date = new Date()): Date {
  const result = new Date(date);
  const day = result.getDay();
  const daysUntilSaturday = day === 6 ? 7 : (6 - day + 7) % 7;
  result.setDate(result.getDate() + daysUntilSaturday);
  return result;
}

export function getRelativeDateText(dateStr: string): string {
  const targetDate = new Date(dateStr);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  targetDate.setHours(0, 0, 0, 0);

  const diffTime = targetDate.getTime() - today.getTime();
  const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Tomorrow";
  if (diffDays === -1) return "Yesterday";
  if (diffDays > 0 && diffDays <= 7) return `In ${diffDays} days`;
  if (diffDays < 0 && diffDays >= -7) return `${Math.abs(diffDays)} days ago`;

  return targetDate.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: targetDate.getFullYear() !== today.getFullYear() ? 'numeric' : undefined
  });
}

export interface DeadlinePreset {
  label: string;
  value: string;
  relativeDays: number;
}

export function getDeadlinePresets(): DeadlinePreset[] {
  const today = new Date();

  return [
    {
      label: "Tomorrow",
      value: formatDate(addDays(today, 1)),
      relativeDays: 1,
    },
    {
      label: "This Weekend",
      value: formatDate(getNextWeekend(today)),
      relativeDays: Math.round((getNextWeekend(today).getTime() - today.getTime()) / (1000 * 60 * 60 * 24)),
    },
    {
      label: "Next Week",
      value: formatDate(addDays(today, 7)),
      relativeDays: 7,
    },
    {
      label: "Next Monday",
      value: formatDate(getNextMonday(today)),
      relativeDays: Math.round((getNextMonday(today).getTime() - today.getTime()) / (1000 * 60 * 60 * 24)),
    },
    {
      label: "In 2 Weeks",
      value: formatDate(addDays(today, 14)),
      relativeDays: 14,
    },
  ];
}

export function getDefaultDeadline(): string {
  // Default to 7 days from now
  return formatDate(addDays(new Date(), 7));
}
