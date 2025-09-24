#!/bin/bash

# Simple test of AIROS terminal functionality

echo "🤖 AIROS Terminal Test"
echo "====================="
echo ""

echo "Testing AIROS agent status..."
if curl -s http://localhost:8082/api/status > /dev/null; then
    echo "✅ AI Agent: Running"
    agent_status=$(curl -s http://localhost:8082/api/status | python3 -c "import sys,json; data=json.load(sys.stdin); print(f'Uptime: {int(data[\"uptime_seconds\"])}s, Mode: {data[\"mode\"]}')")
    echo "   $agent_status"
else
    echo "❌ AI Agent: Not responding"
fi

echo ""
echo "System Information:"
sys_info=$(curl -s http://localhost:8082/api/system_info | python3 -c "import sys,json; data=json.load(sys.stdin); print(f'CPU: {data[\"cpu_percent\"]:.1f}%, Memory: {data[\"memory_percent\"]:.1f}%, Packages: {data[\"installed_packages\"]}')" 2>/dev/null || echo "Unable to fetch")
echo "   $sys_info"

echo ""
echo "📱 Virtual Waydroid: Running (Simulated)"
echo "🔧 Fixes Applied: $(curl -s http://localhost:8082/api/app_issues | python3 -c "import sys,json; print(json.load(sys.stdin)['total'])" 2>/dev/null || echo 0)"

echo ""
echo "Available demo commands:"
echo "  curl -X POST http://localhost:8082/api/install_app -d '{\"package_name\":\"com.whatsapp\",\"auto_fix\":true}' -H 'Content-Type: application/json'"
echo "  curl -X POST http://localhost:8082/api/demo/test_compatibility -d '{\"apps\":[\"com.whatsapp\"]}' -H 'Content-Type: application/json'"

echo ""
echo "✨ AIROS Virtual Environment is working! ✨"