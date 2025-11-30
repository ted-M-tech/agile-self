import { createClient } from './client';
import type { Retrospective, Action } from '@/lib/types';
import type { Database } from './types';

type DbRetrospective = Database['public']['Tables']['retrospectives']['Row'];
type DbAction = Database['public']['Tables']['actions']['Row'];

// Convert DB retrospective to app Retrospective type
function dbToRetrospective(dbRetro: DbRetrospective, actions: DbAction[]): Retrospective {
  return {
    id: dbRetro.id,
    title: dbRetro.title,
    type: dbRetro.type,
    startDate: dbRetro.start_date,
    endDate: dbRetro.end_date,
    date: dbRetro.retro_date,
    keeps: dbRetro.keeps,
    problems: dbRetro.problems,
    tries: dbRetro.tries,
    actions: actions.map(dbToAction),
  };
}

// Convert DB action to app Action type
function dbToAction(dbAction: DbAction): Action {
  return {
    id: dbAction.id,
    text: dbAction.text,
    completed: dbAction.completed,
    retrospectiveId: dbAction.retrospective_id,
    createdAt: dbAction.created_at,
    deadline: dbAction.deadline || undefined,
    fromTryItem: dbAction.from_try_item || undefined,
  };
}

export class DataService {
  private supabase = createClient();

  // Fetch all retrospectives for the current user
  async fetchRetrospectives(userId: string): Promise<Retrospective[]> {
    const { data: retros, error: retroError } = await this.supabase
      .from('retrospectives')
      .select('*')
      .eq('user_id', userId)
      .order('retro_date', { ascending: false });

    if (retroError) throw retroError;
    if (!retros) return [];

    // Fetch all actions for these retrospectives
    const retroIds = retros.map(r => r.id);
    const { data: actions, error: actionsError } = await this.supabase
      .from('actions')
      .select('*')
      .in('retrospective_id', retroIds);

    if (actionsError) throw actionsError;

    // Group actions by retrospective
    const actionsByRetro = (actions || []).reduce((acc, action) => {
      if (!acc[action.retrospective_id]) {
        acc[action.retrospective_id] = [];
      }
      acc[action.retrospective_id].push(action);
      return acc;
    }, {} as Record<string, DbAction[]>);

    return retros.map(retro => 
      dbToRetrospective(retro, actionsByRetro[retro.id] || [])
    );
  }

  // Save a new retrospective
  async saveRetrospective(userId: string, retrospective: Retrospective): Promise<void> {
    // Insert retrospective
    const { data: retroData, error: retroError } = await this.supabase
      .from('retrospectives')
      .insert({
        id: retrospective.id,
        user_id: userId,
        title: retrospective.title,
        type: retrospective.type,
        start_date: retrospective.startDate,
        end_date: retrospective.endDate,
        retro_date: retrospective.date,
        keeps: retrospective.keeps,
        problems: retrospective.problems,
        tries: retrospective.tries,
      })
      .select()
      .single();

    if (retroError) throw retroError;

    // Insert actions
    if (retrospective.actions.length > 0) {
      const actionsToInsert = retrospective.actions.map(action => ({
        id: action.id,
        retrospective_id: retrospective.id,
        user_id: userId,
        text: action.text,
        completed: action.completed,
        deadline: action.deadline || null,
        from_try_item: action.fromTryItem || false,
      }));

      const { error: actionsError } = await this.supabase
        .from('actions')
        .insert(actionsToInsert);

      if (actionsError) throw actionsError;
    }
  }

  // Delete a retrospective (cascades to actions)
  async deleteRetrospective(retrospectiveId: string): Promise<void> {
    const { error } = await this.supabase
      .from('retrospectives')
      .delete()
      .eq('id', retrospectiveId);

    if (error) throw error;
  }

  // Update an action
  async updateAction(actionId: string, updates: Partial<Action>): Promise<void> {
    const dbUpdates: any = {};
    
    if (updates.text !== undefined) dbUpdates.text = updates.text;
    if (updates.completed !== undefined) dbUpdates.completed = updates.completed;
    if (updates.deadline !== undefined) dbUpdates.deadline = updates.deadline;

    const { error } = await this.supabase
      .from('actions')
      .update(dbUpdates)
      .eq('id', actionId);

    if (error) throw error;
  }

  // Delete an action
  async deleteAction(actionId: string): Promise<void> {
    const { error } = await this.supabase
      .from('actions')
      .delete()
      .eq('id', actionId);

    if (error) throw error;
  }

  // Fetch user preferences
  async fetchPreferences(userId: string) {
    const { data, error } = await this.supabase
      .from('user_preferences')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error && error.code !== 'PGRST116') throw error; // Ignore "not found" error
    return data;
  }

  // Update user preferences
  async updatePreferences(userId: string, preferences: any): Promise<void> {
    const { error } = await this.supabase
      .from('user_preferences')
      .upsert({
        user_id: userId,
        ...preferences,
      });

    if (error) throw error;
  }

  // Clear all user data (for settings)
  async clearAllData(userId: string): Promise<void> {
    // Delete retrospectives (actions will cascade)
    const { error: retroError } = await this.supabase
      .from('retrospectives')
      .delete()
      .eq('user_id', userId);

    if (retroError) throw retroError;

    // Reset preferences
    const { error: prefError } = await this.supabase
      .from('user_preferences')
      .update({
        reminder_enabled: false,
        theme: 'light',
      })
      .eq('user_id', userId);

    if (prefError) throw prefError;
  }
}

export const dataService = new DataService();
