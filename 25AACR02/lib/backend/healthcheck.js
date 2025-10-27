const https = require('https');

const options = {
  hostname: 'skillsocket-backend.onrender.com',
  port: 443,
  path: '/api/health',
  method: 'GET',
  timeout: 2000,
};

const req = https.request(options, (res) => {
  console.log(`Health check status: ${res.statusCode}`);
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

req.on('error', (err) => {
  console.log('Health check failed:', err.message);
  process.exit(1);
});

req.end();
