#!/usr/bin/env node
/**
 * WorkBuddy 服务测试脚本
 * 用于验证后端服务是否正常工作
 */

const http = require('http');

const PORT = process.env.TEST_PORT || 9999;
const TOKEN = 'test-token-12345';

async function makeRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: PORT,
      path,
      method,
      headers: {
        'Authorization': `Bearer ${TOKEN}`,
        'Content-Type': 'application/json',
      },
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });

    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Timeout'));
    });

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('🧪 开始测试 WorkBuddy 服务...\n');

  // 测试 1: Health Check
  console.log('1️⃣  测试 /health 端点...');
  try {
    const resp = await makeRequest('GET', '/health');
    if (resp.status === 200 && resp.body === 'OK') {
      console.log('✅ Health check 通过\n');
    } else {
      console.log('❌ Health check 失败:', resp);
    }
  } catch (error) {
    console.log('❌ Health check 失败:', error.message);
    console.log('⚠️  请先启动服务: OPENCHAMBER_SERVICE_PORT=9999 OPENCHAMBER_SERVICE_TOKEN=test-token-12345 node service/index.js\n');
    process.exit(1);
  }

  // 测试 2: Status
  console.log('2️⃣  测试 /status 端点...');
  try {
    const resp = await makeRequest('GET', '/status');
    const data = JSON.parse(resp.body);
    if (resp.status === 200 && typeof data.enabled === 'boolean') {
      console.log('✅ Status 通过');
      console.log('   状态:', data);
    } else {
      console.log('❌ Status 失败:', resp);
    }
  } catch (error) {
    console.log('❌ Status 失败:', error.message);
  }

  // 测试 3: Login Start
  console.log('\n3️⃣  测试 /login/start 端点...');
  try {
    const resp = await makeRequest('POST', '/login/start');
    const data = JSON.parse(resp.body);
    if (resp.status === 200 && data.loginUrl) {
      console.log('✅ Login start 通过');
      console.log('   登录 URL:', data.loginUrl.substring(0, 80) + '...');
    } else {
      console.log('❌ Login start 失败:', resp);
    }
  } catch (error) {
    console.log('❌ Login start 失败:', error.message);
  }

  // 测试 4: Models
  console.log('\n4️⃣  测试 /models 端点...');
  try {
    const resp = await makeRequest('GET', '/models');
    const data = JSON.parse(resp.body);
    if (resp.status === 200 && Array.isArray(data)) {
      console.log('✅ Models 通过');
      console.log(`   模型数量: ${data.length}`);
      if (data.length > 0) {
        console.log('   示例模型:', data[0].name);
      }
    } else {
      console.log('❌ Models 失败:', resp);
    }
  } catch (error) {
    console.log('❌ Models 失败:', error.message);
  }

  console.log('\n🎉 测试完成！');
}

runTests().catch(console.error);
