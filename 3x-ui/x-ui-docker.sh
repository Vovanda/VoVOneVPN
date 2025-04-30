#!/bin/bash

# Цвета
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
cyan='\033[0;36m'
plain='\033[0m'

# Переменные окружения
XUI_BIN_FOLDER="${XUI_BIN_FOLDER:-/app/bin}"
XUI_APP_BIN="${XUI_APP_FOLDER:-/app}/x-ui"
XUI_DB="${XUI_DB_FOLDER:-/etc/x-ui}/x-ui.db"
XUI_LOG="${XUI_LOG_FOLDER:-/var/log/x-ui}/x-ui.log"
FAIL2BAN_ENABLED="${X_UI_ENABLE_FAIL2BAN:-false}"
XRAY_PROCESS_NAME="xray-linux-amd64"

# Проверка root
[[ $EUID -ne 0 ]] && echo -e "${red}Error:${plain} Script must be run as root!" && exit 1

show_menu() {
    echo -e "
${cyan}╔────────────────────────────────────────────────╗
│ ${green}🚀 3X-UI Docker Management (ENV Configured) ${cyan} │
├────────────────────────────────────────────────┤
│ ${green}1.${plain} Reset Admin Credentials                 │
│ ${green}2.${plain} Change Web Panel Path                  │
│ ${green}3.${plain} Reset All Settings                     │
│ ${green}4.${plain} Change Panel Port                      │
│ ${green}5.${plain} Show Current Settings                  │
├────────────────────────────────────────────────┤
│ ${green}6.${plain} ▶ Start X-UI Panel                     │
│ ${green}7.${plain} ■ Stop X-UI Panel                      │
│ ${green}8.${plain} 🔄 Restart X-UI Panel                  │
│ ${green}9.${plain} 📊 Check Service Status                │
├────────────────────────────────────────────────┤
│ ${green}10.${plain} 🚀 Enable BBR Optimization           │
│ ${green}11.${plain} 🌍 Update Geo Databases              │
│ ${green}12.${plain} 🚦 Configure Fail2Ban                │
│ ${green}13.${plain} 📶 Run Speed Test (Ookla)            │
│ ${green}0.${plain} 🔚 Exit                               │
${cyan}╚────────────────────────────────────────────────╝${plain}"
}

header() {
    clear
    echo -e "${cyan}███████╗  X-UI Docker Management  ███████╗${plain}"
    echo -e "\nConfig Paths:"
    echo -e "  Binary: ${green}${XUI_APP_BIN}${plain}"
    echo -e "  Database: ${green}${XUI_DB}${plain}"
    echo -e "  Logs: ${green}${XUI_LOG}${plain}"
    echo -e "  Fail2Ban: ${green}${FAIL2BAN_ENABLED}${plain}\n"
}

check_status() {
    local xui_pid=$(pgrep -f "${XUI_APP_BIN}" 2>/dev/null)
    local xray_pid=$(pgrep -f "${XRAY_PROCESS_NAME}" 2>/dev/null)
    local fail2ban_pid=$(pgrep -f "fail2ban-server" 2>/dev/null)

    if [ -n "$xui_pid" ]; then
        echo -e "${green}● X-UI Status: Running (PID: ${xui_pid})${plain}"
    else
        echo -e "${red}● X-UI Status: Stopped${plain}"
    fi

    if [ -n "$xray_pid" ]; then
        echo -e "${green}● Xray Status: Running (PID: ${xray_pid})${plain}"
    else
        echo -e "${red}● Xray Status: Stopped${plain}"
    fi

    if [ "$FAIL2BAN_ENABLED" = "true" ]; then
        if [ -n "$fail2ban_pid" ]; then
            echo -e "${green}● Fail2Ban Status: Running (PID: ${fail2ban_pid})${plain}"
        else
            echo -e "${red}● Fail2Ban Status: Stopped${plain}"
        fi
    fi
}

start_panel() {
    echo -e "\n${green}✓ Starting X-UI...${plain}"
    nohup ${XUI_APP_BIN} run > ${XUI_LOG} 2>&1 &
    
    local timeout=10
    while [ $timeout -gt 0 ]; do
        if pgrep -f "${XUI_APP_BIN}" >/dev/null; then
            echo -e "${green}✓ X-UI successfully started!${plain}"
            check_status
            return 0
        fi
        sleep 1
        ((timeout--))
    done
    
    echo -e "${red}✗ Failed to start X-UI! Check logs: ${XUI_LOG}${plain}"
    return 1
}

stop_panel() {
    echo -e "\n${yellow}⚠ Stopping X-UI...${plain}"
    local xui_pid=$(pgrep -f "${XUI_APP_BIN}")
    
    if [ -n "$xui_pid" ]; then
        kill -TERM $xui_pid 2>/dev/null
        local timeout=10
        
        while [ $timeout -gt 0 ]; do
            if ! ps -p $xui_pid > /dev/null; then
                echo -e "${green}✓ X-UI successfully stopped!${plain}"
                check_status
                return 0
            fi
            sleep 1
            ((timeout--))
        done
        
        kill -9 $xui_pid 2>/dev/null
        echo -e "${red}✗ Forced X-UI stop!${plain}"
    else
        echo -e "${yellow}⚠ X-UI not running!${plain}"
    fi
    
    check_status
}

