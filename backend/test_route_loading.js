try {
  console.log('Testing route loading...');

  const doctorsRoutes = require('./routes/doctors');
  console.log('✅ doctors route loaded:', typeof doctorsRoutes);

  const appointmentsRoutes = require('./routes/appointments');
  console.log('✅ appointments route loaded:', typeof appointmentsRoutes);

  const chatRoutes = require('./routes/chat');
  console.log('✅ chat route loaded:', typeof chatRoutes);

  const reportsRoutes = require('./routes/reports');
  console.log('✅ reports route loaded:', typeof reportsRoutes);

  const pharmacyRoutes = require('./routes/pharmacy');
  console.log('✅ pharmacy route loaded:', typeof pharmacyRoutes);

  console.log('All routes loaded successfully!');

} catch (error) {
  console.error('❌ Error loading routes:', error.message);
  console.error('Stack:', error.stack);
}