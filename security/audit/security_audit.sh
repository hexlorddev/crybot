#!/bin/bash

# CryBot Security Audit Script
# Comprehensive security analysis for CryBot installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRYBOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
AUDIT_REPORT="$CRYBOT_DIR/security_audit_$(date +%Y%m%d_%H%M%S).txt"

echo "🛡️ CryBot Security Audit" | tee "$AUDIT_REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$AUDIT_REPORT"
echo "Date: $(date)" | tee -a "$AUDIT_REPORT"
echo "System: $(uname -a)" | tee -a "$AUDIT_REPORT"
echo "" | tee -a "$AUDIT_REPORT"

# Check file permissions
echo "📁 File Permissions Analysis" | tee -a "$AUDIT_REPORT"
echo "─────────────────────────────" | tee -a "$AUDIT_REPORT"

check_permissions() {
    local file="$1"
    local expected="$2"
    local description="$3"
    
    if [ -f "$file" ] || [ -d "$file" ]; then
        actual=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
        if [ "$actual" = "$expected" ]; then
            echo "✅ $description: $actual (correct)" | tee -a "$AUDIT_REPORT"
        else
            echo "⚠️  $description: $actual (expected $expected)" | tee -a "$AUDIT_REPORT"
        fi
    else
        echo "❌ $description: File not found" | tee -a "$AUDIT_REPORT"
    fi
}

check_permissions "$CRYBOT_DIR/crybot" "755" "CryBot executable"
check_permissions "$CRYBOT_DIR/configs" "750" "Configuration directory"
check_permissions "$CRYBOT_DIR/logs" "700" "Logs directory"
check_permissions "$CRYBOT_DIR/plugins" "755" "Plugins directory"

# Check for sensitive files
echo "" | tee -a "$AUDIT_REPORT"
echo "🔍 Sensitive Files Check" | tee -a "$AUDIT_REPORT"
echo "────────────────────────" | tee -a "$AUDIT_REPORT"

find "$CRYBOT_DIR" -name "*.key" -o -name "*.pem" -o -name "*password*" -o -name "*secret*" | while read -r file; do
    perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
    if [ "$perms" -gt 600 ]; then
        echo "⚠️  $file: permissions too open ($perms)" | tee -a "$AUDIT_REPORT"
    else
        echo "✅ $file: secure permissions ($perms)" | tee -a "$AUDIT_REPORT"
    fi
done

# Check encryption configuration
echo "" | tee -a "$AUDIT_REPORT"
echo "🔐 Encryption Configuration" | tee -a "$AUDIT_REPORT"
echo "───────────────────────────" | tee -a "$AUDIT_REPORT"

config_file="$CRYBOT_DIR/crybot_config.json"
if [ -f "$config_file" ]; then
    if grep -q '"encryption_enabled": true' "$config_file"; then
        echo "✅ Log encryption is enabled" | tee -a "$AUDIT_REPORT"
    else
        echo "⚠️  Log encryption is disabled" | tee -a "$AUDIT_REPORT"
    fi
    
    # Check for weak passwords
    if grep -q '"password": "' "$config_file"; then
        echo "⚠️  Plaintext passwords found in config" | tee -a "$AUDIT_REPORT"
    else
        echo "✅ No plaintext passwords in config" | tee -a "$AUDIT_REPORT"
    fi
else
    echo "❌ Configuration file not found" | tee -a "$AUDIT_REPORT"
fi

# Check network security
echo "" | tee -a "$AUDIT_REPORT"
echo "🌐 Network Security" | tee -a "$AUDIT_REPORT"
echo "───────────────────" | tee -a "$AUDIT_REPORT"

# Check for open ports
open_ports=$(netstat -tuln 2>/dev/null | grep -E ':80[0-9][0-9]\s' | wc -l || echo "0")
if [ "$open_ports" -gt 0 ]; then
    echo "⚠️  Found $open_ports potentially CryBot-related open ports" | tee -a "$AUDIT_REPORT"
    netstat -tuln 2>/dev/null | grep -E ':80[0-9][0-9]\s' | tee -a "$AUDIT_REPORT"
else
    echo "✅ No suspicious open ports detected" | tee -a "$AUDIT_REPORT"
fi

# Check plugin security
echo "" | tee -a "$AUDIT_REPORT"
echo "🧩 Plugin Security" | tee -a "$AUDIT_REPORT"
echo "──────────────────" | tee -a "$AUDIT_REPORT"

plugin_count=0
unsigned_plugins=0