restart_panel() {
    stop_panel
    start_panel
}

reset_credentials() {
    read -p "Enter new username: " username
    read -p "Enter new password: " password
    ${XUI_APP_BIN} setting -username "${username}" -password "${password}"
    echo -e "\n${green}✓ Credentials updated!${plain}"
    restart_panel
}

reset_webpath() {
    read -p "Enter new web path (e.g. /dashboard): " webpath
    ${XUI_APP_BIN} setting -webBasePath "${webpath}"
    echo -e "\n${green}✓ Web path updated!${plain}"
    restart_panel
}

reset_settings() {
    echo -e "${yellow}⚠ This will reset ALL settings!${plain}"
    read -p "Are you sure? [y/N]: " confirm
    if [[ "${confirm}" =~ ^[Yy]$ ]]; then
        rm -f "${XUI_DB}"
        echo -e "\n${green}✓ All settings reset!${plain}"
        restart_panel
    else
        echo -e "\n${red}✗ Operation canceled${plain}"
    fi
}

change_port() {
    current_port=$(${XUI_APP_BIN} setting -show | grep "port:" | awk '{print $2}')
    read -p "Enter new port [current: ${current_port}]: " port
    ${XUI_APP_BIN} setting -port "${port:-${current_port}}"
    echo -e "\n${green}✓ Port changed!${plain}"
    restart_panel
}

show_settings() {
    echo -e "\n${cyan}🔧 Current Settings:${plain}"
    ${XUI_APP_BIN} setting -show | awk '{print "  " $0}'
    echo -e "${cyan}🔒 SSL Configuration:${plain}"
    ${XUI_APP_BIN} cert -show | awk '{print "  " $0}'
}

enable_bbr() {
    echo -e "\n${cyan}🚀 Enabling BBR Optimization...${plain}"
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    echo -e "${green}✓ BBR enabled!${plain}"
}

update_geo() {
    GEO_PATH="$(dirname ${XUI_APP_BIN})/bin"
    echo -e "\n${cyan}🌍 Updating Geo Databases in ${GEO_PATH}...${plain}"
    wget -qO "${GEO_PATH}/geoip.dat" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
    wget -qO "${GEO_PATH}/geosite.dat" https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
    echo -e "${green}✓ Geo files updated!${plain}"
    restart_panel
}

configure_fail2ban() {
    if [ "${FAIL2BAN_ENABLED}" != "true" ]; then
        echo -e "${red}Fail2Ban is disabled by environment!${plain}"
        return 1
    fi

    echo -e "\n${cyan}🚦 Configuring Fail2Ban...${plain}"
    mkdir -p /etc/fail2ban/jail.d
    
    cat > /etc/fail2ban/jail.d/x-ui.conf << EOF
[x-ui]
enabled = true
port = 2053,5555,5580
filter = x-ui
logpath = ${XUI_LOG}
maxretry = 3
bantime = 86400
findtime = 3600
EOF

    echo -e "${green}✓ Fail2Ban configuration updated!${plain}"
    pkill -9 -f "fail2ban-server" && fail2ban-server -b -x
    sleep 2
    check_status
}

run_speedtest() {
    echo -e "\n${cyan}📶 Running Speedtest...${plain}"
    if ! command -v speedtest >/dev/null; then
        echo -e "${yellow}Installing Speedtest CLI...${plain}"
        apt-get update >/dev/null 2>&1
        apt-get install -y gnupg1 apt-transport-https dirmngr >/dev/null 2>&1
        curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash >/dev/null 2>&1
        apt-get install -y speedtest >/dev/null 2>&1
    fi
    speedtest --accept-license --accept-gdpr
}

# Главный цикл
header
check_status

while true; do
    show_menu
    echo -e "\n${cyan}────────────────────────────────────"
    read -p "  Select option [0-13]: " choice

    case $choice in
        1) reset_credentials ;;
        2) reset_webpath ;;
        3) reset_settings ;;
        4) change_port ;;
        5) show_settings ;;
        6) start_panel ;;
        7) stop_panel ;;
        8) restart_panel ;;
        9) check_status ;;
        10) enable_bbr ;;
        11) update_geo ;;
        12) configure_fail2ban ;;
        13) run_speedtest ;;
        0) 
            echo -e "\n${green}👋 Goodbye!${plain}\n"
            exit 0
            ;;
        *) 
            echo -e "\n${red}✗ Invalid option!${plain}"
            ;;
    esac

    read -p $'\nPress Enter to continue...'
    header
    check_status
done