#!/bin/bash

# Stop any running Next.js servers
pkill -f "next" 2>/dev/null || true

# Add all changes
git add .

# Commit with descriptive message
git commit -m "fix: downgrade to Next.js 14.2.5 and fix build issues

- Downgrade from Next.js 15.5.2 to 14.2.5 (stable version)
- Fix config file: next.config.ts -> next.config.js
- Fix fonts: Geist -> Inter/JetBrains Mono
- Add build ID generation to prevent chunk mismatches
- Eliminate ./586.js module errors"

# Push to GitHub
git push origin main

echo "✅ Changes committed and pushed to GitHub!"
echo "🚀 Now redeploy on Vercel with 'Use existing Build Cache' UNCHECKED" 