if [ -d "$CRYBOT_DIR/plugins" ]; then
    for plugin in "$CRYBOT_DIR/plugins"/*.cryplugin; do
        if [ -f "$plugin" ]; then
            plugin_count=$((plugin_count + 1))
            
            # Check for plugin signature
            if grep -q "signature:" "$plugin"; then
                echo "✅ $(basename "$plugin"): digitally signed" | tee -a "$AUDIT_REPORT"
            else
                echo "⚠️  $(basename "$plugin"): unsigned plugin" | tee -a "$AUDIT_REPORT"
                unsigned_plugins=$((unsigned_plugins + 1))
            fi
            
            # Check for dangerous permissions
            if grep -q "system_access\|file_access\|network_access" "$plugin"; then
                echo "⚠️  $(basename "$plugin"): requests sensitive permissions" | tee -a "$AUDIT_REPORT"
            fi
        fi
    done
    
    echo "📊 Plugin Summary: $plugin_count total, $unsigned_plugins unsigned" | tee -a "$AUDIT_REPORT"
else
    echo "❌ Plugins directory not found" | tee -a "$AUDIT_REPORT"
fi

# Check log files for security events
echo "" | tee -a "$AUDIT_REPORT"
echo "📋 Security Log Analysis" | tee -a "$AUDIT_REPORT"
echo "────────────────────────" | tee -a "$AUDIT_REPORT"

if [ -d "$CRYBOT_DIR/logs" ]; then
    # Check for failed authentication attempts
    failed_auth=$(find "$CRYBOT_DIR/logs" -name "*.log" -exec grep -c "authentication failed\|login failed\|access denied" {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$failed_auth" -gt 10 ]; then
        echo "⚠️  High number of authentication failures: $failed_auth" | tee -a "$AUDIT_REPORT"
    else
        echo "✅ Authentication failures within normal range: $failed_auth" | tee -a "$AUDIT_REPORT"
    fi
    
    # Check for suspicious commands
    suspicious_commands=$(find "$CRYBOT_DIR/logs" -name "*.log" -exec grep -c "rm -rf\|sudo\|passwd\|su " {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    
    if [ "$suspicious_commands" -gt 5 ]; then
        echo "⚠️  Suspicious commands detected: $suspicious_commands" | tee -a "$AUDIT_REPORT"
    else
        echo "✅ No suspicious commands detected" | tee -a "$AUDIT_REPORT"
    fi
else
    echo "❌ Logs directory not found" | tee -a "$AUDIT_REPORT"
fi

# Check system dependencies
echo "" | tee -a "$AUDIT_REPORT"
echo "🔧 System Dependencies" | tee -a "$AUDIT_REPORT"
echo "──────────────────────" | tee -a "$AUDIT_REPORT"

check_dependency() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        version=$(eval "$cmd --version 2>/dev/null | head -1" || echo "unknown")
        echo "✅ $description: installed ($version)" | tee -a "$AUDIT_REPORT"
    else
        echo "⚠️  $description: not installed" | tee -a "$AUDIT_REPORT"
    fi
}

check_dependency "crystal" "Crystal compiler"
check_dependency "openssl" "OpenSSL"
check_dependency "gpg" "GnuPG"

# Generate security score
echo "" | tee -a "$AUDIT_REPORT"
echo "🏆 Security Score" | tee -a "$AUDIT_REPORT"
echo "─────────────────" | tee -a "$AUDIT_REPORT"

score=100
issues=0

# Deduct points for issues found
if grep -q "⚠️" "$AUDIT_REPORT"; then
    warnings=$(grep -c "⚠️" "$AUDIT_REPORT")
    score=$((score - warnings * 5))
    issues=$((issues + warnings))
fi

if grep -q "❌" "$AUDIT_REPORT"; then
    errors=$(grep -c "❌" "$AUDIT_REPORT")
    score=$((score - errors * 10))
    issues=$((issues + errors))
fi

if [ "$score" -ge 90 ]; then
    echo "🟢 Security Score: $score/100 (Excellent)" | tee -a "$AUDIT_REPORT"
elif [ "$score" -ge 70 ]; then
    echo "🟡 Security Score: $score/100 (Good)" | tee -a "$AUDIT_REPORT"
elif [ "$score" -ge 50 ]; then
    echo "🟠 Security Score: $score/100 (Fair)" | tee -a "$AUDIT_REPORT"
else
    echo "🔴 Security Score: $score/100 (Needs Attention)" | tee -a "$AUDIT_REPORT"
fi

echo "Issues found: $issues" | tee -a "$AUDIT_REPORT"

# Generate recommendations
echo "" | tee -a "$AUDIT_REPORT"
echo "💡 Security Recommendations" | tee -a "$AUDIT_REPORT"
echo "───────────────────────────" | tee -a "$AUDIT_REPORT"

if [ "$issues" -gt 0 ]; then
    echo "1. Review and fix the issues marked with ⚠️ and ❌ above" | tee -a "$AUDIT_REPORT"
    echo "2. Enable log encryption if not already enabled" | tee -a "$AUDIT_REPORT"
    echo "3. Regularly audit plugin permissions and signatures" | tee -a "$AUDIT_REPORT"
    echo "4. Monitor logs for suspicious activity" | tee -a "$AUDIT_REPORT"
    echo "5. Keep CryBot and dependencies updated" | tee -a "$AUDIT_REPORT"
else
    echo "✅ Your CryBot installation appears to be secure!" | tee -a "$AUDIT_REPORT"
    echo "Continue following security best practices:" | tee -a "$AUDIT_REPORT"
    echo "• Regularly update CryBot and plugins" | tee -a "$AUDIT_REPORT"
    echo "• Monitor logs for unusual activity" | tee -a "$AUDIT_REPORT"
    echo "• Only install trusted plugins" | tee -a "$AUDIT_REPORT"
fi

echo "" | tee -a "$AUDIT_REPORT"
echo "🛡️ Audit complete! Report saved to: $AUDIT_REPORT" | tee -a "$AUDIT_REPORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$AUDIT_REPORT"