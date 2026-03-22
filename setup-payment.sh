#!/bin/bash
#===============================================================================
# Freedom 项目 - 收款方式自动化设置
# 
# 用途: 检测并配置被动收入收款方式
# 支持: Gumroad / Ko-fi / Buy Me a Coffee / 微信/支付宝
#===============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║   Freedom - 收款方式设置                    ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# 检查现有配置
check_existing() {
    echo -e "\n${YELLOW}[1] 检查现有收款配置...${NC}"
    
    CONFIG_FILE="$HOME/.openclaw/freedom-payment-config.txt"
    
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✓${NC} 发现已有配置:"
        cat "$CONFIG_FILE"
        return 0
    else
        echo -e "${YELLOW}未找到配置文件${NC}"
        return 1
    fi
}

# 选择收款平台
select_platform() {
    echo -e "\n${YELLOW}[2] 选择收款平台${NC}"
    echo ""
    echo "平台对比:"
    echo "┌─────────────────┬──────────┬────────┬──────────┐"
    echo "│ 平台           │ 手续费   │ 到账   │ 难度     │"
    echo "├─────────────────┼──────────┼────────┼──────────┤"
    echo "│ Gumroad        │ 10%      │ 即时   │ 5分钟    │"
    echo "│ Ko-fi          │ 免费*    │ 即时   │ 5分钟    │"
    echo "│ Buy Me Coffee  │ 免费    │ 即时   │ 5分钟    │"
    echo "│ 微信/支付宝    │ 0%      │ 即时   │ 10分钟   │"
    echo "└─────────────────┴──────────┴────────┴──────────┘"
    echo ""
    
    echo "请选择平台:"
    echo "1) Gumroad (国际，推荐)"
    echo "2) Ko-fi (国际，免费)"
    echo "3) Buy Me a Coffee (国际)"
    echo "4) 微信/支付宝 (国内)"
    echo "5) 多个平台都要"
    read -p "选择 (1-5): " choice
    
    case $choice in
        1) PLATFORM="gumroad" ;;
        2) PLATFORM="kofi" ;;
        3) PLATFORM="bmac" ;;
        4) PLATFORM="china" ;;
        5) PLATFORM="all" ;;
        *) PLATFORM="gumroad" ;;
    esac
    
    echo -e "${GREEN}✓${NC} 选择: $PLATFORM"
}

# Gumroad 设置
setup_gumroad() {
    echo -e "\n${YELLOW}配置 Gumroad...${NC}"
    echo ""
    echo "步骤:"
    echo "1. 打开 https://gumroad.com 注册账号 (免费)"
    echo "2. 创建产品页面"
    echo "3. 获取你的产品链接或嵌入代码"
    echo ""
    echo "你的产品链接将是:"
    echo "https://[你的用户名].gumroad.com/l/[产品名]"
    echo ""
    read -p "粘贴你的 Gumroad 产品链接: " link
    
    if [ -n "$link" ]; then
        echo "GUMROAD_LINK=$link" >> "$HOME/.openclaw/freedom-payment-config.txt"
        echo -e "${GREEN}✓${NC} Gumroad 链接已保存"
        echo ""
        echo "下一步: 将这个链接分享出去，有人购买钱就到账！"
    fi
}

# Ko-fi 设置
setup_kofi() {
    echo -e "\n${YELLOW}配置 Ko-fi...${NC}"
    echo ""
    echo "步骤:"
    echo "1. 打开 https://ko-fi.com 注册账号"
    echo "2. 创建 'Shop' 页面添加产品"
    echo "3. 获取你的 Ko-fi 链接"
    echo ""
    read -p "粘贴你的 Ko-fi 链接: " link
    
    if [ -n "$link" ]; then
        echo "KOFI_LINK=$link" >> "$HOME/.openclaw/freedom-payment-config.txt"
        echo -e "${GREEN}✓${NC} Ko-fi 链接已保存"
    fi
}

