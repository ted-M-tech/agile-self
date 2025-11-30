export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      retrospectives: {
        Row: {
          id: string
          user_id: string
          title: string
          type: 'weekly' | 'monthly'
          start_date: string
          end_date: string
          retro_date: string
          keeps: string[]
          problems: string[]
          tries: string[]
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          title: string
          type: 'weekly' | 'monthly'
          start_date: string
          end_date: string
          retro_date: string
          keeps?: string[]
          problems?: string[]
          tries?: string[]
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          title?: string
          type?: 'weekly' | 'monthly'
          start_date?: string
          end_date?: string
          retro_date?: string
          keeps?: string[]
          problems?: string[]
          tries?: string[]
          created_at?: string
          updated_at?: string
        }
      }
      actions: {
        Row: {
          id: string
          retrospective_id: string
          user_id: string
          text: string
          completed: boolean
          deadline: string | null
          from_try_item: boolean
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          retrospective_id: string
          user_id: string
          text: string
          completed?: boolean
          deadline?: string | null
          from_try_item?: boolean
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          retrospective_id?: string
          user_id?: string
          text?: string
          completed?: boolean
          deadline?: string | null
          from_try_item?: boolean
          created_at?: string
          updated_at?: string
        }
      }
      user_preferences: {
        Row: {
          id: string
          user_id: string
          reminder_enabled: boolean
          reminder_frequency: 'weekly' | 'monthly' | null
          reminder_day_of_week: number | null
          reminder_day_of_month: number | null
          theme: 'light' | 'dark'
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          reminder_enabled?: boolean
          reminder_frequency?: 'weekly' | 'monthly' | null
          reminder_day_of_week?: number | null
          reminder_day_of_month?: number | null
          theme?: 'light' | 'dark'
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          reminder_enabled?: boolean
          reminder_frequency?: 'weekly' | 'monthly' | null
          reminder_day_of_week?: number | null
          reminder_day_of_month?: number | null
          theme?: 'light' | 'dark'
          created_at?: string
          updated_at?: string
        }
      }
    }
  }
}
