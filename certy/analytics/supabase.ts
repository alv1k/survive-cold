// Supabase analytics utilities
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || '';
const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY || '';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Function to track an event in Supabase
export const trackEvent = async (event_type: string, properties: Record<string, any>, user_id?: string) => {
  try {
    const { data, error } = await supabase
      .from('analytics_events')
      .insert([{
        event_type,
        properties,
        user_id,
        timestamp: new Date().toISOString()
      }]);

    if (error) {
      console.error('Error tracking event:', error);
      return { success: false, error };
    }

    return { success: true, data };
  } catch (error) {
    console.error('Error tracking event:', error);
    return { success: false, error };
  }
};

// Function to get user analytics
export const getUserAnalytics = async (user_id: string) => {
  try {
    const { data, error } = await supabase
      .from('user_analytics')
      .select('*')
      .eq('user_id', user_id)
      .order('created_at', { ascending: false })
      .limit(10);

    if (error) {
      console.error('Error fetching user analytics:', error);
      return { success: false, error };
    }

    return { success: true, data };
  } catch (error) {
    console.error('Error fetching user analytics:', error);
    return { success: false, error };
  }
};

// Function to get overall analytics for admin dashboard
export const getOverallAnalytics = async () => {
  try {
    // Get total users
    const { count: totalUsers } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true });

    // Get recent events
    const { data: recentEvents } = await supabase
      .from('analytics_events')
      .select('*')
      .order('timestamp', { ascending: false })
      .limit(10);

    // Get event counts by type
    const { data: eventCounts } = await supabase.rpc('get_event_counts');

    return {
      success: true,
      totalUsers,
      recentEvents,
      eventCounts
    };
  } catch (error) {
    console.error('Error fetching overall analytics:', error);
    return { success: false, error };
  }
};