# Buy Me a Coffee 设置
setup_bmac() {
    echo -e "\n${YELLOW}配置 Buy Me a Coffee...${NC}"
    echo ""
    echo "步骤:"
    echo "1. 打开 https://buymeacoffee.com 注册"
    echo "2. 创建你的主页"
    echo "3. 获取你的链接"
    echo ""
    read -p "粘贴你的链接: " link
    
    if [ -n "$link" ]; then
        echo "BMAC_LINK=$link" >> "$HOME/.openclaw/freedom-payment-config.txt"
        echo -e "${GREEN}✓${NC} Buy Me a Coffee 链接已保存"
    fi
}

# 中国支付设置
setup_china() {
    echo -e "\n${YELLOW}配置微信/支付宝...${NC}"
    
    # 创建收款码目录
    QR_DIR="$HOME/.openclaw/payment-qr"
    mkdir -p "$QR_DIR"
    
    echo ""
    echo "请准备你的收款二维码:"
    echo "1. 微信收款码"
    echo "2. 支付宝收款码"
    echo ""
    echo "将二维码图片保存到: $QR_DIR"
    echo ""
    echo "微信: $QR_DIR/wechat-qr.png"
    echo "支付宝: $QR_DIR/alipay-qr.png"
    echo ""
    
    echo "或者，你可以通过以下方式分享你的收款链接:"
    echo "- 微信: 我-支付-收付款-二维码收款-保存图片"
    echo "- 支付宝: 首页-收钱-保存图片"
    echo ""
    
    read -p "是否有收款二维码? (y/n): " has_qr
    
    if [[ $has_qr =~ ^[Yy]$ ]]; then
        echo "请将二维码图片放入上述目录"
        echo "WEIXIN_QR=$QR_DIR/wechat-qr.png" >> "$HOME/.openclaw/freedom-payment-config.txt"
        echo "ALIPAY_QR=$QR_DIR/alipay-qr.png" >> "$HOME/.openclaw/freedom-payment-config.txt"
        echo -e "${GREEN}✓${NC} 收款码路径已保存"
    fi
}

# 生成销售页面
generate_sales_page() {
    echo -e "\n${YELLOW}[3] 更新销售页面...${NC}"
    
    CONFIG="$HOME/.openclaw/freedom-payment-config.txt"
    SALES_PAGE="$HOME/.openclaw/workspace-main/projects/freedom/digital-product/sales-page.html"
    
    if [ -f "$CONFIG" ]; then
        source "$CONFIG"
        
        # 更新销售页面的购买链接
        if [ -n "$GUMROAD_LINK" ]; then
            sed -i.bak "s|href=\"#\"|href=\"$GUMROAD_LINK\"|g" "$SALES_PAGE"
            echo -e "${GREEN}✓${NC} 销售页面已更新 Gumroad 链接"
        fi
    fi
    
    echo -e "${GREEN}✓${NC} 销售页面: $SALES_PAGE"
}

# 生成推广链接
generate_share_links() {
    echo -e "\n${YELLOW}[4] 推广链接${NC}"
    
    CONFIG="$HOME/.openclaw/freedom-payment-config.txt"
    
    if [ -f "$CONFIG" ]; then
        source "$CONFIG"
        
        echo ""
        echo "分享这些链接，有人购买你就有收入:"
        echo ""
        
        [ -n "$GUMROAD_LINK" ] && echo "📦 Gumroad: $GUMROAD_LINK"
        [ -n "$KOFI_LINK" ] && echo "☕ Ko-fi: $KOFI_LINK"
        [ -n "$BMAC_LINK" ] && echo "☕ Buy Me a Coffee: $BMAC_LINK"
        
        echo ""
        echo "推广方法:"
        echo "1. 分享到社交媒体 (即刻/小红书/微博)"
        echo "2. 在 GitHub 项目中添加购买链接"
        echo "3. 发给需要的朋友"
        echo ""
    fi
}

# 主程序
main() {
    check_existing || select_platform
    
    case $PLATFORM in
        gumroad) setup_gumroad ;;
        kofi) setup_kofi ;;
        bmac) setup_bmac ;;
        china) setup_china ;;
        all)
            setup_gumroad
            setup_kofi
            setup_bmac
            setup_china
            ;;
    esac
    
    generate_sales_page
    generate_share_links
    
    echo -e "\n${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║   设置完成！现在可以开始收款了！            ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

main "$@"
