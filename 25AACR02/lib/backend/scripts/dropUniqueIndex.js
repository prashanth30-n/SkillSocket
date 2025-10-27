const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB using environment variable
const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/barter';
mongoose.connect(mongoUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});

const db = mongoose.connection;

db.once('open', async () => {
    try {
        console.log('Connected to MongoDB');
        
        // Drop the unique index on from_1_to_1
        const collection = db.collection('connectionrequests');
        
        try {
            await collection.dropIndex('from_1_to_1');
            console.log('✅ Successfully dropped unique index: from_1_to_1');
        } catch (error) {
            if (error.code === 27) {
                console.log('ℹ️  Index from_1_to_1 does not exist (already dropped)');
            } else {
                console.error('❌ Error dropping index:', error);
            }
        }
        
        // Create new non-unique indexes
        try {
            await collection.createIndex({ from: 1, to: 1 });
            console.log('✅ Created new non-unique index: from_1_to_1');
        } catch (error) {
            console.error('❌ Error creating new index:', error);
        }
        
        try {
            await collection.createIndex({ from: 1, to: 1, status: 1 });
            console.log('✅ Created new compound index: from_1_to_1_status_1');
        } catch (error) {
            console.error('❌ Error creating compound index:', error);
        }
        
        console.log('🎉 Database migration completed successfully!');
        console.log('Now users can send new connection requests after rejection.');
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Migration failed:', error);
        process.exit(1);
    }
});

db.on('error', (error) => {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
});
