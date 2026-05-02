#!/bin/bash
# Graylog 前端字串擷取工具
# 從 graylog.jar 的 webpack bundle 中擷取候選 UI 文字
#
# 使用方式：
#   ./extract-strings.sh /usr/share/graylog-server/graylog.jar
#   ./extract-strings.sh /usr/share/graylog-server/graylog.jar output.txt

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "用法: $0 <graylog.jar 路徑> [輸出檔案]"
    echo "範例: $0 /usr/share/graylog-server/graylog.jar"
    exit 1
fi

JAR_PATH="$1"
OUTPUT="${2:-extracted-strings.txt}"

if [ ! -f "$JAR_PATH" ]; then
    echo "錯誤: 找不到檔案 $JAR_PATH"
    exit 1
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "解壓 JS 檔案..."
unzip -q "$JAR_PATH" "web-interface/assets/*.js" -d "$WORK_DIR" 2>/dev/null || {
    echo "錯誤: 無法從 $JAR_PATH 解壓 web-interface/assets/*.js"
    echo "請確認這是 Graylog server 的 jar 檔"
    exit 1
}

JS_COUNT=$(find "$WORK_DIR" -name "*.js" | wc -l | tr -d ' ')
echo "找到 $JS_COUNT 個 JS 檔案"

echo "擷取候選字串..."
grep -ohP '"[A-Z][a-zA-Z ]{2,60}"' "$WORK_DIR"/web-interface/assets/*.js 2>/dev/null \
    | sed 's/"//g' \
    | sort -u \
    | grep -vE '^(https?://|/api/|className|data-|aria-|Content-Type|Accept|Authorization|XMLHttpRequest)' \
    | grep -vE '^(GET|POST|PUT|DELETE|PATCH|OPTIONS|HEAD)$' \
    | grep -vE '^[A-Z_]{2,}$' \
    | grep -vE '\.' \
    > "$OUTPUT"

COUNT=$(wc -l < "$OUTPUT" | tr -d ' ')
echo ""
echo "擷取完成：$COUNT 個候選字串"
echo "輸出檔案：$OUTPUT"
echo ""
echo "注意：擷取結果需要人工篩選，許多字串不是 UI 文字。"
echo "建議與現有字典比對，找出尚未翻譯的項目："
echo "  comm -23 <(sort $OUTPUT) <(jq -r '.translations | keys[]' static/graylog-i18n-dict.json | sort)"
