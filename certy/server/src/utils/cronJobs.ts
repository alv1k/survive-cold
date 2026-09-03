import cron from 'node-cron';
import { pool } from '../config/db';

// Cron job to send subscription renewal reminders
// This would run daily at 9 AM
cron.schedule('0 9 * * *', async () => {
  console.log('Running subscription renewal reminder job');
  
  try {
    // Find subscriptions that expire in the next 3 days
    const result = await pool.query(`
      SELECT u.email, u.name, s.end_date, s.plan_name
      FROM subscriptions s
      JOIN users u ON s.user_id = u.id
      WHERE s.is_active = true 
      AND s.end_date BETWEEN NOW() AND NOW() + INTERVAL '3 days'
      AND s.renewal_reminder_sent = false
    `);
    
    for (const subscription of result.rows) {
      // Send renewal reminder email
      console.log(`Sending renewal reminder to ${subscription.email} for ${subscription.plan_name} expiring on ${subscription.end_date}`);
      
      // In a real implementation, you would send an email here
      // await sendRenewalReminderEmail(subscription.email, subscription);
      
      // Mark reminder as sent
      await pool.query(
        'UPDATE subscriptions SET renewal_reminder_sent = true WHERE id = $1',
        [subscription.id]
      );
    }
  } catch (error) {
    console.error('Error in subscription renewal reminder job:', error);
  }
});

// Cron job to deactivate expired subscriptions
// This would run daily at midnight
cron.schedule('0 0 * * *', async () => {
  console.log('Running expired subscription deactivation job');
  
  try {
    // Find subscriptions that expired
    const result = await pool.query(`
      UPDATE subscriptions 
      SET is_active = false 
      WHERE is_active = true AND end_date < NOW()
      RETURNING id, user_id
    `);
    
    if (result.rows.length > 0) {
      console.log(`Deactivated ${result.rows.length} expired subscriptions`);
      
      // In a real implementation, you might want to notify users
      // that their subscription has expired
    }
  } catch (error) {
    console.error('Error in expired subscription deactivation job:', error);
  }
});

// Cron job to reset coupon usage counts periodically (if needed)
// This would run daily at 11:59 PM
cron.schedule('59 23 * * *', async () => {
  console.log('Running daily cleanup job');
  
  try {
    // Example: Reset daily usage limits for certain features
    // This is just an example - implement based on your specific needs
    
    console.log('Daily cleanup completed');
  } catch (error) {
    console.error('Error in daily cleanup job:', error);
  }
});

console.log('Cron jobs scheduled');