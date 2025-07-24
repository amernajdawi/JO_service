const WebSocket = require('ws');

// Test WebSocket connection and messaging
async function testWebSocket() {
  // You'll need to replace this token with a valid JWT token from your app
  const testToken = 'your_jwt_token_here'; // Get this from your Flutter app's debug logs
  
  const ws = new WebSocket(`ws://10.46.6.119:3000?token=${testToken}`);
  
  ws.on('open', function open() {
    console.log('✅ WebSocket connected successfully');
    
    // Send a test message
    const testMessage = {
      recipientId: 'test_recipient_id', // Replace with actual recipient ID
      text: 'Test message from debug script'
    };
    
    console.log('📤 Sending test message:', testMessage);
    ws.send(JSON.stringify(testMessage));
  });

  ws.on('message', function message(data) {
    console.log('📥 Received message:', data.toString());
    try {
      const parsed = JSON.parse(data.toString());
      console.log('📊 Parsed message:', JSON.stringify(parsed, null, 2));
    } catch (e) {
      console.log('❌ Error parsing message:', e.message);
    }
  });

  ws.on('error', function error(err) {
    console.log('❌ WebSocket error:', err.message);
  });

  ws.on('close', function close() {
    console.log('🔌 WebSocket connection closed');
  });

  // Keep the script running for 30 seconds
  setTimeout(() => {
    console.log('🕒 Closing connection after 30 seconds');
    ws.close();
  }, 30000);
}

console.log('🚀 Starting WebSocket debug test...');
testWebSocket().catch(console.error);
