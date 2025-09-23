#!/bin/bash
#
# Quick Setup for M0nkeyFl0wer's Linux Smart(er) Phone
# Run this to create and push your entire project to GitHub
#

set -e

echo "🚀 Setting up Linux Smart(er) Phone for M0nkeyFl0wer..."

# 1. Run the export script (assuming it's saved)
if [ -f "export_lsp_project.sh" ]; then
    echo "Running export script..."
    ./export_lsp_project.sh
else
    echo "⚠️  Please save the export_lsp_project.sh script first!"
    exit 1
fi

# 2. Navigate to project
cd ~/linux-smarter-phone

# 3. Get GPLv3 license
echo "Downloading GPLv3 license..."
wget -q https://www.gnu.org/licenses/gpl-3.0.txt -O LICENSE

# 4. Initialize git
echo "Initializing git repository..."
git init

# 5. Add all files
git add .

# 6. Create initial commit
git commit -m "Initial commit: Linux Smart(er) Phone - Personal OnePlus 7 Pro transformation

This project documents my journey of transforming my personal OnePlus 7 Pro
into a smart(er) phone running Linux with ML-powered Android app compatibility.

I'll be sharing detailed updates on my blog as I progress through:
- Installing Ubuntu Touch
- Setting up Waydroid for Android apps  
- Implementing ML-powered compatibility fixes
- Daily driver experiences

This is a real device experiment, not just theory!"

# 7. Add remote (assuming repo is created on GitHub)
echo ""
echo "⚠️  IMPORTANT: Before continuing..."
echo "   1. Go to https://github.com/new"
echo "   2. Create repository named: linux-smarter-phone"
echo "   3. Make it PUBLIC"
echo "   4. DON'T initialize with README"
echo "   5. Click 'Create repository'"
echo ""
read -p "Press Enter when you've created the repository on GitHub..."

# 8. Add remote and push
git remote add origin https://github.com/M0nkeyFl0wer/linux-smarter-phone.git
git branch -M main
git push -u origin main

echo ""
echo "✅ Project pushed to GitHub!"
echo ""
echo "📍 Your repository: https://github.com/M0nkeyFl0wer/linux-smarter-phone"
echo ""
echo "Next steps:"
echo "  1. Add topics on GitHub (click gear icon next to About)"
echo "  2. Update your blog URL in README.md"
echo "  3. Create tracking issues"
echo "  4. Start your OnePlus 7 Pro transformation!"
echo ""
echo "🎉 Good luck with your phone transformation journey!"