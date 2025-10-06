#!/usr/bin/env bash

set -e

echo "=== Fantasy Terminal Unix Setup ==="

if ! command -v love &>/dev/null; then
    echo -e "\nInstalling LÖVE (love2d)..."
    if command -v brew &>/dev/null; then
        brew install love
    elif command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y love
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y love
    else
        echo "Error: No supported package manager found. Please install LÖVE manually."
        exit 1
    fi
else
    echo "LÖVE already installed."
fi

if ! command -v luajit &>/dev/null; then
    echo -e "\nInstalling LuaJIT..."
    if command -v brew &>/dev/null; then
        brew install luajit
    elif command -v apt &>/dev/null; then
        sudo apt install -y luajit
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y luajit
    else
        echo "Error: No supported package manager found. Please install LuaJIT manually."
        exit 1
    fi
else
    echo "LuaJIT already installed."
fi

if ! command -v luarocks &>/dev/null; then
    echo -e "\nInstalling LuaRocks..."
    if command -v brew &>/dev/null; then
        brew install luarocks
    elif command -v apt &>/dev/null; then
        sudo apt install -y luarocks
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y luarocks
    else
        echo "Error: No supported package manager found. Please install LuaRocks manually."
        exit 1
    fi
else
    echo "LuaRocks already installed."
fi

echo -e "\nInitializing local LuaRocks environment..."
luarocks init --local

echo -e "\nInstalling Lua dependencies..."
luarocks --tree=lua_modules install --only-deps fantasy-terminal-scm-1.rockspec

REPO_ROOT="$(pwd)"
export PATH="$PATH:$REPO_ROOT/lua_modules/bin"
expo
